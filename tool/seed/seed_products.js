// Puts the figures from the old Laravel shop's MySQL database (products.json)
// into the demo shop "Sakura Figures", for sale in the app. Run
// `npm run seed` first: it makes that shop and its owner account.
//
// For each figure this writes what the app itself writes when a shop owner
// adds an item and turns on "Sell in the app" (lib/data/inventory_repository.dart):
//   shops/{shop}/items/{sku}        the stock item, listed
//   shops/{shop}/moves/{sku}-opening  its opening stock, so History adds up
//   products/{shop}_{sku}           its copy in the customer catalog
// and hides the old house copy at products/{sku} (is_active = false), so
// nothing shows twice.
//
// The photos ship inside the app under assets/products, so image_url is an
// asset path, not a web URL. New photos added from the app go to Firebase
// Storage instead.
//
// Prices were USD there (sale price when it had one), turned into whole
// kyats at x4,500 and rounded to 1,000 Ks. Cost is set at 70% of the price
// so the stock value has something to show; change it in the app.
//
// Safe to run again: the ids are the old SKUs, so each run overwrites the
// same 18 items and resets their stock to products.json.
//
// Same key and steps as seed_users.js (see README):
//   npm run seed:products
// Against the local emulators: npm run seed:products:emulator
import { readFileSync } from 'node:fs';
import { initializeApp, applicationDefault } from 'firebase-admin/app';
import { getAuth } from 'firebase-admin/auth';
import { getFirestore, Timestamp } from 'firebase-admin/firestore';

const PROJECT_ID = process.env.GCLOUD_PROJECT || 'anime-figure-shop-lite';
const SHOP_EMAIL = 'shop@animefigureshop.test';
const onEmulator = Boolean(process.env.FIRESTORE_EMULATOR_HOST);

initializeApp(
  onEmulator
    ? { projectId: PROJECT_ID }
    : { projectId: PROJECT_ID, credential: applicationDefault() },
);
const db = getFirestore();

const products = JSON.parse(
  readFileSync(new URL('./products.json', import.meta.url), 'utf8'),
);

async function main() {
  console.log(
    `Seeding ${products.length} figures into Sakura Figures in ${
      onEmulator ? 'the local emulators' : `project ${PROJECT_ID}`
    }`,
  );

  const owner = await getAuth()
    .getUserByEmail(SHOP_EMAIL)
    .catch(() => null);
  if (!owner) {
    throw new Error(`No ${SHOP_EMAIL} account yet. Run "npm run seed" first.`);
  }
  const shopId = owner.uid;
  const shop = (await db.doc(`shops/${shopId}`).get()).data();
  if (!shop) throw new Error('The demo shop is missing. Run "npm run seed".');

  const now = Timestamp.now();
  const batch = db.batch();
  for (const { id, ...p } of products) {
    const quantity = p.stock_quantity;
    const moveId = `${id}-opening`;
    const listing = {
      name: p.name,
      description: p.description,
      price: p.price,
      image_url: p.image_url,
      category: p.category,
      anime: p.anime,
    };
    batch.set(db.doc(`shops/${shopId}/items/${id}`), {
      ...listing,
      code: id.toUpperCase(),
      unit: 'pcs',
      cost: Math.round((p.price * 0.7) / 1000) * 1000,
      quantity,
      low_stock_at: 2,
      is_active: true,
      listed: true,
      last_move_id: quantity > 0 ? moveId : '',
      created_at: now,
      updated_at: now,
    });
    if (quantity > 0) {
      batch.set(db.doc(`shops/${shopId}/moves/${moveId}`), {
        type: 'in',
        item_id: id,
        item_name: p.name,
        quantity,
        quantity_before: 0,
        quantity_after: quantity,
        unit_price: 0,
        customer_id: '',
        customer_name: '',
        note: 'Opening stock',
        created_by: shopId,
        created_at: now,
      });
    }
    batch.set(db.doc(`products/${shopId}_${id}`), {
      ...listing,
      stock_quantity: quantity,
      is_active: true,
      shop_id: shopId,
      shop_name: shop.name,
      shop_open_until: shop.expires_at,
      item_id: id,
      updated_at: now,
    });
  }
  // The old house copies, where an earlier run made them.
  const old = await db.getAll(...products.map((p) => db.doc(`products/${p.id}`)));
  for (const doc of old) {
    if (doc.exists) batch.update(doc.ref, { is_active: false });
  }
  await batch.commit();

  for (const p of products) {
    console.log(
      `  ${p.id.padEnd(15)} ${String(p.price).padStart(8)} Ks  x${p.stock_quantity}  ${p.name}`,
    );
  }
  console.log(`\nDone. Sign in as ${SHOP_EMAIL} to see them under Stock.`);
}

main().catch((e) => {
  console.error(e.message || e);
  process.exit(1);
});
