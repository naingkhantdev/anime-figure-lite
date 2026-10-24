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
- Cart (in memory; kept when a guest signs in, cleared on sign-out)
- Checkout: phone, **Delivery** or **Pick up at shop**, address (delivery
  only), optional note. Pre-filled from the customer's last order.
- Place an order. It is created as `pending`.
- "My orders" with status and details; customers can cancel while `pending`
- Payment happens outside the app (cash on delivery, bank transfer, mobile
  wallet)

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

### Launch

The phone shows navy with the logo from the first instant (native splash:
`android/app/src/main/res/drawable*/launch_background.xml`,
`values-v31/styles.xml` for Android 12+, and iOS `LaunchScreen.storyboard`).
Flutter's first frame is the same picture, then `lib/ui/widgets/splash_intro.dart`
plays a ~2 s intro (logo rises, name appears letter by letter, gold rule,
drifting petals) while the app loads underneath. A tap skips it; reduce
motion gets a still frame and a fade. The logo is 144dp everywhere
(`splashLogoSize`); change it in all those places together.

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

## Data model (Firestore)

`products/{id}`. Add products in the Firebase console.
| field | type | note |
|---|---|---|
| name | string | |
| description | string | |
| price | number (integer) | Whole kyats: 25000 = 25,000 Ks. Never use decimals or floats for money. |
| stock_quantity | number (integer) | |
| image_url | string | public image URL (optional) |
| is_active | boolean | only `true` products are shown |

`orders/{id}`. Created by the app.
| field | type |
|---|---|
| user_id | string (Firebase Auth uid) |
| status | string: `pending` → staff change to `confirmed` / `shipped` / `cancelled`. The customer may set `cancelled` while `pending`. |
| items | array of `{product_id, name, price, quantity}` (price in whole kyats) |
| total | number (integer, whole kyats; excludes any delivery fee) |
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

`shops/{shopId}/items/{id}`: name, code, unit, price, cost, quantity,
low_stock_at (ints), is_active (bool), last_move_id, created_at, updated_at.
Items are hidden, not deleted.

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
- **Delivery fee is not in the app.** Tell the customer when confirming.
- **Images:** Cloud Storage for Firebase needs the Blaze plan for new
  projects, so use public image URLs (for example Cloudflare R2 or any image
  host).

Moving to Blaze would allow a Cloud Function to do pricing and stock on the
server. Blaze needs a card but is still $0 within the free quota.
