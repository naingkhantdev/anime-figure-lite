// Puts the figures from the old Laravel shop's MySQL database into the
// figure shop (`products/{id}`, see lib/models/product.dart). The list is in
// products.json; the photos ship inside the app under assets/products, so
// image_url is an asset path, not a web URL (no Firebase Storage needed).
//
// Prices were USD there (sale price when it had one), turned into whole
// kyats at x4,500 and rounded to 1,000 Ks.
//
// Safe to run again: the document id is the old SKU, so each run overwrites
// the same 18 products and leaves any others alone.
//
// Same key and steps as seed_users.js (see README):
//   npm run seed:products
// Against the local emulators: npm run seed:products:emulator
import { readFileSync } from 'node:fs';
import { initializeApp, applicationDefault } from 'firebase-admin/app';
import { getFirestore } from 'firebase-admin/firestore';

const PROJECT_ID = process.env.GCLOUD_PROJECT || 'anime-figure-shop-lite';
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
    `Seeding ${products.length} products into ${
      onEmulator ? 'the local emulators' : `project ${PROJECT_ID}`
    }`,
  );

  const batch = db.batch();
  for (const { id, ...p } of products) {
    batch.set(db.doc(`products/${id}`), { ...p, is_active: true });
  }
  await batch.commit();

  for (const p of products) {
    console.log(
      `  ${p.id.padEnd(15)} ${String(p.price).padStart(8)} Ks  x${p.stock_quantity}  ${p.name}`,
    );
  }
  console.log('\nDone.');
}

main().catch((e) => {
  console.error(e.message || e);
  process.exit(1);
});
