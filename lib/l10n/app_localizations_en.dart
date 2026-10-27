import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get errQuantityNegative => 'Quantity cannot be negative.';

  @override
  String get errQuantityAtLeastOne => 'Enter a quantity of at least 1.';

  @override
  String errOnlyInStock(int count) {
    return 'Only $count in stock.';
  }

  @override
  String get errQuantityTooLarge => 'Quantity is too large.';

  @override
  String get errCartEmpty => 'Your cart is empty.';

  @override
  String errTooManyOrderLines(int max) {
    return 'An order can have at most $max products.';
  }

  @override
  String get errPhoneFormat => 'Enter a phone number like 09xxxxxxxxx.';

  @override
  String get errAddressEmpty => 'Enter a delivery address.';

  @override
  String errProductUnavailable(String name) {
    return '$name is no longer available.';
  }

  @override
  String errOnlyLeftOf(int count, String name) {
    return 'Only $count of $name left in stock.';
  }

  @override
  String get errShopNameEmpty => 'Enter the shop name.';

  @override
  String errShopNameTooLong(int max) {
    return 'Keep the shop name under $max letters.';
  }

  @override
  String get errPhotoTooBig => 'That photo is still too big after shrinking. Try another one.';

  @override
  String get errItemNameEmpty => 'Enter the item name.';

  @override
  String errNameTooLong(int max) {
    return 'Keep the name under $max letters.';
  }

  @override
  String errCodeTooLong(int max) {
    return 'Keep the code under $max letters.';
  }

  @override
  String errUnitTooLong(int max) {
    return 'Keep the unit under $max letters.';
  }

  @override
  String get errPriceTooLarge => 'That price is too large.';

  @override
  String get errLowStockTooLarge => 'The low stock level is too large.';

  @override
  String get errPickCategory => 'Pick a category from the list.';

  @override
  String errAnimeTooLong(int max) {
    return 'Keep the anime name under $max letters.';
  }

  @override
  String errTextTooLong(int max) {
    return 'Keep it under $max letters.';
  }

  @override
  String get errPhotoAddressUnknown => 'That photo address is not one the app knows.';

  @override
  String get errListedNeedsPrice => 'Set a selling price to sell this item in the app.';

  @override
  String get errShopLoading => 'Your shop is still loading.';

  @override
  String get errItemGone => 'This item no longer exists.';

  @override
  String errNoteTooLong(int max) {
    return 'Keep the note under $max letters.';
  }

  @override
  String get errNameEmpty => 'Enter the name.';

  @override
  String get errNotAllowed => 'Not allowed. If your shop has expired, contact the owner to renew.';

  @override
  String get errOffline => 'No internet connection. Try again when online.';

  @override
  String get moveIn => 'Stock in';

  @override
  String get moveOut => 'Stock out';

  @override
  String get moveCount => 'Count';

  @override
  String get sortFeatured => 'Recommended';

  @override
  String get sortPriceLow => 'Lowest price';

  @override
  String get sortPriceHigh => 'Highest price';

  @override
  String get sortName => 'Name A to Z';

  @override
  String get deliveryMethodDelivery => 'Delivery';

  @override
  String get deliveryMethodPickup => 'Pick up at shop';

  @override
  String get categoryScaleFigure => 'Scale figure';

  @override
  String get categoryNendoroid => 'Nendoroid';

  @override
  String get categoryGarageKit => 'Garage kit';

  @override
  String get categoryPrizeFigure => 'Prize figure';

  @override
  String get categoryActionFigure => 'Action figure';

  @override
  String get categoryAcrylicStand => 'Acrylic stand';

  @override
  String get categoryOther => 'Other';

  @override
  String get cancel => 'Cancel';

  @override
  String get signIn => 'Sign in';

  @override
  String get signOut => 'Sign out';

  @override
  String get signOutQuestion => 'Sign out?';

  @override
  String get couldNotLoad => 'Could not load this';

  @override
  String get shopStatusWaiting => 'Waiting';

  @override
  String get shopStatusActive => 'Active';

  @override
  String get shopStatusExpired => 'Expired';

  @override
  String shopDaysLeftShort(int days) {
    return '${days}d left';
  }

  @override
  String shopExpiredBanner(String date) {
    return 'Your shop expired on $date. You can still look at everything, but not change it. Contact the owner to renew.';
  }

  @override
  String shopExpiresBanner(int days, String date) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days days',
      one: '1 day',
    );
    return 'Your shop expires in $_temp0 ($date). Contact the owner to renew.';
  }

  @override
  String get typeEmailFirst => 'Type your email first, then tap this again.';

  @override
  String passwordResetSent(String email) {
    return 'Password reset email sent to $email.';
  }

  @override
  String get createAnAccount => 'Create an account';

  @override
  String get welcomeBack => 'Welcome back';

  @override
  String get signUpSubtitle => 'One account to shop, track orders and run a shop.';

  @override
  String get signInSubtitle => 'Sign in to check out and see your orders.';

  @override
  String get email => 'Email';

  @override
  String get password => 'Password';

  @override
  String get hidePassword => 'Hide password';

  @override
  String get showPassword => 'Show password';

  @override
  String get createAccount => 'Create account';

  @override
  String get haveAccountSignIn => 'Already have an account? Sign in';

  @override
  String get newHereCreateAccount => 'New here? Create an account';

  @override
  String get forgotPassword => 'Forgot password?';

  @override
  String get deleteMyAccount => 'Delete my account';

  @override
  String get deleteMyAccountQuestion => 'Delete my account?';

  @override
  String get closeShopBody => 'Your account holds your shop and its stock history, so we close it for you. Contact us to close your shop and delete your account.';

  @override
  String closeShopBodyContact(String contact) {
    return 'Your account holds your shop and its stock history, so we close it for you. Contact us to close your shop and delete your account: $contact';
  }

  @override
  String get ok => 'OK';

  @override
  String get accountDeleted => 'Your account has been deleted.';

  @override
  String get wrongPassword => 'Wrong password.';

  @override
  String get deleteAccountBody => 'This cannot be undone. Pending orders are cancelled. Past orders stay with the shop, without your phone number or address.';

  @override
  String get yourPassword => 'Your password';

  @override
  String get delete => 'Delete';

  @override
  String get oneLastStep => 'One last step';

  @override
  String get nameYourShop => 'Name your shop';

  @override
  String get nameYourShopHelp => 'You can change these later. The shop opens once the owner approves it.';

  @override
  String get shopName => 'Shop name';

  @override
  String get phoneOptional => 'Phone (optional)';

  @override
  String get createShop => 'Create shop';

  @override
  String shopWaitingForApproval(String shop) {
    return '$shop is waiting for approval';
  }

  @override
  String shopWaitingBody(String appName) {
    return 'The owner of $appName will turn your shop on. This page opens your shop by itself as soon as they do.';
  }

  @override
  String contactLine(String contact) {
    return 'Contact: $contact';
  }

  @override
  String accountLine(String email) {
    return 'Account: $email';
  }

  @override
  String get tabShop => 'Shop';

  @override
  String get tabCart => 'Cart';

  @override
  String get tabOrders => 'Orders';

  @override
  String get tabAccount => 'Account';

  @override
  String get myOrders => 'My orders';

  @override
  String get signInToSeeOrders => 'Sign in to see your orders';

  @override
  String get signInToSeeOrdersBody => 'Orders you place show up here, with what the shop is doing with them.';

  @override
  String get goToAccount => 'Go to Account';

  @override
  String get browseFigures => 'Browse figures';

  @override
  String get signedInAs => 'Signed in as';

  @override
  String get signedIn => 'Signed in';

  @override
  String get openAShop => 'Open a shop';

  @override
  String get openAShopSubtitle => 'Sell and track your own stock';

  @override
  String get browsingAsGuest => 'You are browsing as a guest';

  @override
  String get guestIntro => 'Look around as much as you like. An account lets you:';

  @override
  String get benefitCheckout => 'Check out in a few taps';

  @override
  String get benefitCheckoutLine => 'Your phone and address are remembered.';

  @override
  String get benefitFollow => 'Follow every order';

  @override
  String get benefitFollowLine => 'See when the shop confirms and sends it.';

  @override
  String get benefitShop => 'Open your own shop';

  @override
  String get benefitShopLine => 'Track stock and sell your figures here.';

  @override
  String get keepBrowsing => 'Keep browsing';

  @override
  String ordersPlaced(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Placed $count orders, one for each shop. Each shop confirms its own.',
      one: 'Order placed. The shop will confirm it soon.',
    );
    return '$_temp0';
  }

  @override
  String couldNotPlaceOrder(String error) {
    return 'Could not place order: $error';
  }

  @override
  String get checkout => 'Checkout';

  @override
  String get phone => 'Phone';

  @override
  String get deliveryAddress => 'Delivery address';

  @override
  String get deliveryAddressHint => 'Township, street, landmark';

  @override
  String get noteOptional => 'Note (optional)';

  @override
  String get estimatedTotal => 'Estimated total';

  @override
  String get payShopDirectly => 'Pay the shop directly. The shop confirms the final price and any delivery fee.';

  @override
  String get placeOrder => 'Place order';

  @override
  String get cartEmpty => 'Your cart is empty';

  @override
  String get cartEmptyBody => 'Figures you add show up here.';

  @override
  String itemCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count items',
      one: '1 item',
    );
    return '$_temp0';
  }

  @override
  String get continueShopping => 'Continue shopping';

  @override
  String get orderSummary => 'Order summary';

  @override
  String figuresCount(int count) {
    return 'Figures ($count)';
  }

  @override
  String get setByShop => 'Set by the shop';

  @override
  String cartManyShops(int shops) {
    return 'These come from $shops shops, so you will get one order from each. Each shop confirms its price and any delivery fee.';
  }

  @override
  String get cartOneShop => 'The shop confirms the final price and any delivery fee.';

  @override
  String priceEach(String price) {
    return '$price each';
  }

  @override
  String get remove => 'Remove';

  @override
  String get decrease => 'Decrease';

  @override
  String get increase => 'Increase';

  @override
  String get noOrdersYet => 'No orders yet';

  @override
  String get noOrdersYetBody => 'When you check out, your order shows up here.';

  @override
  String get couldNotLoadOrders => 'Could not load your orders';

  @override
  String get statusWaitingForShop => 'Waiting for shop';

  @override
  String get statusConfirmed => 'Confirmed';

  @override
  String get statusPickedUp => 'Picked up';

  @override
  String get statusOnItsWay => 'On its way';

  @override
  String get statusCancelled => 'Cancelled';

  @override
  String get cancelOrderQuestion => 'Cancel this order?';

  @override
  String get keepOrder => 'Keep order';

  @override
  String get cancelOrder => 'Cancel order';

  @override
  String get orderCancelled => 'Order cancelled.';

  @override
  String couldNotCancelOrder(String error) {
    return 'Could not cancel this order: $error';
  }

  @override
  String noteLine(String note) {
    return 'Note: $note';
  }

  @override
  String get figureGone => 'This figure is no longer available';

  @override
  String onlyLeft(int count) {
    return 'Only $count left';
  }

  @override
  String inStockCount(int count) {
    return '$count in stock';
  }

  @override
  String get soldOut => 'Sold out';

  @override
  String moreFrom(String anime) {
    return 'More from $anime';
  }

  @override
  String moreOfCategory(String category) {
    return 'More: $category';
  }

  @override
  String get seeEverythingFromShop => 'See everything from this shop';

  @override
  String inYourCart(int count) {
    return '$count in your cart';
  }

  @override
  String get addToCart => 'Add to cart';

  @override
  String addedToCart(String name) {
    return 'Added $name';
  }

  @override
  String get viewCart => 'View cart';

  @override
  String get noFiguresYet => 'No figures yet';

  @override
  String get noFiguresYetBody => 'New figures appear here as soon as a shop adds them.';

  @override
  String figuresShownOf(int shown, int total) {
    return '$shown of $total figures';
  }

  @override
  String figuresCountPlain(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count figures',
      one: '1 figure',
    );
    return '$_temp0';
  }

  @override
  String get clearAll => 'Clear all';

  @override
  String get noFiguresMatch => 'No figures match';

  @override
  String get noFiguresMatchBody => 'Try another word, or fewer filters.';

  @override
  String get showAllFigures => 'Show all figures';

  @override
  String get couldNotLoadFigures => 'Could not load the figures';

  @override
  String priceFrom(String price) {
    return 'From $price';
  }

  @override
  String priceUpTo(String price) {
    return 'Up to $price';
  }

  @override
  String get anyPrice => 'Any price';

  @override
  String get searchHint => 'Search figures or anime';

  @override
  String get clearSearch => 'Clear search';

  @override
  String get filters => 'Filters';

  @override
  String get all => 'All';

  @override
  String get inStock => 'In stock';

  @override
  String get sortAndFilter => 'Sort & filter';

  @override
  String get reset => 'Reset';

  @override
  String get sortBy => 'Sort by';

  @override
  String get inStockOnly => 'In stock only';

  @override
  String get inStockOnlyHelp => 'Hide figures that are sold out';

  @override
  String get price => 'Price';

  @override
  String get min => 'Min';

  @override
  String get max => 'Max';

  @override
  String get minMoreThanMax => 'Min is more than max.';

  @override
  String priceUnder(String amount) {
    return 'Under $amount';
  }

  @override
  String priceOver(String amount) {
    return 'Over $amount';
  }

  @override
  String get category => 'Category';

  @override
  String get anime => 'Anime';

  @override
  String get checkPriceRange => 'Check the price range';

  @override
  String showFigures(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Show $count figures',
      one: 'Show 1 figure',
    );
    return '$_temp0';
  }

  @override
  String get newItem => 'New item';

  @override
  String get newCustomer => 'New customer';

  @override
  String get tabStock => 'Stock';

  @override
  String get tabHistory => 'History';

  @override
  String get tabCustomers => 'Customers';

  @override
  String get shopReadOnly => 'Your shop is read-only until the owner renews it.';

  @override
  String get edit => 'Edit';

  @override
  String activeUntil(String date) {
    return 'Active until $date';
  }

  @override
  String expiredOn(String date) {
    return 'Expired on $date';
  }

  @override
  String daysLeftRenew(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days days left.',
      one: '1 day left.',
    );
    return '$_temp0 Contact the owner to renew.';
  }

  @override
  String get readOnlyRenew => 'Read-only. Contact the owner to renew.';

  @override
  String get shopDetails => 'Shop details';

  @override
  String get save => 'Save';

  @override
  String get statItems => 'Items';

  @override
  String get statLow => 'Low';

  @override
  String get statOut => 'Out';

  @override
  String stockWorthAtCost(String value) {
    return 'Stock worth $value at cost';
  }

  @override
  String get searchNameOrCode => 'Search name or code';

  @override
  String get lowStock => 'Low stock';

  @override
  String get outOfStock => 'Out of stock';

  @override
  String get hidden => 'Hidden';

  @override
  String get noItemsYet => 'No items yet';

  @override
  String get noItemsYetBody => 'Tap \"New item\" to add the first thing you sell.';

  @override
  String get nothingMatches => 'Nothing matches';

  @override
  String get inTheApp => 'In the app';

  @override
  String itemHidden(String name) {
    return '$name is hidden.';
  }

  @override
  String itemBack(String name) {
    return '$name is back.';
  }

  @override
  String get hideFromStockList => 'Hide from stock list';

  @override
  String get showInStockListAgain => 'Show in stock list again';

  @override
  String get itemIsGone => 'This item is gone';

  @override
  String get moveInShort => 'In';

  @override
  String get noMovesYet => 'No stock movements yet.';

  @override
  String get sellingPrice => 'Selling price';

  @override
  String get costPrice => 'Cost price';

  @override
  String get profitEach => 'Profit each';

  @override
  String get lowStockAt => 'Low stock at';

  @override
  String get code => 'Code';

  @override
  String errMustBeWholeNumber(String field) {
    return '$field must be a whole number.';
  }

  @override
  String get lowStockLevel => 'Low stock level';

  @override
  String get startingQuantity => 'Starting quantity';

  @override
  String get editItem => 'Edit item';

  @override
  String get name => 'Name';

  @override
  String get codeOptional => 'Code (optional)';

  @override
  String get codeHint => 'SKU / barcode';

  @override
  String get unit => 'Unit';

  @override
  String get unitHint => 'pcs, box, kg';

  @override
  String get warnAtOrBelow => 'Warn when at or below';

  @override
  String get changeQuantityHelp => 'To change the quantity, use In, Out or Count on the item page, so the history stays right.';

  @override
  String get addItem => 'Add item';

  @override
  String get addAPhoto => 'Add a photo';

  @override
  String get photo => 'Photo';

  @override
  String get photoHelp => 'Customers see it in the shop. It is made smaller before it is saved.';

  @override
  String get camera => 'Camera';

  @override
  String get gallery => 'Gallery';

  @override
  String get sellInApp => 'Sell in the app';

  @override
  String get sellInAppOn => 'Customers see it in the shop, with your shop name. Its stock follows this item.';

  @override
  String get sellInAppOff => 'Turn on to show it to customers in the app.';

  @override
  String get descriptionOptional => 'Description (optional)';

  @override
  String get descriptionHint => 'Size, maker, condition, what is in the box';

  @override
  String get errQuantityWhole => 'Quantity must be a whole number.';

  @override
  String get errPriceWhole => 'Price must be a whole number of kyats.';

  @override
  String moveSaved(String move, String name) {
    return '$move saved for $name.';
  }

  @override
  String get errEnterWholeNumber => 'Enter a whole number.';

  @override
  String get moveInHelp => 'New stock arrived.';

  @override
  String get moveOutHelp => 'Sold or taken out.';

  @override
  String get moveCountHelp => 'You counted the shelf. Enter how many are really there.';

  @override
  String get counted => 'Counted';

  @override
  String get quantity => 'Quantity';

  @override
  String get costEach => 'Cost each';

  @override
  String get sellingPriceEach => 'Selling price each';

  @override
  String totalLine(String amount) {
    return 'Total $amount';
  }

  @override
  String get saveStockIn => 'Save stock in';

  @override
  String get saveStockOut => 'Save stock out';

  @override
  String get saveCount => 'Save count';

  @override
  String get customerOptional => 'Customer (optional)';

  @override
  String get walkInCustomer => 'Walk-in customer';

  @override
  String get toDo => 'To do';

  @override
  String get done => 'Done';

  @override
  String get noOrdersToHandle => 'No orders to handle';

  @override
  String get noFinishedOrders => 'No finished orders yet';

  @override
  String get noOrdersToHandleBody => 'When a customer orders something you sell in the app, it shows up here.';

  @override
  String get noFinishedOrdersBody => 'Shipped and cancelled orders are kept here.';

  @override
  String get shopCancelOrderBody => 'The customer sees it as cancelled. Stock you already took out stays out; record a Stock in to put it back.';

  @override
  String get keepIt => 'Keep it';

  @override
  String get orderConfirmedDone => 'Confirmed. The stock went out and is in History.';

  @override
  String get confirm => 'Confirm';

  @override
  String get markedOnItsWay => 'Marked as on its way.';

  @override
  String get shipped => 'Shipped';

  @override
  String get today => 'Today';

  @override
  String get sales => 'Sales';

  @override
  String get counts => 'Counts';

  @override
  String get noMovementsYet => 'No movements yet';

  @override
  String get noMovementsYetBody => 'Open an item and tap In, Out or Count.';

  @override
  String showingLatest(int count) {
    return 'Showing the latest $count. Open an item to see all of its history.';
  }

  @override
  String get searchNameOrPhone => 'Search name or phone';

  @override
  String get noCustomersYet => 'No customers yet';

  @override
  String get noCustomersYetBody => 'Add regulars here, then pick them when you record a stock out.';

  @override
  String deleteNameQuestion(String name) {
    return 'Delete $name?';
  }

  @override
  String get deleteCustomerBody => 'Past stock outs keep their name.';

  @override
  String get addressOptional => 'Address (optional)';

  @override
  String get addCustomer => 'Add customer';

  @override
  String get recentPurchases => 'Recent purchases';

  @override
  String get saving => 'Saving…';

  @override
  String get shops => 'Shops';

  @override
  String get searchShops => 'Search name, email or phone';

  @override
  String get expiring => 'Expiring';

  @override
  String get noShopsHere => 'No shops here';

  @override
  String get noShopsHereBody => 'New shops appear when someone signs up in the app.';

  @override
  String signedUpOn(String date) {
    return 'Signed up $date';
  }

  @override
  String untilDaysLeft(String date, int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days days left',
      one: '1 day left',
    );
    return 'Until $date · $_temp0';
  }

  @override
  String get shopWorksUntil => 'Shop works until the end of';

  @override
  String shopNowRunsUntil(String shop, String date) {
    return '$shop now runs until $date.';
  }

  @override
  String stopShopQuestion(String shop) {
    return 'Stop $shop now?';
  }

  @override
  String get stopShopBody => 'The shop becomes read-only straight away. Its data is kept, and renewing turns it back on.';

  @override
  String get stopNow => 'Stop now';

  @override
  String shopStopped(String shop) {
    return '$shop has been stopped.';
  }

  @override
  String get waitingForYou => 'Waiting for you to turn it on.';

  @override
  String runsUntil(String date) {
    return 'Runs until $date';
  }

  @override
  String addTimeFrom(String date) {
    return 'Add time from $date';
  }

  @override
  String get addTimeFromToday => 'Add time from today';

  @override
  String addMonths(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '+ $count months',
      one: '+ 1 month',
    );
    return '$_temp0';
  }

  @override
  String get addOneYear => '+ 1 year';

  @override
  String get pickEndDate => 'Pick an end date';

  @override
  String get stopThisShopNow => 'Stop this shop now';

  @override
  String get loading => 'Loading';
}
