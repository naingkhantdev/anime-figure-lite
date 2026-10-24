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

- Email/password sign-in and sign-up (Firebase Auth)
- Product list and detail, live from Firestore
- Cart (in memory, cleared on sign-out)
- Place an order. It is created as `pending`.
- "My orders" list with status

## Setup

1. Create a project at https://console.firebase.google.com and stay on the
   **Spark** (free) plan.
2. **Authentication → Sign-in method** → enable **Email/Password**.
3. **Firestore Database** → create a database (production mode).
4. **Firestore → Rules** → paste `firestore.rules` from this repo → Publish.
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
| price_cents | number (integer) | 1999 = 19.99. Never use decimals or floats for money. |
| stock_quantity | number (integer) | |
| image_url | string | public image URL (optional) |
| is_active | boolean | only `true` products are shown |

`orders/{id}`. Created by the app.
| field | type |
|---|---|
| user_id | string (Firebase Auth uid) |
| status | string: `pending` → staff change to `confirmed` / `shipped` / `cancelled` |
| items | array of `{product_id, name, price_cents, quantity}` |
| total_cents | number (integer) |
| created_at | timestamp (server time) |

## Limits of the small tier (read this)

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
  transfer) and then confirm the order.
- **Images:** Cloud Storage for Firebase needs the Blaze plan for new
  projects, so use public image URLs (for example Cloudflare R2 or any image
  host).

Moving to Blaze would allow a Cloud Function to do pricing and stock on the
server. Blaze needs a card but is still $0 within the free quota.
