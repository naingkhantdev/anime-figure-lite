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
  Bytes,
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
  phone: '09123456789',
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
        phone: '09123456789',
        owner_email: 'alice@test.com',
        expires_at: null,
        created_at: serverTimestamp(),
      }),
    );
  });

  test('a shop needs a phone customers can call', async () => {
    await assertFails(
      setDoc(doc(as('alice'), 'shops/alice'), {
        name: 'Alice Toys',
        phone: '',
        owner_email: 'alice@test.com',
        expires_at: null,
        created_at: serverTimestamp(),
      }),
    );
    await seed((db) =>
      setDoc(doc(db, 'shops/bob'), { ...shopDoc(future()), phone: '' }));
    await assertFails(
      updateDoc(doc(as('bob'), 'shops/bob'), { name: 'Renamed' }),
      'an older shop adds its phone the next time it saves',
    );
    await assertSucceeds(
      updateDoc(doc(as('bob'), 'shops/bob'),
        { name: 'Renamed', phone: '09987654321' }),
    );
  });

  test('cannot give yourself an expiry date when creating', async () => {
    await assertFails(
      setDoc(doc(as('alice'), 'shops/alice'), {
        name: 'Alice Toys',
        phone: '09123456789',
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
        phone: '09123456789',
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

describe('blacklist', () => {
  const seedBoss = () =>
    seed((db) => setDoc(doc(db, 'super_admins/boss'), {}));

  /** The app's block(): the remark and its empty twin, together. */
  const block = (db, email, remark = 'Never paid') => {
    const batch = writeBatch(db);
    batch.set(doc(db, `blacklist/${email}`), {
      email,
      remark,
      created_at: serverTimestamp(),
    });
    batch.set(doc(db, `blocked/${email}`), { created_at: serverTimestamp() });
    return batch.commit();
  };

  const unblock = (db, email) => {
    const batch = writeBatch(db);
    batch.delete(doc(db, `blacklist/${email}`));
    batch.delete(doc(db, `blocked/${email}`));
    return batch.commit();
  };

  test('super admin blocks with a remark, edits it, and unblocks', async () => {
    await seedBoss();
    const db = as('boss');
    await assertSucceeds(block(db, 'bob@test.com'));
    await assertSucceeds(getDocs(collection(db, 'blacklist')));
    await assertSucceeds(
      updateDoc(doc(db, 'blacklist/bob@test.com'), { remark: 'Rude' }));
    await assertSucceeds(unblock(db, 'bob@test.com'));
  });

  test('both documents, or neither', async () => {
    await seedBoss();
    const db = as('boss');
    await assertFails(setDoc(doc(db, 'blocked/bob@test.com'),
      { created_at: serverTimestamp() }));
    await assertFails(setDoc(doc(db, 'blacklist/bob@test.com'),
      { email: 'bob@test.com', remark: 'x', created_at: serverTimestamp() }));
    await assertSucceeds(block(db, 'bob@test.com'));
    await assertFails(deleteDoc(doc(db, 'blocked/bob@test.com')));
  });

  test('a remark is required; the email is lowercase; not yourself',
    async () => {
      await seedBoss();
      const db = as('boss');
      await assertFails(block(db, 'bob@test.com', ''));
      await assertFails(block(db, 'Bob@test.com'));
      await assertFails(block(db, 'not-an-email'));
      await assertFails(block(db, 'boss@test.com'));
    });

  test('only the super admin; the blocked person sees no remark',
    async () => {
      await seedBoss();
      await block(as('boss'), 'bob@test.com');
      await assertFails(block(as('alice'), 'carol@test.com'));
      await assertFails(unblock(as('bob'), 'bob@test.com'));
      await assertFails(getDoc(doc(as('bob'), 'blacklist/bob@test.com')));
      await assertSucceeds(getDoc(doc(as('bob'), 'blocked/bob@test.com')));
      await assertFails(getDoc(doc(as('alice'), 'blocked/bob@test.com')));
    });

  test('a blocked account cannot order or open a shop', async () => {
    await seed(async (db) => {
      await setDoc(doc(db, 'blocked/bob@test.com'), {});
      await setDoc(doc(db, 'blocked/alice@test.com'), {});
    });
    await assertFails(setDoc(doc(as('bob'), 'orders/o1'), {
      user_id: 'bob',
      shop_id: '',
      status: 'pending',
      items: [{ product_id: 'p1', name: 'Figure', price: 1, quantity: 1 }],
      total: 1,
      phone: '09123456789',
      delivery_method: 'pickup',
      address: '',
      note: '',
      delivery_fee: 0,
      created_at: serverTimestamp(),
    }));
    await assertFails(setDoc(doc(as('bob'), 'shops/bob'), {
      ...shopDoc(null),
      owner_email: 'bob@test.com',
      created_at: serverTimestamp(),
    }));
  });

  test("a blocked owner's open shop changes nothing, and comes back",
    async () => {
      await seedBoss();
      await seedItem(5);
      await block(as('boss'), 'alice@test.com');
      const item = doc(as('alice'), 'shops/alice/items/item1');
      await assertSucceeds(getDoc(item));
      await assertFails(updateDoc(item,
        { name: 'New name', updated_at: serverTimestamp() }));
      await unblock(as('boss'), 'alice@test.com');
      await assertSucceeds(updateDoc(item,
        { name: 'New name', updated_at: serverTimestamp() }));
    });
});

describe('shop_public', () => {
  const info = (extra = {}) => ({
    phone: '09123456789',
    delivery_fee: 3000,
    payment_methods: [
      { type: 'kbzpay', name: 'Alice', number: '09123456789' },
    ],
    updated_at: serverTimestamp(),
    ...extra,
  });

  test('an open shop saves its settings; anyone can read them', async () => {
    await seed((db) => setDoc(doc(db, 'shops/alice'), shopDoc(future())));
    await assertSucceeds(setDoc(doc(as('alice'), 'shop_public/alice'), info()));
    await assertSucceeds(
      getDoc(doc(env.unauthenticatedContext().firestore(), 'shop_public/alice')),
    );
  });

  test('settings change with the shop phone, in one write', async () => {
    await seed((db) => setDoc(doc(db, 'shops/alice'), shopDoc(future())));
    const db = as('alice');
    await assertFails(
      setDoc(doc(db, 'shop_public/alice'), info({ phone: '09111111111' })),
      'phone differs from the shop',
    );
    const batch = writeBatch(db);
    batch.update(doc(db, 'shops/alice'), { phone: '09111111111' });
    batch.set(doc(db, 'shop_public/alice'), info({ phone: '09111111111' }));
    await assertSucceeds(batch.commit());
  });

  test('no settings for other, closed or waiting shops, or bad values',
    async () => {
      await seed(async (db) => {
        await setDoc(doc(db, 'shops/alice'), shopDoc(future()));
        await setDoc(doc(db, 'shops/bob'), shopDoc(past()));
        await setDoc(doc(db, 'shops/carol'), shopDoc(null));
      });
      await assertFails(setDoc(doc(as('bob'), 'shop_public/alice'), info()));
      await assertFails(setDoc(doc(as('bob'), 'shop_public/bob'), info()));
      await assertFails(setDoc(doc(as('carol'), 'shop_public/carol'), info()));
      const db = as('alice');
      for (const bad of [
        { delivery_fee: -1 },
        { delivery_fee: 1.5 },
        { payment_methods: 'KBZPay 0912' },
        { payment_methods: Array(7).fill({ type: 'bank' }) },
        { owner_email: 'x@test.com' },
      ]) {
        await assertFails(
          setDoc(doc(db, 'shop_public/alice'), info(bad)),
          JSON.stringify(bad),
        );
      }
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

  const seedOrder = () =>
    seed((db) =>
      setDoc(doc(db, 'orders/o1'), {
        user_id: 'bob',
        status: 'confirmed',
        total: 45000,
        phone: '09123456789',
        address: 'Yangon',
        note: 'ring twice',
      }),
    );
  const blank = { phone: '', address: '', note: '' };

  test('before deleting their account, a customer blanks their details',
    async () => {
      await seedOrder();
      await assertFails(updateDoc(doc(as('alice'), 'orders/o1'), blank));
      await assertSucceeds(updateDoc(doc(as('bob'), 'orders/o1'), blank));
    });

  test('blanking details cannot change anything else', async () => {
    await seedOrder();
    await assertFails(
      updateDoc(doc(as('bob'), 'orders/o1'), { ...blank, total: 0 }),
    );
    await assertFails(
      updateDoc(doc(as('bob'), 'orders/o1'), { ...blank, phone: '0999' }),
    );
    await assertFails(
      updateDoc(doc(as('bob'), 'orders/o1'), { status: 'cancelled' }),
      'only pending orders can be cancelled',
    );
  });
});

// A shop's items in the customer catalog, and its orders.
describe('selling in the app', () => {
  const listing = (extra = {}) => ({
    name: 'Figure',
    description: 'From One Piece.',
    price: 25000,
    stock_quantity: 5,
    image_url: '',
    category: 'Scale figure',
    anime: 'One Piece',
    is_active: true,
    shop_id: 'alice',
    shop_name: 'Shop',
    shop_open_until: null,
    item_id: 'item1',
    updated_at: serverTimestamp(),
    ...extra,
  });

  /** alice's shop, open until [expires], with a listed item1 of 5. */
  const seedListed = async (expires = future()) => {
    await seed(async (db) => {
      await setDoc(doc(db, 'shops/alice'), shopDoc(expires));
      await setDoc(doc(db, 'shops/alice/items/item1'), {
        ...itemFields({
          quantity: 5,
          listed: true,
          category: 'Scale figure',
          anime: 'One Piece',
          description: 'From One Piece.',
          image_url: '',
        }),
        created_at: Timestamp.now(),
        updated_at: Timestamp.now(),
      });
    });
    return expires;
  };

  test('an open shop lists an item that matches it', async () => {
    const expires = await seedListed();
    await assertSucceeds(
      setDoc(
        doc(as('alice'), 'products/alice_item1'),
        listing({ shop_open_until: expires }),
      ),
    );
  });

  test('the catalog copy cannot differ from the item', async () => {
    const expires = await seedListed();
    const db = as('alice');
    for (const lie of [
      { price: 1000 },
      { stock_quantity: 99 },
      { shop_name: 'Famous Shop' },
      { shop_open_until: Timestamp.fromMillis(Date.now() + 999 * DAY) },
    ]) {
      await assertFails(
        setDoc(
          doc(db, 'products/alice_item1'),
          listing({ shop_open_until: expires, ...lie }),
        ),
        JSON.stringify(lie),
      );
    }
  });

  test("cannot list for another shop or overwrite the house's figures",
    async () => {
      const expires = await seedListed();
      await seed((db) => setDoc(doc(db, 'products/fig-1'), { name: 'Miku' }));
      const db = as('alice');
      await assertFails(
        setDoc(
          doc(db, 'products/fig-1'),
          listing({ shop_open_until: expires }),
        ),
      );
      await assertFails(
        setDoc(
          doc(as('bob'), 'products/alice_item1'),
          listing({ shop_open_until: expires }),
        ),
      );
    });

  test('an expired shop cannot list', async () => {
    const expires = await seedListed(past());
    await assertFails(
      setDoc(
        doc(as('alice'), 'products/alice_item1'),
        listing({ shop_open_until: expires }),
      ),
    );
  });

  test('a sale updates the item, its history and its listing together',
    async () => {
      const expires = await seedListed();
      const db = as('alice');
      const batch = writeBatch(db);
      batch.set(
        doc(db, 'shops/alice/moves/m2'),
        moveFields({ type: 'out', quantity: 2, quantity_before: 5,
          quantity_after: 3 }),
      );
      batch.update(doc(db, 'shops/alice/items/item1'), {
        quantity: 3,
        last_move_id: 'm2',
        updated_at: serverTimestamp(),
      });
      batch.set(
        doc(db, 'products/alice_item1'),
        listing({ shop_open_until: expires, stock_quantity: 3 }),
      );
      await assertSucceeds(batch.commit());
    });

  test('super admin moves the end date with the shop, nothing else',
    async () => {
      const expires = await seedListed();
      await seed(async (db) => {
        await setDoc(doc(db, 'super_admins/boss'), {});
        await setDoc(doc(db, 'products/alice_item1'), {
          ...listing({ shop_open_until: expires }),
          updated_at: Timestamp.now(),
        });
      });
      const db = as('boss');
      const later = Timestamp.fromMillis(Date.now() + 90 * DAY);
      const batch = writeBatch(db);
      batch.update(doc(db, 'shops/alice'), { expires_at: later });
      batch.update(doc(db, 'products/alice_item1'), { shop_open_until: later });
      await assertSucceeds(batch.commit());
      await assertFails(
        updateDoc(doc(db, 'products/alice_item1'), { price: 1 }),
      );
    });

  const order = (extra = {}) => ({
    user_id: 'bob',
    shop_id: 'alice',
    status: 'pending',
    items: [{ product_id: 'alice_item1', name: 'Figure', price: 25000,
      quantity: 1 }],
    total: 25000,
    phone: '09123456789',
    delivery_method: 'pickup',
    address: '',
    note: '',
    delivery_fee: 0,
    created_at: serverTimestamp(),
    ...extra,
  });

  test("a delivery order carries the shop's own delivery fee", async () => {
    await seed(async (db) => {
      await setDoc(doc(db, 'shops/alice'), shopDoc(future()));
      await setDoc(doc(db, 'shop_public/alice'), {
        phone: '09123456789',
        delivery_fee: 3000,
        payment_methods: [],
        updated_at: Timestamp.now(),
      });
    });
    const db = as('bob');
    const delivery = { delivery_method: 'delivery', address: 'Yangon' };
    await assertSucceeds(setDoc(doc(db, 'orders/o1'),
      order({ ...delivery, delivery_fee: 3000, total: 28000 })));
    for (const bad of [
      { ...delivery, delivery_fee: 0, total: 25000 },
      { ...delivery, delivery_fee: 1000, total: 26000 },
      { ...delivery, delivery_fee: 3000, total: 2000 },
      { delivery_fee: 3000, total: 28000 },
    ]) {
      await assertFails(setDoc(doc(db, 'orders/o2'), order(bad)),
        JSON.stringify(bad));
    }
    const { delivery_fee, ...noFee } = order();
    await assertFails(setDoc(doc(db, 'orders/o3'), noFee), 'fee is required');
  });

  test('delivery is free from a shop without settings, and for the house',
    async () => {
      await seed((db) => setDoc(doc(db, 'shops/alice'), shopDoc(future())));
      const db = as('bob');
      const delivery = { delivery_method: 'delivery', address: 'Yangon' };
      await assertSucceeds(setDoc(doc(db, 'orders/o1'), order(delivery)));
      await assertSucceeds(
        setDoc(doc(db, 'orders/o2'), order({ ...delivery, shop_id: '' })));
      await assertFails(setDoc(doc(db, 'orders/o3'),
        order({ ...delivery, delivery_fee: 500, total: 25500 })));
    });

  test('a customer orders from a shop; the shop sees it, others do not',
    async () => {
      await seed((db) => setDoc(doc(db, 'shops/alice'), shopDoc(future())));
      await assertSucceeds(setDoc(doc(as('bob'), 'orders/o1'), order()));
      await assertSucceeds(getDoc(doc(as('alice'), 'orders/o1')));
      await assertFails(getDoc(doc(as('carol'), 'orders/o1')));
    });

  test('the shop moves its order on step by step, and only the status',
    async () => {
      await seed(async (db) => {
        await setDoc(doc(db, 'shops/alice'), shopDoc(future()));
        await setDoc(doc(db, 'orders/o1'), {
          ...order(),
          created_at: Timestamp.now(),
        });
      });
      const db = as('alice');
      const o = doc(db, 'orders/o1');
      await assertFails(updateDoc(o, { status: 'shipped' }), 'skips confirm');
      await assertFails(updateDoc(o, { status: 'confirmed', total: 1 }));
      await assertSucceeds(updateDoc(o, { status: 'confirmed' }));
      await assertSucceeds(updateDoc(o, { status: 'shipped' }));
      await assertFails(updateDoc(o, { status: 'pending' }));
      await assertFails(
        updateDoc(doc(as('carol'), 'orders/o1'), { status: 'cancelled' }),
      );
    });
});

describe('payment screenshots', () => {
  const proof = (extra = {}) => ({
    order_id: 'o1',
    user_id: 'bob',
    shop_id: 'alice',
    data: Bytes.fromUint8Array(new Uint8Array(1000)),
    created_at: serverTimestamp(),
    ...extra,
  });

  /** bob's order o1 with alice's shop, in [status]. */
  const seedOrder = (status = 'pending') =>
    seed((db) =>
      setDoc(doc(db, 'orders/o1'), {
        user_id: 'bob',
        shop_id: 'alice',
        status,
        total: 25000,
        delivery_fee: 0,
        phone: '09123456789',
        delivery_method: 'pickup',
        address: '',
        note: '',
        created_at: Timestamp.now(),
      }),
    );

  /** The app's sendPaymentProof: the proof and the order's pointer. */
  const send = (db, proofId, extra = {}) => {
    const batch = writeBatch(db);
    batch.set(doc(db, `payment_proofs/${proofId}`), proof(extra));
    batch.update(doc(db, 'orders/o1'), {
      payment_proof_id: proofId,
      payment_sent_at: serverTimestamp(),
    });
    return batch.commit();
  };

  test('a customer sends a screenshot; only they and the shop see it',
    async () => {
      await seedOrder();
      await seed((db) => setDoc(doc(db, 'super_admins/boss'), {}));
      await assertSucceeds(send(as('bob'), 'pr1'));
      await assertSucceeds(getDoc(doc(as('bob'), 'payment_proofs/pr1')));
      await assertSucceeds(getDoc(doc(as('alice'), 'payment_proofs/pr1')));
      await assertSucceeds(getDoc(doc(as('boss'), 'payment_proofs/pr1')));
      await assertFails(getDoc(doc(as('carol'), 'payment_proofs/pr1')));
      await assertFails(getDoc(doc(env.unauthenticatedContext().firestore(),
        'payment_proofs/pr1')));
    });

  test('and replaces it while the order waits', async () => {
    await seedOrder();
    const db = as('bob');
    await assertSucceeds(send(db, 'pr1'));
    await assertSucceeds(send(db, 'pr2'));
    await assertSucceeds(deleteDoc(doc(db, 'payment_proofs/pr1')));
    await assertFails(
      updateDoc(doc(db, 'payment_proofs/pr2'), { order_id: 'o9' }),
      'write-once',
    );
  });

  test('no screenshots on others\' orders, closed orders, or too big',
    async () => {
      await seedOrder();
      await assertFails(send(as('carol'), 'pr1', { user_id: 'carol' }));
      await assertFails(send(as('bob'), 'pr2', { shop_id: 'carol' }));
      await assertFails(send(as('bob'), 'pr3',
        { data: Bytes.fromUint8Array(new Uint8Array(500 * 1024)) }));
      await assertFails(
        updateDoc(doc(as('bob'), 'orders/o1'), {
          payment_proof_id: 'nothing',
          payment_sent_at: serverTimestamp(),
        }),
        'the proof must exist',
      );
      await seedOrder('confirmed');
      await assertFails(send(as('bob'), 'pr4'), 'not pending');
    });
});

describe('photos', () => {
  const photo = (extra = {}) => ({
    shop_id: 'alice',
    data: Bytes.fromUint8Array(new Uint8Array(1000)),
    created_at: serverTimestamp(),
    ...extra,
  });

  test('an open shop saves a photo; anyone can see it', async () => {
    await seed((db) => setDoc(doc(db, 'shops/alice'), shopDoc(future())));
    await assertSucceeds(setDoc(doc(as('alice'), 'photos/p1'), photo()));
    await assertSucceeds(
      getDoc(doc(env.unauthenticatedContext().firestore(), 'photos/p1')),
    );
  });

  test('no photos for other shops, closed shops, or too big', async () => {
    await seed(async (db) => {
      await setDoc(doc(db, 'shops/alice'), shopDoc(future()));
      await setDoc(doc(db, 'shops/bob'), shopDoc(past()));
    });
    await assertFails(
      setDoc(doc(as('carol'), 'photos/p1'), photo()),
      'not her shop',
    );
    await assertFails(
      setDoc(doc(as('bob'), 'photos/p2'), photo({ shop_id: 'bob' })),
      'expired',
    );
    await assertFails(
      setDoc(
        doc(as('alice'), 'photos/p3'),
        photo({ data: Bytes.fromUint8Array(new Uint8Array(500 * 1024)) }),
      ),
      'too big',
    );
  });
});
