// Tests firestore.rules against the local emulator. Run from this folder:
//   npm install
//   npm test        (needs Java 11+ and the Firebase CLI)
import { after, before, beforeEach, describe, test } from 'node:test';
import { readFileSync } from 'node:fs';
import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} from '@firebase/rules-unit-testing';
import {
  doc,
  getDoc,
  getDocs,
  collection,
  serverTimestamp,
  setDoc,
  updateDoc,
  deleteDoc,
  writeBatch,
  Timestamp,
} from 'firebase/firestore';

const DAY = 24 * 60 * 60 * 1000;
const future = () => Timestamp.fromMillis(Date.now() + 30 * DAY);
const past = () => Timestamp.fromMillis(Date.now() - DAY);

let env;

before(async () => {
  env = await initializeTestEnvironment({
    projectId: 'demo-kura',
    firestore: { rules: readFileSync('../firestore.rules', 'utf8') },
  });
});

after(() => env.cleanup());

beforeEach(() => env.clearFirestore());

const as = (uid) =>
  env.authenticatedContext(uid, { email: `${uid}@test.com` }).firestore();

/** Sets up data with rules switched off. */
const seed = (fn) =>
  env.withSecurityRulesDisabled((ctx) => fn(ctx.firestore()));

const shopDoc = (expires) => ({
  name: 'Shop',
  phone: '',
  owner_email: 'x@test.com',
  expires_at: expires,
  created_at: Timestamp.now(),
});

const itemFields = (extra = {}) => ({
  name: 'Figure',
  code: '',
  unit: 'pcs',
  price: 25000,
  cost: 18000,
  quantity: 0,
  low_stock_at: 2,
  is_active: true,
  last_move_id: '',
  created_at: serverTimestamp(),
  updated_at: serverTimestamp(),
  ...extra,
});

const moveFields = (extra = {}) => ({
  type: 'in',
  item_id: 'item1',
  item_name: 'Figure',
  quantity: 5,
  quantity_before: 0,
  quantity_after: 5,
  unit_price: 18000,
  customer_id: '',
  customer_name: '',
  note: '',
  created_by: 'alice',
  created_at: serverTimestamp(),
  ...extra,
});

/** An existing item with [quantity] in alice's shop, written directly. */
const seedItem = (quantity, expires = future()) =>
  seed(async (db) => {
    await setDoc(doc(db, 'shops/alice'), shopDoc(expires));
    await setDoc(doc(db, 'shops/alice/items/item1'), {
      ...itemFields({ quantity }),
      created_at: Timestamp.now(),
      updated_at: Timestamp.now(),
    });
  });

/** The app's recordMove: a movement plus the item update, together. */
const recordMove = (db, moveId, move, newQuantity) => {
  const batch = writeBatch(db);
  batch.set(doc(db, `shops/alice/moves/${moveId}`), moveFields(move));
  batch.update(doc(db, 'shops/alice/items/item1'), {
    quantity: newQuantity,
    last_move_id: moveId,
    updated_at: serverTimestamp(),
  });
  return batch.commit();
};

describe('shops', () => {
  test('an owner creates their own shop, pending', async () => {
    await assertSucceeds(
      setDoc(doc(as('alice'), 'shops/alice'), {
        name: 'Alice Toys',
        phone: '',
        owner_email: 'alice@test.com',
        expires_at: null,
        created_at: serverTimestamp(),
      }),
    );
  });

  test('cannot give yourself an expiry date when creating', async () => {
    await assertFails(
      setDoc(doc(as('alice'), 'shops/alice'), {
        name: 'Alice Toys',
        phone: '',
        owner_email: 'alice@test.com',
        expires_at: future(),
        created_at: serverTimestamp(),
      }),
    );
  });

  test("cannot create someone else's shop", async () => {
    await assertFails(
      setDoc(doc(as('alice'), 'shops/bob'), {
        name: 'Fake',
        phone: '',
        owner_email: 'alice@test.com',
        expires_at: null,
        created_at: serverTimestamp(),
      }),
    );
  });

  test('owner can rename but not extend', async () => {
    await seed((db) => setDoc(doc(db, 'shops/alice'), shopDoc(past())));
    const db = as('alice');
    await assertSucceeds(updateDoc(doc(db, 'shops/alice'), { name: 'New' }));
    await assertFails(
      updateDoc(doc(db, 'shops/alice'), { expires_at: future() }),
    );
  });

  test("cannot read another shop", async () => {
    await seed((db) => setDoc(doc(db, 'shops/bob'), shopDoc(future())));
    await assertFails(getDoc(doc(as('alice'), 'shops/bob')));
    await assertFails(getDocs(collection(as('alice'), 'shops')));
  });

  test('super admin lists shops and sets expiry, nothing else', async () => {
    await seed(async (db) => {
      await setDoc(doc(db, 'super_admins/boss'), {});
      await setDoc(doc(db, 'shops/bob'), shopDoc(null));
    });
    const db = as('boss');
    await assertSucceeds(getDocs(collection(db, 'shops')));
    await assertSucceeds(
      updateDoc(doc(db, 'shops/bob'), { expires_at: future() }),
    );
    await assertFails(updateDoc(doc(db, 'shops/bob'), { name: 'Mine now' }));
  });

  test('nobody can make themselves super admin', async () => {
    await assertFails(setDoc(doc(as('alice'), 'super_admins/alice'), {}));
  });
});

describe('items and stock', () => {
  test('active shop adds an item with opening stock', async () => {
    await seed((db) => setDoc(doc(db, 'shops/alice'), shopDoc(future())));
    const db = as('alice');
    const batch = writeBatch(db);
    batch.set(
      doc(db, 'shops/alice/items/item1'),
      itemFields({ quantity: 5, last_move_id: 'm1' }),
    );
    batch.set(doc(db, 'shops/alice/moves/m1'), moveFields());
    await assertSucceeds(batch.commit());
  });

  test('cannot create an item with stock but no movement', async () => {
    await seed((db) => setDoc(doc(db, 'shops/alice'), shopDoc(future())));
    await assertFails(
      setDoc(
        doc(as('alice'), 'shops/alice/items/item1'),
        itemFields({ quantity: 5, last_move_id: 'm1' }),
      ),
    );
  });

  test('stock in and out with matching history', async () => {
    await seedItem(5);
    const db = as('alice');
    await assertSucceeds(
      recordMove(db, 'm2', { quantity: 3, quantity_before: 5, quantity_after: 8 }, 8),
    );
    await assertSucceeds(
      recordMove(
        db,
        'm3',
        { type: 'out', quantity: 2, quantity_before: 8, quantity_after: 6 },
        6,
      ),
    );
    await assertSucceeds(
      recordMove(
        db,
        'm4',
        { type: 'adjust', quantity: 4, quantity_before: 6, quantity_after: 4 },
        4,
      ),
    );
  });

  test('cannot sell more than in stock', async () => {
    await seedItem(1);
    await assertFails(
      recordMove(
        as('alice'),
        'm2',
        { type: 'out', quantity: 2, quantity_before: 1, quantity_after: -1 },
        -1,
      ),
    );
  });

  test('history must add up', async () => {
    await seedItem(5);
    // Says +1 but sets the item to 50.
    await assertFails(
      recordMove(
        as('alice'),
        'm2',
        { quantity: 1, quantity_before: 5, quantity_after: 6 },
        50,
      ),
    );
    // Lies about the starting quantity.
    await assertFails(
      recordMove(
        as('alice'),
        'm3',
        { quantity: 1, quantity_before: 0, quantity_after: 1 },
        1,
      ),
    );
  });

  test('cannot change quantity without a movement', async () => {
    await seedItem(5);
    await assertFails(
      updateDoc(doc(as('alice'), 'shops/alice/items/item1'), {
        quantity: 99,
        updated_at: serverTimestamp(),
      }),
    );
  });

  test('can edit item details without touching quantity', async () => {
    await seedItem(5);
    await assertSucceeds(
      updateDoc(doc(as('alice'), 'shops/alice/items/item1'), {
        price: 30000,
        updated_at: serverTimestamp(),
      }),
    );
  });

  test('history cannot be edited or deleted', async () => {
    await seedItem(5);
    await recordMove(
      as('alice'),
      'm2',
      { quantity: 1, quantity_before: 5, quantity_after: 6 },
      6,
    );
    const db = as('alice');
    await assertFails(
      updateDoc(doc(db, 'shops/alice/moves/m2'), { quantity: 100 }),
    );
    await assertFails(deleteDoc(doc(db, 'shops/alice/moves/m2')));
  });

  test('expired shop can read but not write', async () => {
    await seedItem(5, past());
    const db = as('alice');
    await assertSucceeds(getDocs(collection(db, 'shops/alice/items')));
    await assertFails(
      recordMove(db, 'm2', { quantity: 1, quantity_before: 5, quantity_after: 6 }, 6),
    );
    await assertFails(
      updateDoc(doc(db, 'shops/alice/items/item1'), {
        price: 1,
        updated_at: serverTimestamp(),
      }),
    );
  });

  test('pending shop cannot write', async () => {
    await seed((db) => setDoc(doc(db, 'shops/alice'), shopDoc(null)));
    await assertFails(
      setDoc(doc(as('alice'), 'shops/alice/items/item1'), itemFields()),
    );
  });

  test("cannot touch another shop's items", async () => {
    await seedItem(5);
    const bob = as('bob');
    await assertFails(getDoc(doc(bob, 'shops/alice/items/item1')));
    await assertFails(
      setDoc(doc(bob, 'shops/alice/items/item2'), itemFields()),
    );
  });
});

describe('customers', () => {
  const customer = () => ({
    name: 'Ko Aung',
    phone: '09123456789',
    address: '',
    note: '',
    created_at: serverTimestamp(),
    updated_at: serverTimestamp(),
  });

  test('active shop adds and deletes customers', async () => {
    await seed((db) => setDoc(doc(db, 'shops/alice'), shopDoc(future())));
    const db = as('alice');
    await assertSucceeds(setDoc(doc(db, 'shops/alice/customers/c1'), customer()));
    await assertSucceeds(deleteDoc(doc(db, 'shops/alice/customers/c1')));
  });

  test("other shops can't see them", async () => {
    await seed((db) => setDoc(doc(db, 'shops/alice'), shopDoc(future())));
    await setDoc(doc(as('alice'), 'shops/alice/customers/c1'), customer());
    await assertFails(getDoc(doc(as('bob'), 'shops/alice/customers/c1')));
  });
});

// The figure shop's own rules, living in the same file.
describe('figure shop', () => {
  test('anyone can browse products, nobody can write them', async () => {
    await seed((db) => setDoc(doc(db, 'products/p1'), { name: 'Miku' }));
    await assertSucceeds(
      getDoc(doc(env.unauthenticatedContext().firestore(), 'products/p1')),
    );
    await assertFails(setDoc(doc(as('alice'), 'products/p2'), { name: 'x' }));
  });

  test("customers can't read other people's orders", async () => {
    await seed((db) => setDoc(doc(db, 'orders/o1'), { user_id: 'bob' }));
    await assertSucceeds(getDoc(doc(as('bob'), 'orders/o1')));
    await assertFails(getDoc(doc(as('alice'), 'orders/o1')));
  });
});
