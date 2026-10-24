// Creates three demo accounts, one per role, so the app can be tried end to
// end. Safe to run again: existing accounts are reused and reset.
//
//   super admin   admin@animefigureshop.test     sees every shop
//   shop admin    shop@animefigureshop.test      "Sakura Figures", active 1 month
//   customer      customer@animefigureshop.test  the figure shop
//
// All three get the password in SEED_PASSWORD (default below).
//
// Against the real project (needs a service account key, see README):
//   npm install
//   set GOOGLE_APPLICATION_CREDENTIALS=service-account.json   (PowerShell:
//   $env:GOOGLE_APPLICATION_CREDENTIALS="service-account.json")
//   npm run seed
//
// Against the local emulators (no key needed): npm run seed:emulator
import { initializeApp, applicationDefault } from 'firebase-admin/app';
import { getAuth } from 'firebase-admin/auth';
import { getFirestore, FieldValue, Timestamp } from 'firebase-admin/firestore';

const PROJECT_ID = process.env.GCLOUD_PROJECT || 'anime-figure-shop-lite';
const PASSWORD = process.env.SEED_PASSWORD || 'Password123!';
const onEmulator = Boolean(process.env.FIRESTORE_EMULATOR_HOST);

initializeApp(
  onEmulator
    ? { projectId: PROJECT_ID }
    : { projectId: PROJECT_ID, credential: applicationDefault() },
);
const auth = getAuth();
const db = getFirestore();

/** The account for [email], created if missing, password reset if not. */
async function account(email, displayName) {
  try {
    const user = await auth.getUserByEmail(email);
    return auth.updateUser(user.uid, { password: PASSWORD, displayName });
  } catch (e) {
    if (e.code !== 'auth/user-not-found') throw e;
    return auth.createUser({ email, password: PASSWORD, displayName });
  }
}

/** Same date next month, like extendExpiry() in lib/logic/subscription.dart. */
function oneMonthFromNow() {
  const d = new Date();
  d.setMonth(d.getMonth() + 1);
  return d;
}

async function main() {
  console.log(
    `Seeding ${onEmulator ? 'the local emulators' : `project ${PROJECT_ID}`}`,
  );

  const admin = await account('admin@animefigureshop.test', 'Super Admin');
  await db.doc(`super_admins/${admin.uid}`).set({ note: 'seeded super admin' });

  const shop = await account('shop@animefigureshop.test', 'Sakura Figures');
  // Same fields firestore.rules require of a shop (lib/models/shop.dart).
  await db.doc(`shops/${shop.uid}`).set({
    name: 'Sakura Figures',
    phone: '09123456789',
    owner_email: shop.email,
    expires_at: Timestamp.fromDate(oneMonthFromNow()),
    created_at: FieldValue.serverTimestamp(),
  });

  const customer = await account('customer@animefigureshop.test', 'Customer');
  // A customer is any account that is neither of the above, so make sure no
  // earlier run left it with a shop or super admin rights.
  await db.doc(`shops/${customer.uid}`).delete();
  await db.doc(`super_admins/${customer.uid}`).delete();

  console.log('\nDone. Sign in with any of these, password:', PASSWORD);
  for (const [role, u] of [
    ['super admin', admin],
    ['shop admin ', shop],
    ['customer   ', customer],
  ]) {
    console.log(`  ${role}  ${u.email}  (uid ${u.uid})`);
  }
}

main().catch((e) => {
  console.error(e.message || e);
  process.exit(1);
});
