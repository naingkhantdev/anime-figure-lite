# Anime Figure Shop — Lite (small-use tier)

A small, standalone Flutter + Firebase shop app. It is **completely separate**
from the full project at `E:\StudioProjects\anime_figure_shop`.

| | Small use (this repo) | Large use (`anime_figure_shop`) |
|---|---|---|
| Clients | Flutter mobile only | Flutter mobile + React web/admin |
| Backend | Firebase (Auth + Firestore), no server code | Laravel API + MySQL |
| Admin | Firebase console | React admin panel |
| Business logic | Client + Firestore security rules | Server-side (Laravel) |
| Cost | Firebase Spark plan, $0, no card | Free tiers (Render/Aiven/Oracle) |
| Good for | A small shop, testing a market, few orders/day | Real volume, payments, pre-orders, points |

There is no shared data between the two. If the small shop grows, move to the
large project. The data shapes use the same snake_case names, so moving is easy.

## Features (v1)

- Prices in Myanmar kyat (MMK), shown as `25,000 Ks`
- Browse products without an account; sign in (email/password) only to
  check out or see "My orders"
- Search with a sort button beside it (recommended, price either way, name),
  and filter chips: **Category**, **Anime**, **Price** (slider or ready
  ranges), **Shop**, **In stock**. Tapping a figure's anime, category or
  shop on its page shows more of the same.
- Figures from the house and from shops that sell in the app, side by side
- Cart (in memory; kept when a guest signs in, cleared on sign-out)
- Checkout: phone, **Delivery** or **Pick up at shop**, address (delivery
  only), optional note. Pre-filled from the customer's last order. Shows
  the figures, each shop's **delivery fee** (none for pickup) and the total.
- Place an order. It is created as `pending`, one order per shop in the
  cart, so each shop handles its own.
- "My orders" with status and details; customers can cancel while `pending`
- On each order: **Call** and **Viber** buttons for the shop (and, on the
  shop's side, for the customer), the shop's **ways to pay** (KBZPay,
  WavePay, AYA Pay, CB Pay, bank) with copy buttons, and **Send payment
  screenshot**, replaceable while the order waits. Only the customer, that
  shop and the super admin can see the screenshot.
- Money still moves outside the app (wallet, bank transfer, cash on
  delivery); the screenshot saves sending it over Viber.

## Roles: one app, three kinds of people

The first screen depends on who is signed in (`lib/ui/pages/role_gate.dart`):

| Role | How they get it | What they see |
|---|---|---|
| Guest / customer | Nothing, or any account | The figure shop: browse, cart, checkout, My orders |
| **Shop admin** | Account menu → **Open a shop**, then you approve it | Their own stock: items, In / Out / Count, history, customers |
| **Super admin** (you) | A document at `super_admins/{your uid}`, made by hand in the Firebase console | Every shop: turn on, add 1/3/6/12 months, pick an end date, or stop now |

A shop's life: **Waiting** (just opened, `expires_at` empty, can't change
anything) → you add time → **Active** → yellow banner 7 days before the end →
**Expired** (read-only, nothing deleted) → you add time again.

### Make yourself super admin

1. Sign in to the app with your own account.
2. Firebase console → **Authentication** → copy your **User UID**.
3. **Firestore** → Start collection `super_admins` → Document ID = your UID →
   add any field (e.g. `note: "me"`) → Save.
4. Reopen the app. You now see the shop list instead of the figure shop.

Put how shop admins reach you (to be approved or renew) in
`lib/config.dart`, `supportContact`, e.g. `'Viber 09xxxxxxxxx'`.

### Stock features (shop admins)

- **Stock**: list with search, Low/Out/Hidden filters, counts and stock value
  at cost. Items have selling price, cost price, unit, code, and a "warn when
  at or below" level.
- **In / Out / Count** on each item. Out can name a customer and a price.
  Count sets the quantity to what is really on the shelf.
- **History**: every movement, grouped by day, with today's in, out and sales.
  It can never be edited or deleted; fix mistakes with a new movement.
- **Customers**: records the shop keeps (not app accounts), each with their
  recent purchases.
- **Sell in the app**: a switch on an item (with category, anime, photo link
  and description) puts it in the customer catalog under the shop's name.
  Its price and stock follow the item. The catalog hides a shop's figures
  while it is waiting or expired.
- **Orders**: customers' orders for the shop's figures. **Confirm** takes
  the stock out (a "Stock out" in History at the order's price), then
  **Shipped** / **Picked up**, or **Cancel**. Waiting orders show as a count
  on the tab. Each order has Call and Viber for the customer, and shows
  when they have sent a payment screenshot (tap to view it).
- **Shop settings** (Shop tab → edit): name, phone (required; customers call
  it), delivery fee, and up to six ways to pay. Saving needs an open shop.

### Look

Minimal glass (`lib/ui/theme.dart`, `lib/ui/widgets/glass.dart`): a pale
aurora ground (soft pink, lilac and sky glows), frosted white panels with a
bright rim, near-black ink, DM Sans. Pink is the one accent: main buttons,
prices, the cart badge, the selected tab, focus. Other colour only where it
means something: low stock, out of stock, in/out numbers, expiry. The bottom
bar floats as real frosted glass; cards are translucent without blur, so
long lists stay smooth.

Motion (`lib/ui/widgets/effects.dart`, `skeleton.dart`), all still when the
phone's "remove animations" setting is on:

- The app name in the bars and on sign-in gets a pink shine that sweeps
  across it now and then.
- The one panel holding a screen's main action (sign in, the cart total,
  place order, waiting for approval) has a beam of light running round its
  border.
- While data loads, a skeleton in the shape of the content shimmers instead
  of a spinner.
- List items fade in and rise into place, slowing as they settle: staggered
  on first load, then each one as it scrolls into view.

The phone shows white with the logo from the first instant (native splash),
then `lib/ui/widgets/splash_intro.dart` lets the logo settle and the name
fade in (~1.4 s) while the app loads underneath. A tap skips it.

### Languages

Every word the app shows lives in `lib/l10n/app_en.arb` (English). The app
follows the phone's language when it has a file for it, else English.

- **Add a language** (Burmese is `my`): copy `app_en.arb` to `app_my.arb`,
  set `"@@locale": "my"`, translate the values (not the keys, and keep
  `{placeholders}` as they are), then run `flutter gen-l10n`.
- **New text in code:** add a key to `app_en.arb`, run `flutter gen-l10n`,
  and use `context.l10n.yourKey`. Errors from `lib/data` and `lib/logic`
  carry `(l) => l.yourKey`, so they need no `BuildContext`.
- Stored values stay English in every language: categories, the `in` /
  `out` / `adjust` move types, and notes the app writes into History.

### Changing the logo

The logo is a red neon fighter, cut out with a transparent background (the
launcher icon puts it on dark navy). Everything is built from the source
art in `assets/brand/source/`:

- `logo.jpg`: the logo, square, the tile in the middle of the dark
  background (as the artist made it).
- `poses/1.jpg`, `2.jpg`, ...: more fighting poses in the same style, same
  tile and background. The splash plays them in name order as a quick
  combo, each strike with after-images, a red flash and a shockwave, then
  lands on the logo. With none, the fighter strikes three times in the
  logo's pose, the middle one mirrored.

After adding or changing any of them, from the project folder:

```
pip install pillow                           # once
python tool/brand_assets.py                  # logo, poses, icons, native splash
dart pub global run flutter_launcher_icons   # launcher icon
```

Then stop the app and `flutter run` again; hot restart doesn't pick up
images. The splash's navy is `AppColors.splash`, and the same colour is in
`android/app/src/main/res/values/colors.xml` and
`ios/Runner/Base.lproj/LaunchScreen.storyboard`; change all three together.

### Demo accounts (seed)

`tool/seed/seed_users.js` creates one account per role, all with password
`Password123!` (or `SEED_PASSWORD`):

| Role | Email |
|---|---|
| Super admin | `admin@animefigureshop.test` |
| Shop admin ("Sakura Figures", active 1 month) | `shop@animefigureshop.test` |
| Customer | `customer@animefigureshop.test` |

It needs an admin key for the real project:

1. Firebase console → Project settings → **Service accounts** → **Generate
   new private key**. Save it as `tool/seed/service-account.json`. It is in
   `.gitignore`; never commit or share it.
2. In PowerShell:
   ```
   cd tool\seed
   npm install
   $env:GOOGLE_APPLICATION_CREDENTIALS="service-account.json"
   npm run seed
   ```

Running it again is safe: it reuses the accounts and resets their passwords.
To try it on the local emulators instead (needs Java): `npm run seed:emulator`.

## Setup

1. Create a project at https://console.firebase.google.com and stay on the
   **Spark** (free) plan.
2. **Authentication → Sign-in method** → enable **Email/Password**.
3. **Firestore Database** → create a database (production mode).
4. **Firestore → Rules** → paste `firestore.rules` from this repo → Publish.
   It holds the rules for the figure shop and for the shops' stock; publish
   the whole file.
5. Generate `lib/firebase_options.dart` (the app won't compile without it):
   ```
   dart pub global activate flutterfire_cli
   firebase login            # needs the Firebase CLI: npm i -g firebase-tools
   flutterfire configure     # pick your project, platforms android + ios
   ```
6. iOS only: Firebase needs iOS 13+. In `ios/Podfile`, set
   `platform :ios, '13.0'`.
7. `flutter run`

## Releasing (Google Play)

- **App ID:** `com.animefigureshop.app`. It can never change once on Play.
- **Upload key:** `C:\Users\User\keys\anime-figure-shop-upload.jks`, outside
  the repo. Its password is in `android/key.properties` (git-ignored).
  **Back up both files** somewhere safe (a password manager or a USB stick).
  Turn on **Play App Signing** when creating the app in Play Console, so
  Google holds the final key and can reset a lost upload key.
- **Build:** bump `version:` in `pubspec.yaml` (the number after `+` must go
  up every upload), then `flutter build appbundle` and upload
  `build/app/outputs/bundle/release/app-release.aab`.
- **Crashlytics:** release builds report crashes to Firebase console →
  Crashlytics. Debug builds don't.
- **Privacy policy:** `public/privacy.html`, served by Firebase Hosting at
  https://anime-figure-shop-lite.web.app/privacy.html after
  `firebase deploy --only hosting`. Put that link in Play Console.
- **Account deletion:** Account → Delete my account (customers). Shop owners
  are asked to contact you; delete their shop and account in the console.
  For the Play "Data deletion" form, the web link is the privacy page.

## Data model (Firestore)

`products/{id}`. Load them with the seed script below, or add them in the
Firebase console.

| field | type | note |
|---|---|---|
| name | string | |
| description | string | |
| price | number (integer) | Whole kyats: 25000 = 25,000 Ks. Never use decimals or floats for money. |
| stock_quantity | number (integer) | |
| image_url | string | public image URL, or `assets/products/...` for a bundled photo (optional) |
| is_active | boolean | only `true` products are shown |
| category | string | one of the list in `lib/logic/catalog.dart` (optional) |
| anime | string | the series, e.g. `One Piece` (optional) |

A shop's figure is a copy of its item at `products/{shop id}_{item id}`,
written by the owner's app with the item, plus `shop_id`, `shop_name`,
`item_id`, `shop_open_until` (the shop's expiry) and `updated_at`. The rules
only accept it when every value equals the item and the shop, so the
catalog can't claim a price or stock the shop doesn't have. Renewing a shop
moves `shop_open_until` on its figures too.

The figures from the old Laravel shop (18, with photos) belong to the demo
shop **Sakura Figures**: `tool/seed/seed_products.js` (`npm run
seed:products`, after `npm run seed`) writes each one as a Sakura Figures
stock item, with its opening stock and its catalog copy, from
`tool/seed/products.json`, and hides any older house copy. Their photos
ship inside the app in `assets/products/`, so their `image_url` is an asset
path like `assets/products/fig-ph-924.webp`. Any `image_url` starting with
`assets/` is loaded from the app; anything else is loaded from the web.

**Photos from the app** (Edit item → Camera / Gallery) are shrunk on the
phone to at most 800 px, JPEG quality 70 (about 60–150 KB), and saved in
Firestore, one document each: `photos/{id}` with shop_id, data (bytes) and
created_at. The item's `image_url` is then `photo:{id}`. Firebase Storage
would be the usual place, but it needs the paid Blaze plan, which can't be
paid from Myanmar. The rules let only an open shop's owner add a photo, up
to 400 KB; anyone may view. The catalog loads each photo only when its card
shows, and the phone keeps it.

`orders/{id}`. Created by the app.
| field | type |
|---|---|
| user_id | string (Firebase Auth uid) |
| shop_id | string: the shop it was placed with; empty for the house's own figures (handled by staff in the console) |
| status | string: `pending` → `confirmed` → `shipped`, or `cancelled`. The shop moves its own orders one step at a time; staff do the house's in the console. The customer may set `cancelled` while `pending`. |
| items | array of `{product_id, name, price, quantity}` (price in whole kyats) |
| total | number (integer, whole kyats; **includes** delivery_fee) |
| delivery_fee | number (integer): the shop's fee from `shop_public` for delivery, 0 for pickup or the house. The rules check it. Absent on older orders. |
| payment_proof_id, payment_sent_at | the customer's payment screenshot in `payment_proofs`, once sent |
| phone | string, e.g. `09123456789` |
| delivery_method | string: `delivery` or `pickup` |
| address | string (empty for `pickup`) |
| note | string (may be empty) |
| created_at | timestamp (server time) |

### Stock data (one shop per account)

`super_admins/{uid}`: any fields; only its existence matters.

`shops/{owner uid}`
| field | type | note |
|---|---|---|
| name | string | |
| phone | string | may be empty |
| owner_email | string | |
| expires_at | timestamp or null | null = waiting. Only the super admin can change it. |
| created_at | timestamp | |

`shop_public/{shopId}`: what customers may know about a shop, readable by
anyone, written by the owner's app together with `shops/{id}` while the shop
is open: phone (always equal to the shop's), delivery_fee (int, whole
kyats), payment_methods (up to 6 of `{type, name, number}`, type one of
`kbzpay`, `wavepay`, `ayapay`, `cbpay`, `bank`), updated_at.
`shops/{id}` itself stays private (owner email, expiry).

`payment_proofs/{id}`: order_id, user_id, shop_id, data (bytes, JPEG up to
400 KB), created_at. A customer's screenshot of paying a shop. Readable
only by that customer, that shop and the super admin; only for the
customer's own pending order with a shop; never edited (a replacement is
a new document, and the old one is deleted). Deleting an account deletes
its screenshots.

`shops/{shopId}/items/{id}`: name, code, unit, price, cost, quantity,
low_stock_at (ints), is_active (bool), last_move_id, created_at, updated_at,
and for selling in the app listed (bool), category, anime, description,
image_url. Items are hidden, not deleted.

`shops/{shopId}/moves/{id}`: type (`in` / `out` / `adjust`), item_id,
item_name, quantity, quantity_before, quantity_after, unit_price, customer_id,
customer_name, note, created_by, created_at. Write-once.

`shops/{shopId}/customers/{id}`: name, phone, address, note, created_at,
updated_at.

### How the rules keep stock honest (no server code)

The Spark plan has no Cloud Functions, so `firestore.rules` does the work:

- A shop can only reach `shops/{its own uid}/…`.
- Writes are refused unless `expires_at` is in the future, so an expired shop
  can't keep working with a modified app.
- An item's `quantity` can only change in the same write as a new movement,
  and the movement's numbers must add up (before ± quantity = after, and
  "before" must be the real stored quantity). The history always explains the
  count, and stock can't go below zero.
- Only the super admin can change `expires_at`, and the super admin can't
  touch a shop's stock.

Tests for the rules (both the figure shop and stock) run on the local
emulator and need Java 11+:

```
cd rules_test
npm install
npm test
```

## Daily routine for staff

There are no notifications on the free plan, so check a few times a day:

1. Firebase console → Firestore → `orders` → filter `status == pending`.
2. For each order, check every line's `price` against the product's current
   `price`, and that `total` adds up (see limits below).
3. Contact the customer on `phone` with the final price, delivery fee and
   payment details.
4. When paid (or agreed for cash on delivery), set `status` to `confirmed`
   and lower each product's `stock_quantity` by hand.
5. Set `status` to `shipped` once it has been delivered or picked up.

Orders the customer cancelled show `cancelled`; nothing to do for those.

## Limits of the small tier (read this)

Stock (shop admins):

- **Stock in/out needs internet** (it runs as a transaction so two phones
  can't overwrite each other). Browsing works offline from the cache.
- **One login per shop.** Staff share the owner's account.
- The figure shop's `products` and the shop admins' stock are separate: an
  order here does not change anyone's stock.

The figure shop:


The Spark plan has **no Cloud Functions**, so there is no trusted server code.
That means:

- **Order prices come from the app.** The app reads the current prices from
  Firestore when it places the order. Someone with a modified app could still
  write a fake price, because security rules can't check every line of an
  order. **Before confirming an order, check its prices against the products.**
- **Stock is not reduced automatically.** When you confirm an order, lower
  `stock_quantity` by hand in the console. The app does block orders larger
  than the current stock.
- **No payments.** Collect payment outside the app (cash on delivery, bank
  transfer, mobile wallet) and then confirm the order.
- **No notifications.** Staff must check for new orders themselves (see the
  daily routine above).
- **Delivery fee is one flat fee per shop**, set in Shop settings (none for
  pickup). The house's own figures deliver free in the app; tell the
  customer any fee when confirming.
- **A payment screenshot is not a payment.** Check the money has arrived in
  the wallet or bank before confirming.
- **Images:** Cloud Storage for Firebase needs the Blaze plan for new
  projects, so use public image URLs (for example Cloudflare R2 or any image
  host).

Moving to Blaze would allow a Cloud Function to do pricing and stock on the
server. Blaze needs a card but is still $0 within the free quota.
