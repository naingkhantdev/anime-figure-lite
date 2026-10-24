# Admin: sales, profit and stock in/out — design

Date: 2026-10-24 · Status: ready for owner approval · Author: staff designer

## 1. Intent

The shop owner runs Anime Figure Shop alone and sells two ways: orders placed
in this app, and walk-in sales at the counter. Today they manage everything in
the Firebase console: they change order status by hand and lower
`stock_quantity` by hand. Nothing records what sold on which day, what stock
came in, or what any of it cost.

They want to open the app on their phone and see **daily, weekly and monthly
sales and profit**, and **what stock came in and went out**. This means every
sale and every stock change has to go through the app. So this feature is also
the moment the console stops being the place where the shop is run.

Success looks like this. At closing time the owner opens Summary → Today and
sees money received, profit, cash in the drawer, and what sold. The figures add
up against the stock history and the shelf.

## 2. Goals, non-goals, anti-goals

**Goals**
- An admin area inside the existing Flutter app, visible only to the owner.
- In-app product management, so the console is no longer needed day to day.
- A full stock record with these entries: opening stock, stock in with cost,
  sales, order confirm and cancel, other stock out (loss), and stock count
  correction.
- Walk-in sales with discounts and a payment method.
- App-order lifecycle: confirm (adjust amount, add delivery fee, choose payment
  method, take stock), complete, and cancel (with restock).
- Summary for Today, This week and This month: money received, profit, losses
  and breakdowns.

**Non-goals (this version)**
- Receipts (shareable text or image).
- Staff accounts or roles, push notifications, photo upload (Firebase Storage
  needs Blaze), Burmese text, CSV export, in-app payment.
- Partial confirmation of an order, per-product low-stock limits, price history.

**Anti-goals: failures even if the feature "works"**
- A stock number that changes without a matching movement record.
- Profit shown for a sale whose cost is unknown, as if the profit were 100%.
- History that disappears. Mistakes are voided, never deleted.
- Admin data (sales, costs, movements, all customers' orders) readable by
  anyone other than the owner.
- Stock reduced for an order but no sale recorded (or the reverse) because a
  multi-step write half-failed.

## 3. Constraints

- **Firebase Spark plan, $0, no card, no server code.** All logic runs in the
  app. Multi-document changes **must** use Firestore transactions so they are
  all-or-nothing.
- **Admin actions need internet.** Transactions can't run offline. When offline,
  fail with: "No connection. Nothing was saved."
- **Money is integer whole kyats** (existing rule, `lib/utils/money.dart`). Never
  use doubles. Round only where stated (average cost).
- **Myanmar time is fixed at UTC+6:30** (no daylight saving). Periods are
  calculated in this zone whatever the phone's setting. Weeks run Monday to
  Sunday. Months are calendar months.
- **Flutter 3.22 / Material 3**, Riverpod 2, the existing minimal theme in
  `lib/ui/theme.dart`. Pink is kept for main actions, prices and focus.
- **Spark quotas:** 50k reads and 20k writes per day. A month summary reads that
  month's sales and movements, which is hundreds of documents at this shop's
  volume. That's fine. Don't add listeners that re-read whole collections
  repeatedly.
- The existing customer flow (browse, cart, checkout, My orders, customer cancel
  while pending) keeps working unchanged, apart from the status display in §7.6.

## 4. Decisions made with the owner

Q1–Q26 of the design interview, as decided:

1. Products are added and edited in the admin area.
2. Cancelling a **confirmed** order returns stock and reverses the sale.
3. Confirming is **blocked** if any line has too little stock. Stock never goes
   negative.
4. Existing products get a one-time **opening stock** entry (quantity + cost per
   figure). Until a product has a cost, its sales show "profit unknown".
5. **Stock out — other** (damaged, lost, gift) takes a reason. Its cost is a
   **loss** line, not a sale.
6. Confirming an app order lets the owner change the **final amount**
   (discount) and add a **delivery fee**. The fee is kept separate from figure
   profit.
7. Every sale records a **payment method**: Cash (default), KBZPay, Wave, Bank.
8. Mistakes are **voided**, not deleted.
9. Myanmar time, Monday-to-Sunday weeks.
10. A **separate admin account**, used only for running the shop.
11. Product photos stay as a pasted image link.
12. Optional **Series** and **Maker** fields on products.
13. Products are hidden, never deleted.
14. The stock number is **read-only** in the product editor. It changes only
    through movements, including a **stock count** correction.
15. Order statuses: Pending → Confirmed → Completed, plus Cancelled. Completed
    doesn't touch stock or money.
16. No notifications. The customer sees updates in My orders.
17. Whole-order confirm only.
18. Low stock list: products with stock ≤ 2 (one fixed limit).
19. Admin actions need internet.
20. Admin layout: 4 bottom tabs (Summary, Orders, Products, Stock), with
    "+ Sale" on Summary and "+ Stock in" on Stock.
21. Summary shows money received, profit (+ count of sales without cost),
    figures sold, app vs walk-in, payment methods, losses, top 5 by quantity.
22. Week and Month have a day-by-day list. Tapping a day shows that day's sales.
23. A walk-in sale has only an optional note.
24. No receipts.
25. Automated tests for the money and stock math. They run only when the owner
    asks (owner's preference).
26. Built in 3 phases (§9).
27. Phase 1 is for setup only; day-to-day use starts with phase 2.
28. The confirmed amount may be above the order total, with a warning.

## 5. Data model (Firestore)

All money is an int in whole kyats. All timestamps use
`FieldValue.serverTimestamp()`.

### 5.1 `products/{id}`, extended
Existing: `name`, `description`, `price`, `stock_quantity`, `image_url`,
`is_active`.

New fields:
| field | type | note |
|---|---|---|
| series | string | optional, "" when unset |
| maker | string | optional, "" when unset |
| updated_at | timestamp | |

`stock_quantity` is written only inside the movement transactions in §6.

### 5.1a `product_costs/{productId}`, new, admin only
| field | type | note |
|---|---|---|
| avg_cost | int or null | average cost per figure. null or missing doc = cost unknown |
| updated_at | timestamp | |

Cost lives here, not on `products`, because `products` is readable by everyone
and Firestore rules can't hide a single field (anti-goal: costs readable by
others). Every transaction in §6 that touches stock reads and writes the
product and its `product_costs` doc together. Wherever §6 says `avg_cost`, it
means this doc.

### 5.2 `stock_movements/{id}`, new, admin only
| field | type | note |
|---|---|---|
| product_id, product_name | string | name copied at the time |
| type | string | `opening`, `in`, `out_other`, `count`, `sale`, `order`, `order_cancel`, `sale_void`, `void` |
| quantity_change | int | signed: +5, −1 |
| unit_cost | int or null | cost per figure used for this movement |
| reason | string | required for `out_other`; optional otherwise |
| previous_quantity | int or null | on `opening` only: stock before the entry |
| sale_id / order_id | string or null | link when the movement comes from a sale or order |
| voided | bool | true once reversed |
| void_of | string or null | on a `void` movement, the id it reverses |
| created_at | timestamp | |

### 5.3 `sales/{id}`, new, admin only
| field | type | note |
|---|---|---|
| channel | string | `walk_in` or `app` |
| order_id | string or null | for `app` |
| lines | list of `{product_id, name, quantity, list_price, unit_cost}` | `unit_cost` is the product's `avg_cost` at the time of sale, may be null |
| subtotal | int | Σ quantity × list_price |
| amount_received | int | what the owner actually got for the figures (after discount, **excluding** delivery fee) |
| delivery_fee | int | 0 for walk-in |
| payment_method | string | `cash`, `kbzpay`, `wave`, `bank` |
| note | string | |
| voided | bool | |
| created_at, voided_at | timestamp | |

**Profit of a sale** = `amount_received − Σ quantity × unit_cost`. This is
defined only when every line has a `unit_cost`. Otherwise the sale counts as
"without cost": its money is counted, but its profit is not.

### 5.4 `orders/{id}`, extended
New fields are written by the admin only: `confirmed_at`, `completed_at`,
`cancelled_at`, `final_total` (= the sale's `amount_received`), `delivery_fee`,
`payment_method`, `sale_id`.

`status` ∈ `pending`, `confirmed`, `completed`, `cancelled`. Old documents may
hold `shipped` (set by hand in the past). Read it as `completed`.

**Legacy orders:** orders confirmed or shipped in the console before this
feature have no `sale_id`. Their stock was lowered by hand. They are
**read-only** in the admin area, with the note "Handled before the admin area:
not in sales or stock history". They don't appear in Summary (designer's call).

### 5.5 `admins/{uid}`, new
An empty document whose id is the owner's Auth uid. The owner creates it once
in the console. This is the **single source** of who the admin is, used by both
the rules and the app (designer's call, replacing "uid hard-coded in rules":
same result, and there's no uid in the code to keep in sync).

## 6. Stock and money rules (the math)

These go into pure Dart functions with no Firestore calls, so they can be
tested.

- **Average cost (stock in, opening, restock):**
  `new_avg = round((qty × avg + in_qty × in_cost) / (qty + in_qty))`. Rounding is
  half up to whole kyats. When `avg` is null and `qty` is 0, `new_avg = in_cost`.
- **Stock in is blocked** for a product with `avg_cost == null` and
  `stock_quantity > 0`. The owner must enter opening stock first, otherwise
  untracked figures would be mixed into the average. A product created in the
  app starts at stock 0 and cost null, so its first stock in works directly.
- **Opening stock:** allowed once, while `avg_cost == null`. The owner enters the
  real quantity (prefilled with the current `stock_quantity`) and a cost per
  figure. It writes an `opening` movement for the difference
  (`new − current`, may be 0) with `unit_cost`, sets `stock_quantity` and
  `avg_cost`.
- **Sale or order out:** `quantity_change = −q`, `unit_cost = avg_cost` (may be
  null). Average cost doesn't change when stock goes out.
- **Other stock out:** like a sale out, with a reason. **Loss** =
  `q × unit_cost`. Counted as "loss, cost unknown" when null.
- **Stock count:** the owner enters the counted number. `diff = counted − current`.
  A negative diff is a loss (same as other stock out, reason "count"). A
  positive diff adds stock **without** changing the average (designer's call:
  found figures have no purchase price). A diff of 0 records nothing.
- **Void an opening entry:** allowed only while it is the product's latest
  movement. Otherwise void the later movements first, or use Count. It
  restores `previous_quantity` and sets the cost back to null (designer's call;
  this replaces the value-removal formula for openings).
- **Void a manual movement** (`in`, `out_other`, `count`): write a
  `void` movement with the opposite quantity, and mark the original
  `voided = true`.
  - Voiding a stock in removes that batch's value:
    `new_avg = round((qty × avg − in_qty × in_cost) / (qty − in_qty))` when the
    remaining quantity is above 0. When it reaches 0, keep the last average.
  - Never let the average go below 0.
  - A void that would make stock negative is blocked: "Can't void: only N left."
  - Voiding an `out_other` or a negative `count` returns the figures at that
    movement's `unit_cost`, using the stock-in average formula (quantity only
    when null), the same as a voided sale (designer's call).
- **Void a walk-in sale:** mark the sale `voided`. Write `sale_void` movements
  that return each line, recalculating the average with that line's
  `unit_cost` as for a stock in, or quantity only when null.
- **Cancel a confirmed order:** in one transaction, set the order to
  `cancelled` and the sale to `voided`, and write `order_cancel` movements that
  return stock as above.
- Movements created by a sale or an order are voided **only** through that sale
  or order, never on their own.
- **Validation:**
  - Quantities are whole numbers ≥ 1.
  - Costs and prices are whole kyats ≥ 0.
  - A walk-in `amount_received` is between 1 and `subtotal` (a discount can't
    raise the price).
  - On an order confirm, `amount_received` is ≥ 0 with **no upper limit**
    (owner decision: an order may hold an old or tampered lower price). When it
    is above the order `total`, the sheet shows "Above the order total of
    50,000 Ks" but still allows it. `delivery_fee` ≥ 0.

### 6.1 Periods and summary
- Today = 00:00 to 24:00 Myanmar time. This week = Monday 00:00 to now. This
  month = the 1st at 00:00 to now. Query `created_at` ranges converted to UTC.
- Summary over **non-voided** sales and non-voided loss movements in the
  period:
  - money received = Σ `amount_received`
  - delivery fees = Σ `delivery_fee`, shown as a separate small line
  - profit = Σ profit over sales with full cost, plus "N sales without cost"
  - figures sold = Σ line quantities
  - app vs walk-in = money and count for each channel
  - payment methods = money for each method. Delivery fees are included here,
    because that is the cash actually collected.
  - losses = Σ loss, plus "N items with unknown cost"
  - top 5 = products by quantity sold, ties broken by name
- Week and Month: a list of days, newest first, each with money and profit.
  Days with no sales are left out.

## 7. Screens (staff designer spec)

Visual language: the existing minimal theme. White canvas, ink text, 1 px
borders, 12 px radius, one pink accent. Amounts use `formatMmk`. There's no new
decoration: hierarchy comes from size and weight. Every list has an empty state
written in plain words. Every save shows a progress state on its button and a
snackbar on success. Every failure shows a plain message (never a raw
exception), and the form keeps what was typed.

### 7.1 Entry and shell
- When the signed-in user has an `admins/{uid}` document, the app opens on
  **Admin** instead of the shop. A "View shop" item in the Admin app bar menu
  opens the customer storefront, and a "Admin" icon there returns. Sign out
  stays in the menu. Customers never see any admin entry. (Designer's call:
  this account exists only to run the shop, so it should land on admin.)
- Shell: Material 3 `NavigationBar` with icon + label: **Summary**, **Orders**
  (badge = number of pending orders), **Products**, **Stock**. Each tab keeps its
  scroll position when switching.

### 7.2 Summary (opens first)
Top to bottom:
1. Segmented control: Today | This week | This month.
2. **Money received**: large display number, ink colour. Below it, smaller:
   "Profit 84,000 Ks" plus "· 2 sales without cost" when needed.
3. **Low stock**: shown only when any product has ≤ 2 in stock. A compact
   list of name + count, where tapping opens the product.
4. A plain list of rows (label left, value right):
   - Figures sold
   - App orders (money · count)
   - Walk-in (money · count)
   - Cash / KBZPay / Wave / Bank (only methods with money)
   - Delivery fees
   - Losses
5. **Top 5**: name and quantity.
6. Week and Month only: **day list** (date like "Fri 24 Oct", money, profit).
   Tapping a day opens a day page listing that day's sales (time, channel,
   items, amount). Tapping a sale opens the sale detail. A walk-in sale has
   "Void sale" there. An app sale links to its order.
7. An extended FAB, bottom right: **+ Sale**.

### 7.3 Walk-in sale (full-screen page)
- Search field (name, series or maker) above a list of active products in
  stock, each with a thumbnail, name, price and stock. Tapping adds 1. A
  stepper limits quantity to stock.
- A sticky bottom panel: selected lines (tap to change or remove),
  **Subtotal**, an **Amount received** field prefilled with the subtotal, and a
  line showing "Discount 5,000 Ks" when lower.
- Payment method chips (Cash selected by default; they wrap on narrow phones),
  an optional Note field, and the main button **Record sale · 45,000 Ks**.
- On success, return to Summary with the snackbar "Sale recorded". If stock ran
  out in the meantime: "Only N of X left. Nothing was saved."

### 7.4 Orders
- Filter chips: **Pending** (default) | Confirmed | Completed | Cancelled.
- Each row shows the first item name + "and 2 more", the total, the phone and
  the age ("3 h ago").
- Order detail shows:
  - each line, with a **warning** when its price differs from the product's
    current price ("Price now 28,000 Ks"). This replaces the README's manual
    price check.
  - delivery method, address, note, and the phone with a copy action.
- Actions by status:
  - **Pending:** **Confirm** opens a confirm sheet: Amount received (prefilled
    with the total), Delivery fee (0), payment method chips, and the button
    "Confirm · takes stock". **Cancel** asks for confirmation; no stock
    change.
  - **Confirmed:** **Mark completed** and **Cancel order**. Cancelling warns
    "Stock goes back and the sale is removed from the summary." The confirm
    button is red.
  - **Completed / Cancelled:** read only.
- When Amount received is above the order total, the sheet shows the warning
  from §6 next to the field.
- When stock is short at confirm, the sheet shows "Only N of X left." and
  confirms nothing.

### 7.5 Products and Stock
- **Products tab:** a search field, then a list with a thumbnail, name, price,
  stock and a "Hidden" tag. FAB **+ Product**.
  - The **editor** has: Name*, Price*, Description, Image link (with a live
    preview), Series, Maker, and a "Visible in shop" switch.
  - Stock is shown read-only, with its average cost, and with actions:
    **Stock in**, **Stock out**, **Count**, and **Set opening stock** (shown
    only while the cost is unknown, flagged "Cost unknown, profit can't be
    calculated").
- **Stock tab:** history, newest first, grouped by day. A row shows the
  product, the signed quantity, a type label ("Stock in", "Sale", "Order",
  "Loss: damaged", "Count", "Void"), and the cost. Voided rows are struck
  through. There's a product filter. FAB **+ Stock in**. The app-bar menu
  holds **Stock out** and **Count**.
  - Tapping a manual movement opens its detail, with **Void** behind a
    confirmation.
- The Stock in, Stock out, Count and Opening forms each pick a product and
  show the current stock and average cost before saving.

### 7.6 Customer-facing changes
- My orders status labels: Pending → "Waiting for shop", "Confirmed",
  "Completed", "Cancelled".
- Once an order is confirmed, show "Confirmed amount" (`final_total`) and the
  delivery fee when it's above 0.

## 8. Security rules

- `isAdmin()` = `request.auth != null && exists(/databases/$(database)/documents/admins/$(request.auth.uid))`.
- `products`: read for everyone (unchanged). Write only when `isAdmin()`.
- `stock_movements`, `sales`, `product_costs`: read and write only when `isAdmin()`. No delete.
- `orders`: the existing customer rules stay. Add read (including list) for
  admin, and update for admin. There's no delete.
- `admins/{uid}`: read only when `request.auth.uid == uid`. Write never; the
  owner creates it in the console.
- The rules don't check that admin writes are consistent. The admin is
  trusted, and consistency comes from the transactions in §6.
- **Deploying the rules is an action on the live project.** The owner approves
  it each time.

## 9. Phases

Each phase is usable on its own.

1. **Admin access, products, stock.** Includes `admins` and the rules, the
   shell (with placeholder Summary and Orders tabs), the product editor, opening
   stock, stock in, stock out, count, void, the Stock history, and low stock.
   **Setup and checking only** (owner decision). Real selling stays in the
   console until phase 2 is in, because phase 1 has no way to record a sale.
   Enter opening stock close to the phase 2 release. Phase 1's README says
   this plainly.
2. **Sales and orders.** Includes the walk-in sale, sale void, order confirm,
   complete and cancel, and the customer status display.
3. **Summary.** Includes periods, totals, top 5, the day list, and the day and
   sale pages.

Each phase updates README: data model, and "Daily routine" rewritten around the
admin area. Each phase adds unit tests for its math (§6). Tests are written
but run only when the owner asks.

## 10. Left to the builder

- File and folder layout, provider structure, and widget breakdown, following
  existing code style.
- How transactions are wrapped and how the existing `OrderException` style
  extends to admin errors.
- Whether to add a Firestore fake for repository tests. Pure-function tests are
  required either way.
- The exact query and listener strategy, as long as it stays within §3 quotas
  and needs no composite index (or the index is added to `firestore.indexes.json`
  and noted for deployment).
- Calls marked "designer's call" in this document. The owner may change them
  while reviewing.
