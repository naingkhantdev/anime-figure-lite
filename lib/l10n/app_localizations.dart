import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en')
  ];

  /// No description provided for @errQuantityNegative.
  ///
  /// In en, this message translates to:
  /// **'Quantity cannot be negative.'**
  String get errQuantityNegative;

  /// No description provided for @errQuantityAtLeastOne.
  ///
  /// In en, this message translates to:
  /// **'Enter a quantity of at least 1.'**
  String get errQuantityAtLeastOne;

  /// No description provided for @errOnlyInStock.
  ///
  /// In en, this message translates to:
  /// **'Only {count} in stock.'**
  String errOnlyInStock(int count);

  /// No description provided for @errQuantityTooLarge.
  ///
  /// In en, this message translates to:
  /// **'Quantity is too large.'**
  String get errQuantityTooLarge;

  /// No description provided for @errCartEmpty.
  ///
  /// In en, this message translates to:
  /// **'Your cart is empty.'**
  String get errCartEmpty;

  /// No description provided for @errTooManyOrderLines.
  ///
  /// In en, this message translates to:
  /// **'An order can have at most {max} products.'**
  String errTooManyOrderLines(int max);

  /// No description provided for @errPhoneFormat.
  ///
  /// In en, this message translates to:
  /// **'Enter a phone number like 09xxxxxxxxx.'**
  String get errPhoneFormat;

  /// No description provided for @errAddressEmpty.
  ///
  /// In en, this message translates to:
  /// **'Enter a delivery address.'**
  String get errAddressEmpty;

  /// No description provided for @errProductUnavailable.
  ///
  /// In en, this message translates to:
  /// **'{name} is no longer available.'**
  String errProductUnavailable(String name);

  /// No description provided for @errOnlyLeftOf.
  ///
  /// In en, this message translates to:
  /// **'Only {count} of {name} left in stock.'**
  String errOnlyLeftOf(int count, String name);

  /// No description provided for @errShopNameEmpty.
  ///
  /// In en, this message translates to:
  /// **'Enter the shop name.'**
  String get errShopNameEmpty;

  /// No description provided for @errShopNameTooLong.
  ///
  /// In en, this message translates to:
  /// **'Keep the shop name under {max} letters.'**
  String errShopNameTooLong(int max);

  /// No description provided for @errPhotoTooBig.
  ///
  /// In en, this message translates to:
  /// **'That photo is still too big after shrinking. Try another one.'**
  String get errPhotoTooBig;

  /// No description provided for @errItemNameEmpty.
  ///
  /// In en, this message translates to:
  /// **'Enter the item name.'**
  String get errItemNameEmpty;

  /// No description provided for @errNameTooLong.
  ///
  /// In en, this message translates to:
  /// **'Keep the name under {max} letters.'**
  String errNameTooLong(int max);

  /// No description provided for @errCodeTooLong.
  ///
  /// In en, this message translates to:
  /// **'Keep the code under {max} letters.'**
  String errCodeTooLong(int max);

  /// No description provided for @errUnitTooLong.
  ///
  /// In en, this message translates to:
  /// **'Keep the unit under {max} letters.'**
  String errUnitTooLong(int max);

  /// No description provided for @errPriceTooLarge.
  ///
  /// In en, this message translates to:
  /// **'That price is too large.'**
  String get errPriceTooLarge;

  /// No description provided for @errLowStockTooLarge.
  ///
  /// In en, this message translates to:
  /// **'The low stock level is too large.'**
  String get errLowStockTooLarge;

  /// No description provided for @errPickCategory.
  ///
  /// In en, this message translates to:
  /// **'Pick a category from the list.'**
  String get errPickCategory;

  /// No description provided for @errAnimeTooLong.
  ///
  /// In en, this message translates to:
  /// **'Keep the anime name under {max} letters.'**
  String errAnimeTooLong(int max);

  /// No description provided for @errTextTooLong.
  ///
  /// In en, this message translates to:
  /// **'Keep it under {max} letters.'**
  String errTextTooLong(int max);

  /// No description provided for @errPhotoAddressUnknown.
  ///
  /// In en, this message translates to:
  /// **'That photo address is not one the app knows.'**
  String get errPhotoAddressUnknown;

  /// No description provided for @errListedNeedsPrice.
  ///
  /// In en, this message translates to:
  /// **'Set a selling price to sell this item in the app.'**
  String get errListedNeedsPrice;

  /// No description provided for @errShopLoading.
  ///
  /// In en, this message translates to:
  /// **'Your shop is still loading.'**
  String get errShopLoading;

  /// No description provided for @errItemGone.
  ///
  /// In en, this message translates to:
  /// **'This item no longer exists.'**
  String get errItemGone;

  /// No description provided for @errNoteTooLong.
  ///
  /// In en, this message translates to:
  /// **'Keep the note under {max} letters.'**
  String errNoteTooLong(int max);

  /// No description provided for @errNameEmpty.
  ///
  /// In en, this message translates to:
  /// **'Enter the name.'**
  String get errNameEmpty;

  /// No description provided for @errNotAllowed.
  ///
  /// In en, this message translates to:
  /// **'Not allowed. If your shop has expired, contact the owner to renew.'**
  String get errNotAllowed;

  /// No description provided for @errOffline.
  ///
  /// In en, this message translates to:
  /// **'No internet connection. Try again when online.'**
  String get errOffline;

  /// No description provided for @moveIn.
  ///
  /// In en, this message translates to:
  /// **'Stock in'**
  String get moveIn;

  /// No description provided for @moveOut.
  ///
  /// In en, this message translates to:
  /// **'Stock out'**
  String get moveOut;

  /// No description provided for @moveCount.
  ///
  /// In en, this message translates to:
  /// **'Count'**
  String get moveCount;

  /// No description provided for @sortFeatured.
  ///
  /// In en, this message translates to:
  /// **'Recommended'**
  String get sortFeatured;

  /// No description provided for @sortPriceLow.
  ///
  /// In en, this message translates to:
  /// **'Lowest price'**
  String get sortPriceLow;

  /// No description provided for @sortPriceHigh.
  ///
  /// In en, this message translates to:
  /// **'Highest price'**
  String get sortPriceHigh;

  /// No description provided for @sortName.
  ///
  /// In en, this message translates to:
  /// **'Name A to Z'**
  String get sortName;

  /// No description provided for @deliveryMethodDelivery.
  ///
  /// In en, this message translates to:
  /// **'Delivery'**
  String get deliveryMethodDelivery;

  /// No description provided for @deliveryMethodPickup.
  ///
  /// In en, this message translates to:
  /// **'Pick up at shop'**
  String get deliveryMethodPickup;

  /// No description provided for @categoryScaleFigure.
  ///
  /// In en, this message translates to:
  /// **'Scale figure'**
  String get categoryScaleFigure;

  /// No description provided for @categoryNendoroid.
  ///
  /// In en, this message translates to:
  /// **'Nendoroid'**
  String get categoryNendoroid;

  /// No description provided for @categoryGarageKit.
  ///
  /// In en, this message translates to:
  /// **'Garage kit'**
  String get categoryGarageKit;

  /// No description provided for @categoryPrizeFigure.
  ///
  /// In en, this message translates to:
  /// **'Prize figure'**
  String get categoryPrizeFigure;

  /// No description provided for @categoryActionFigure.
  ///
  /// In en, this message translates to:
  /// **'Action figure'**
  String get categoryActionFigure;

  /// No description provided for @categoryAcrylicStand.
  ///
  /// In en, this message translates to:
  /// **'Acrylic stand'**
  String get categoryAcrylicStand;

  /// No description provided for @categoryOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get categoryOther;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @signIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get signIn;

  /// No description provided for @signOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get signOut;

  /// No description provided for @signOutQuestion.
  ///
  /// In en, this message translates to:
  /// **'Sign out?'**
  String get signOutQuestion;

  /// No description provided for @couldNotLoad.
  ///
  /// In en, this message translates to:
  /// **'Could not load this'**
  String get couldNotLoad;

  /// No description provided for @shopStatusWaiting.
  ///
  /// In en, this message translates to:
  /// **'Waiting'**
  String get shopStatusWaiting;

  /// No description provided for @shopStatusActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get shopStatusActive;

  /// No description provided for @shopStatusExpired.
  ///
  /// In en, this message translates to:
  /// **'Expired'**
  String get shopStatusExpired;

  /// No description provided for @shopDaysLeftShort.
  ///
  /// In en, this message translates to:
  /// **'{days}d left'**
  String shopDaysLeftShort(int days);

  /// No description provided for @shopExpiredBanner.
  ///
  /// In en, this message translates to:
  /// **'Your shop expired on {date}. You can still look at everything, but not change it. Contact the owner to renew.'**
  String shopExpiredBanner(String date);

  /// No description provided for @shopExpiresBanner.
  ///
  /// In en, this message translates to:
  /// **'Your shop expires in {days, plural, =1{1 day} other{{days} days}} ({date}). Contact the owner to renew.'**
  String shopExpiresBanner(int days, String date);

  /// No description provided for @typeEmailFirst.
  ///
  /// In en, this message translates to:
  /// **'Type your email first, then tap this again.'**
  String get typeEmailFirst;

  /// No description provided for @passwordResetSent.
  ///
  /// In en, this message translates to:
  /// **'Password reset email sent to {email}.'**
  String passwordResetSent(String email);

  /// No description provided for @createAnAccount.
  ///
  /// In en, this message translates to:
  /// **'Create an account'**
  String get createAnAccount;

  /// No description provided for @welcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome back'**
  String get welcomeBack;

  /// No description provided for @signUpSubtitle.
  ///
  /// In en, this message translates to:
  /// **'One account to shop, track orders and run a shop.'**
  String get signUpSubtitle;

  /// No description provided for @signInSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in to check out and see your orders.'**
  String get signInSubtitle;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @hidePassword.
  ///
  /// In en, this message translates to:
  /// **'Hide password'**
  String get hidePassword;

  /// No description provided for @showPassword.
  ///
  /// In en, this message translates to:
  /// **'Show password'**
  String get showPassword;

  /// No description provided for @createAccount.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get createAccount;

  /// No description provided for @haveAccountSignIn.
  ///
  /// In en, this message translates to:
  /// **'Already have an account? Sign in'**
  String get haveAccountSignIn;

  /// No description provided for @newHereCreateAccount.
  ///
  /// In en, this message translates to:
  /// **'New here? Create an account'**
  String get newHereCreateAccount;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get forgotPassword;

  /// No description provided for @deleteMyAccount.
  ///
  /// In en, this message translates to:
  /// **'Delete my account'**
  String get deleteMyAccount;

  /// No description provided for @deleteMyAccountQuestion.
  ///
  /// In en, this message translates to:
  /// **'Delete my account?'**
  String get deleteMyAccountQuestion;

  /// No description provided for @closeShopBody.
  ///
  /// In en, this message translates to:
  /// **'Your account holds your shop and its stock history, so we close it for you. Contact us to close your shop and delete your account.'**
  String get closeShopBody;

  /// No description provided for @closeShopBodyContact.
  ///
  /// In en, this message translates to:
  /// **'Your account holds your shop and its stock history, so we close it for you. Contact us to close your shop and delete your account: {contact}'**
  String closeShopBodyContact(String contact);

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @accountDeleted.
  ///
  /// In en, this message translates to:
  /// **'Your account has been deleted.'**
  String get accountDeleted;

  /// No description provided for @wrongPassword.
  ///
  /// In en, this message translates to:
  /// **'Wrong password.'**
  String get wrongPassword;

  /// No description provided for @deleteAccountBody.
  ///
  /// In en, this message translates to:
  /// **'This cannot be undone. Pending orders are cancelled. Past orders stay with the shop, without your phone number or address.'**
  String get deleteAccountBody;

  /// No description provided for @yourPassword.
  ///
  /// In en, this message translates to:
  /// **'Your password'**
  String get yourPassword;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @oneLastStep.
  ///
  /// In en, this message translates to:
  /// **'One last step'**
  String get oneLastStep;

  /// No description provided for @nameYourShop.
  ///
  /// In en, this message translates to:
  /// **'Name your shop'**
  String get nameYourShop;

  /// No description provided for @nameYourShopHelp.
  ///
  /// In en, this message translates to:
  /// **'You can change these later. The shop opens once the owner approves it.'**
  String get nameYourShopHelp;

  /// No description provided for @shopName.
  ///
  /// In en, this message translates to:
  /// **'Shop name'**
  String get shopName;

  /// No description provided for @phoneOptional.
  ///
  /// In en, this message translates to:
  /// **'Phone (optional)'**
  String get phoneOptional;

  /// No description provided for @createShop.
  ///
  /// In en, this message translates to:
  /// **'Create shop'**
  String get createShop;

  /// No description provided for @shopWaitingForApproval.
  ///
  /// In en, this message translates to:
  /// **'{shop} is waiting for approval'**
  String shopWaitingForApproval(String shop);

  /// No description provided for @shopWaitingBody.
  ///
  /// In en, this message translates to:
  /// **'The owner of {appName} will turn your shop on. This page opens your shop by itself as soon as they do.'**
  String shopWaitingBody(String appName);

  /// No description provided for @contactLine.
  ///
  /// In en, this message translates to:
  /// **'Contact: {contact}'**
  String contactLine(String contact);

  /// No description provided for @accountLine.
  ///
  /// In en, this message translates to:
  /// **'Account: {email}'**
  String accountLine(String email);

  /// No description provided for @tabShop.
  ///
  /// In en, this message translates to:
  /// **'Shop'**
  String get tabShop;

  /// No description provided for @tabCart.
  ///
  /// In en, this message translates to:
  /// **'Cart'**
  String get tabCart;

  /// No description provided for @tabOrders.
  ///
  /// In en, this message translates to:
  /// **'Orders'**
  String get tabOrders;

  /// No description provided for @tabAccount.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get tabAccount;

  /// No description provided for @myOrders.
  ///
  /// In en, this message translates to:
  /// **'My orders'**
  String get myOrders;

  /// No description provided for @signInToSeeOrders.
  ///
  /// In en, this message translates to:
  /// **'Sign in to see your orders'**
  String get signInToSeeOrders;

  /// No description provided for @signInToSeeOrdersBody.
  ///
  /// In en, this message translates to:
  /// **'Orders you place show up here, with what the shop is doing with them.'**
  String get signInToSeeOrdersBody;

  /// No description provided for @goToAccount.
  ///
  /// In en, this message translates to:
  /// **'Go to Account'**
  String get goToAccount;

  /// No description provided for @browseFigures.
  ///
  /// In en, this message translates to:
  /// **'Browse figures'**
  String get browseFigures;

  /// No description provided for @signedInAs.
  ///
  /// In en, this message translates to:
  /// **'Signed in as'**
  String get signedInAs;

  /// No description provided for @signedIn.
  ///
  /// In en, this message translates to:
  /// **'Signed in'**
  String get signedIn;

  /// No description provided for @openAShop.
  ///
  /// In en, this message translates to:
  /// **'Open a shop'**
  String get openAShop;

  /// No description provided for @openAShopSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Sell and track your own stock'**
  String get openAShopSubtitle;

  /// No description provided for @browsingAsGuest.
  ///
  /// In en, this message translates to:
  /// **'You are browsing as a guest'**
  String get browsingAsGuest;

  /// No description provided for @guestIntro.
  ///
  /// In en, this message translates to:
  /// **'Look around as much as you like. An account lets you:'**
  String get guestIntro;

  /// No description provided for @benefitCheckout.
  ///
  /// In en, this message translates to:
  /// **'Check out in a few taps'**
  String get benefitCheckout;

  /// No description provided for @benefitCheckoutLine.
  ///
  /// In en, this message translates to:
  /// **'Your phone and address are remembered.'**
  String get benefitCheckoutLine;

  /// No description provided for @benefitFollow.
  ///
  /// In en, this message translates to:
  /// **'Follow every order'**
  String get benefitFollow;

  /// No description provided for @benefitFollowLine.
  ///
  /// In en, this message translates to:
  /// **'See when the shop confirms and sends it.'**
  String get benefitFollowLine;

  /// No description provided for @benefitShop.
  ///
  /// In en, this message translates to:
  /// **'Open your own shop'**
  String get benefitShop;

  /// No description provided for @benefitShopLine.
  ///
  /// In en, this message translates to:
  /// **'Track stock and sell your figures here.'**
  String get benefitShopLine;

  /// No description provided for @keepBrowsing.
  ///
  /// In en, this message translates to:
  /// **'Keep browsing'**
  String get keepBrowsing;

  /// No description provided for @ordersPlaced.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Order placed. The shop will confirm it soon.} other{Placed {count} orders, one for each shop. Each shop confirms its own.}}'**
  String ordersPlaced(int count);

  /// No description provided for @couldNotPlaceOrder.
  ///
  /// In en, this message translates to:
  /// **'Could not place order: {error}'**
  String couldNotPlaceOrder(String error);

  /// No description provided for @checkout.
  ///
  /// In en, this message translates to:
  /// **'Checkout'**
  String get checkout;

  /// No description provided for @phone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get phone;

  /// No description provided for @deliveryAddress.
  ///
  /// In en, this message translates to:
  /// **'Delivery address'**
  String get deliveryAddress;

  /// No description provided for @deliveryAddressHint.
  ///
  /// In en, this message translates to:
  /// **'Township, street, landmark'**
  String get deliveryAddressHint;

  /// No description provided for @noteOptional.
  ///
  /// In en, this message translates to:
  /// **'Note (optional)'**
  String get noteOptional;

  /// No description provided for @estimatedTotal.
  ///
  /// In en, this message translates to:
  /// **'Estimated total'**
  String get estimatedTotal;

  /// No description provided for @payShopDirectly.
  ///
  /// In en, this message translates to:
  /// **'Pay the shop after you order: how to pay is on your order. Cash on delivery works too.'**
  String get payShopDirectly;

  /// No description provided for @placeOrder.
  ///
  /// In en, this message translates to:
  /// **'Place order'**
  String get placeOrder;

  /// No description provided for @cartEmpty.
  ///
  /// In en, this message translates to:
  /// **'Your cart is empty'**
  String get cartEmpty;

  /// No description provided for @cartEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Figures you add show up here.'**
  String get cartEmptyBody;

  /// No description provided for @itemCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 item} other{{count} items}}'**
  String itemCount(int count);

  /// No description provided for @continueShopping.
  ///
  /// In en, this message translates to:
  /// **'Continue shopping'**
  String get continueShopping;

  /// No description provided for @orderSummary.
  ///
  /// In en, this message translates to:
  /// **'Order summary'**
  String get orderSummary;

  /// No description provided for @figuresCount.
  ///
  /// In en, this message translates to:
  /// **'Figures ({count})'**
  String figuresCount(int count);

  /// No description provided for @setByShop.
  ///
  /// In en, this message translates to:
  /// **'Added at checkout'**
  String get setByShop;

  /// No description provided for @cartManyShops.
  ///
  /// In en, this message translates to:
  /// **'These come from {shops} shops, so you will get one order from each, and each shop charges its own delivery.'**
  String cartManyShops(int shops);

  /// No description provided for @cartOneShop.
  ///
  /// In en, this message translates to:
  /// **'Pick delivery or pickup at checkout.'**
  String get cartOneShop;

  /// No description provided for @priceEach.
  ///
  /// In en, this message translates to:
  /// **'{price} each'**
  String priceEach(String price);

  /// No description provided for @remove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get remove;

  /// No description provided for @decrease.
  ///
  /// In en, this message translates to:
  /// **'Decrease'**
  String get decrease;

  /// No description provided for @increase.
  ///
  /// In en, this message translates to:
  /// **'Increase'**
  String get increase;

  /// No description provided for @noOrdersYet.
  ///
  /// In en, this message translates to:
  /// **'No orders yet'**
  String get noOrdersYet;

  /// No description provided for @noOrdersYetBody.
  ///
  /// In en, this message translates to:
  /// **'When you check out, your order shows up here.'**
  String get noOrdersYetBody;

  /// No description provided for @couldNotLoadOrders.
  ///
  /// In en, this message translates to:
  /// **'Could not load your orders'**
  String get couldNotLoadOrders;

  /// No description provided for @statusWaitingForShop.
  ///
  /// In en, this message translates to:
  /// **'Waiting for shop'**
  String get statusWaitingForShop;

  /// No description provided for @statusConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Confirmed'**
  String get statusConfirmed;

  /// No description provided for @statusPickedUp.
  ///
  /// In en, this message translates to:
  /// **'Picked up'**
  String get statusPickedUp;

  /// No description provided for @statusOnItsWay.
  ///
  /// In en, this message translates to:
  /// **'On its way'**
  String get statusOnItsWay;

  /// No description provided for @statusCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get statusCancelled;

  /// No description provided for @cancelOrderQuestion.
  ///
  /// In en, this message translates to:
  /// **'Cancel this order?'**
  String get cancelOrderQuestion;

  /// No description provided for @keepOrder.
  ///
  /// In en, this message translates to:
  /// **'Keep order'**
  String get keepOrder;

  /// No description provided for @cancelOrder.
  ///
  /// In en, this message translates to:
  /// **'Cancel order'**
  String get cancelOrder;

  /// No description provided for @orderCancelled.
  ///
  /// In en, this message translates to:
  /// **'Order cancelled.'**
  String get orderCancelled;

  /// No description provided for @couldNotCancelOrder.
  ///
  /// In en, this message translates to:
  /// **'Could not cancel this order: {error}'**
  String couldNotCancelOrder(String error);

  /// No description provided for @noteLine.
  ///
  /// In en, this message translates to:
  /// **'Note: {note}'**
  String noteLine(String note);

  /// No description provided for @figureGone.
  ///
  /// In en, this message translates to:
  /// **'This figure is no longer available'**
  String get figureGone;

  /// No description provided for @onlyLeft.
  ///
  /// In en, this message translates to:
  /// **'Only {count} left'**
  String onlyLeft(int count);

  /// No description provided for @inStockCount.
  ///
  /// In en, this message translates to:
  /// **'{count} in stock'**
  String inStockCount(int count);

  /// No description provided for @soldOut.
  ///
  /// In en, this message translates to:
  /// **'Sold out'**
  String get soldOut;

  /// No description provided for @moreFrom.
  ///
  /// In en, this message translates to:
  /// **'More from {anime}'**
  String moreFrom(String anime);

  /// No description provided for @moreOfCategory.
  ///
  /// In en, this message translates to:
  /// **'More: {category}'**
  String moreOfCategory(String category);

  /// No description provided for @seeEverythingFromShop.
  ///
  /// In en, this message translates to:
  /// **'See everything from this shop'**
  String get seeEverythingFromShop;

  /// No description provided for @inYourCart.
  ///
  /// In en, this message translates to:
  /// **'{count} in your cart'**
  String inYourCart(int count);

  /// No description provided for @addToCart.
  ///
  /// In en, this message translates to:
  /// **'Add to cart'**
  String get addToCart;

  /// No description provided for @addedToCart.
  ///
  /// In en, this message translates to:
  /// **'Added {name}'**
  String addedToCart(String name);

  /// No description provided for @viewCart.
  ///
  /// In en, this message translates to:
  /// **'View cart'**
  String get viewCart;

  /// No description provided for @noFiguresYet.
  ///
  /// In en, this message translates to:
  /// **'No figures yet'**
  String get noFiguresYet;

  /// No description provided for @noFiguresYetBody.
  ///
  /// In en, this message translates to:
  /// **'New figures appear here as soon as a shop adds them.'**
  String get noFiguresYetBody;

  /// No description provided for @figuresShownOf.
  ///
  /// In en, this message translates to:
  /// **'{shown} of {total} figures'**
  String figuresShownOf(int shown, int total);

  /// No description provided for @figuresCountPlain.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 figure} other{{count} figures}}'**
  String figuresCountPlain(int count);

  /// No description provided for @clearAll.
  ///
  /// In en, this message translates to:
  /// **'Clear all'**
  String get clearAll;

  /// No description provided for @noFiguresMatch.
  ///
  /// In en, this message translates to:
  /// **'No figures match'**
  String get noFiguresMatch;

  /// No description provided for @noFiguresMatchBody.
  ///
  /// In en, this message translates to:
  /// **'Try another word, or fewer filters.'**
  String get noFiguresMatchBody;

  /// No description provided for @showAllFigures.
  ///
  /// In en, this message translates to:
  /// **'Show all figures'**
  String get showAllFigures;

  /// No description provided for @couldNotLoadFigures.
  ///
  /// In en, this message translates to:
  /// **'Could not load the figures'**
  String get couldNotLoadFigures;

  /// No description provided for @priceFrom.
  ///
  /// In en, this message translates to:
  /// **'From {price}'**
  String priceFrom(String price);

  /// No description provided for @priceUpTo.
  ///
  /// In en, this message translates to:
  /// **'Up to {price}'**
  String priceUpTo(String price);

  /// No description provided for @anyPrice.
  ///
  /// In en, this message translates to:
  /// **'Any price'**
  String get anyPrice;

  /// No description provided for @searchHint.
  ///
  /// In en, this message translates to:
  /// **'Search figures or anime'**
  String get searchHint;

  /// No description provided for @clearSearch.
  ///
  /// In en, this message translates to:
  /// **'Clear search'**
  String get clearSearch;

  /// No description provided for @filters.
  ///
  /// In en, this message translates to:
  /// **'Filters'**
  String get filters;

  /// No description provided for @all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get all;

  /// No description provided for @inStock.
  ///
  /// In en, this message translates to:
  /// **'In stock'**
  String get inStock;

  /// No description provided for @sortAndFilter.
  ///
  /// In en, this message translates to:
  /// **'Sort & filter'**
  String get sortAndFilter;

  /// No description provided for @reset.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get reset;

  /// No description provided for @sortBy.
  ///
  /// In en, this message translates to:
  /// **'Sort by'**
  String get sortBy;

  /// No description provided for @inStockOnly.
  ///
  /// In en, this message translates to:
  /// **'In stock only'**
  String get inStockOnly;

  /// No description provided for @inStockOnlyHelp.
  ///
  /// In en, this message translates to:
  /// **'Hide figures that are sold out'**
  String get inStockOnlyHelp;

  /// No description provided for @price.
  ///
  /// In en, this message translates to:
  /// **'Price'**
  String get price;

  /// No description provided for @min.
  ///
  /// In en, this message translates to:
  /// **'Min'**
  String get min;

  /// No description provided for @max.
  ///
  /// In en, this message translates to:
  /// **'Max'**
  String get max;

  /// No description provided for @minMoreThanMax.
  ///
  /// In en, this message translates to:
  /// **'Min is more than max.'**
  String get minMoreThanMax;

  /// No description provided for @priceUnder.
  ///
  /// In en, this message translates to:
  /// **'Under {amount}'**
  String priceUnder(String amount);

  /// No description provided for @priceOver.
  ///
  /// In en, this message translates to:
  /// **'Over {amount}'**
  String priceOver(String amount);

  /// No description provided for @category.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get category;

  /// No description provided for @anime.
  ///
  /// In en, this message translates to:
  /// **'Anime'**
  String get anime;

  /// No description provided for @checkPriceRange.
  ///
  /// In en, this message translates to:
  /// **'Check the price range'**
  String get checkPriceRange;

  /// No description provided for @showFigures.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Show 1 figure} other{Show {count} figures}}'**
  String showFigures(int count);

  /// No description provided for @newItem.
  ///
  /// In en, this message translates to:
  /// **'New item'**
  String get newItem;

  /// No description provided for @newCustomer.
  ///
  /// In en, this message translates to:
  /// **'New customer'**
  String get newCustomer;

  /// No description provided for @tabStock.
  ///
  /// In en, this message translates to:
  /// **'Stock'**
  String get tabStock;

  /// No description provided for @tabHistory.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get tabHistory;

  /// No description provided for @tabCustomers.
  ///
  /// In en, this message translates to:
  /// **'Customers'**
  String get tabCustomers;

  /// No description provided for @shopReadOnly.
  ///
  /// In en, this message translates to:
  /// **'Your shop is read-only until the owner renews it.'**
  String get shopReadOnly;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @activeUntil.
  ///
  /// In en, this message translates to:
  /// **'Active until {date}'**
  String activeUntil(String date);

  /// No description provided for @expiredOn.
  ///
  /// In en, this message translates to:
  /// **'Expired on {date}'**
  String expiredOn(String date);

  /// No description provided for @daysLeftRenew.
  ///
  /// In en, this message translates to:
  /// **'{days, plural, =1{1 day left.} other{{days} days left.}} Contact the owner to renew.'**
  String daysLeftRenew(int days);

  /// No description provided for @readOnlyRenew.
  ///
  /// In en, this message translates to:
  /// **'Read-only. Contact the owner to renew.'**
  String get readOnlyRenew;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @statItems.
  ///
  /// In en, this message translates to:
  /// **'Items'**
  String get statItems;

  /// No description provided for @statLow.
  ///
  /// In en, this message translates to:
  /// **'Low'**
  String get statLow;

  /// No description provided for @statOut.
  ///
  /// In en, this message translates to:
  /// **'Out'**
  String get statOut;

  /// No description provided for @stockWorthAtCost.
  ///
  /// In en, this message translates to:
  /// **'Stock worth {value} at cost'**
  String stockWorthAtCost(String value);

  /// No description provided for @searchNameOrCode.
  ///
  /// In en, this message translates to:
  /// **'Search name or code'**
  String get searchNameOrCode;

  /// No description provided for @lowStock.
  ///
  /// In en, this message translates to:
  /// **'Low stock'**
  String get lowStock;

  /// No description provided for @outOfStock.
  ///
  /// In en, this message translates to:
  /// **'Out of stock'**
  String get outOfStock;

  /// No description provided for @hidden.
  ///
  /// In en, this message translates to:
  /// **'Hidden'**
  String get hidden;

  /// No description provided for @noItemsYet.
  ///
  /// In en, this message translates to:
  /// **'No items yet'**
  String get noItemsYet;

  /// No description provided for @noItemsYetBody.
  ///
  /// In en, this message translates to:
  /// **'Tap \"New item\" to add the first thing you sell.'**
  String get noItemsYetBody;

  /// No description provided for @nothingMatches.
  ///
  /// In en, this message translates to:
  /// **'Nothing matches'**
  String get nothingMatches;

  /// No description provided for @inTheApp.
  ///
  /// In en, this message translates to:
  /// **'In the app'**
  String get inTheApp;

  /// No description provided for @itemHidden.
  ///
  /// In en, this message translates to:
  /// **'{name} is hidden.'**
  String itemHidden(String name);

  /// No description provided for @itemBack.
  ///
  /// In en, this message translates to:
  /// **'{name} is back.'**
  String itemBack(String name);

  /// No description provided for @hideFromStockList.
  ///
  /// In en, this message translates to:
  /// **'Hide from stock list'**
  String get hideFromStockList;

  /// No description provided for @showInStockListAgain.
  ///
  /// In en, this message translates to:
  /// **'Show in stock list again'**
  String get showInStockListAgain;

  /// No description provided for @itemIsGone.
  ///
  /// In en, this message translates to:
  /// **'This item is gone'**
  String get itemIsGone;

  /// No description provided for @moveInShort.
  ///
  /// In en, this message translates to:
  /// **'In'**
  String get moveInShort;

  /// No description provided for @noMovesYet.
  ///
  /// In en, this message translates to:
  /// **'No stock movements yet.'**
  String get noMovesYet;

  /// No description provided for @sellingPrice.
  ///
  /// In en, this message translates to:
  /// **'Selling price'**
  String get sellingPrice;

  /// No description provided for @costPrice.
  ///
  /// In en, this message translates to:
  /// **'Cost price'**
  String get costPrice;

  /// No description provided for @profitEach.
  ///
  /// In en, this message translates to:
  /// **'Profit each'**
  String get profitEach;

  /// No description provided for @lowStockAt.
  ///
  /// In en, this message translates to:
  /// **'Low stock at'**
  String get lowStockAt;

  /// No description provided for @code.
  ///
  /// In en, this message translates to:
  /// **'Code'**
  String get code;

  /// No description provided for @errMustBeWholeNumber.
  ///
  /// In en, this message translates to:
  /// **'{field} must be a whole number.'**
  String errMustBeWholeNumber(String field);

  /// No description provided for @lowStockLevel.
  ///
  /// In en, this message translates to:
  /// **'Low stock level'**
  String get lowStockLevel;

  /// No description provided for @startingQuantity.
  ///
  /// In en, this message translates to:
  /// **'Starting quantity'**
  String get startingQuantity;

  /// No description provided for @editItem.
  ///
  /// In en, this message translates to:
  /// **'Edit item'**
  String get editItem;

  /// No description provided for @name.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get name;

  /// No description provided for @codeOptional.
  ///
  /// In en, this message translates to:
  /// **'Code (optional)'**
  String get codeOptional;

  /// No description provided for @codeHint.
  ///
  /// In en, this message translates to:
  /// **'SKU / barcode'**
  String get codeHint;

  /// No description provided for @unit.
  ///
  /// In en, this message translates to:
  /// **'Unit'**
  String get unit;

  /// No description provided for @unitHint.
  ///
  /// In en, this message translates to:
  /// **'pcs, box, kg'**
  String get unitHint;

  /// No description provided for @warnAtOrBelow.
  ///
  /// In en, this message translates to:
  /// **'Warn when at or below'**
  String get warnAtOrBelow;

  /// No description provided for @changeQuantityHelp.
  ///
  /// In en, this message translates to:
  /// **'To change the quantity, use In, Out or Count on the item page, so the history stays right.'**
  String get changeQuantityHelp;

  /// No description provided for @addItem.
  ///
  /// In en, this message translates to:
  /// **'Add item'**
  String get addItem;

  /// No description provided for @addAPhoto.
  ///
  /// In en, this message translates to:
  /// **'Add a photo'**
  String get addAPhoto;

  /// No description provided for @photo.
  ///
  /// In en, this message translates to:
  /// **'Photo'**
  String get photo;

  /// No description provided for @photoHelp.
  ///
  /// In en, this message translates to:
  /// **'Customers see it in the shop. It is made smaller before it is saved.'**
  String get photoHelp;

  /// No description provided for @camera.
  ///
  /// In en, this message translates to:
  /// **'Camera'**
  String get camera;

  /// No description provided for @gallery.
  ///
  /// In en, this message translates to:
  /// **'Gallery'**
  String get gallery;

  /// No description provided for @sellInApp.
  ///
  /// In en, this message translates to:
  /// **'Sell in the app'**
  String get sellInApp;

  /// No description provided for @sellInAppOn.
  ///
  /// In en, this message translates to:
  /// **'Customers see it in the shop, with your shop name. Its stock follows this item.'**
  String get sellInAppOn;

  /// No description provided for @sellInAppOff.
  ///
  /// In en, this message translates to:
  /// **'Turn on to show it to customers in the app.'**
  String get sellInAppOff;

  /// No description provided for @descriptionOptional.
  ///
  /// In en, this message translates to:
  /// **'Description (optional)'**
  String get descriptionOptional;

  /// No description provided for @descriptionHint.
  ///
  /// In en, this message translates to:
  /// **'Size, maker, condition, what is in the box'**
  String get descriptionHint;

  /// No description provided for @errQuantityWhole.
  ///
  /// In en, this message translates to:
  /// **'Quantity must be a whole number.'**
  String get errQuantityWhole;

  /// No description provided for @errPriceWhole.
  ///
  /// In en, this message translates to:
  /// **'Price must be a whole number of kyats.'**
  String get errPriceWhole;

  /// No description provided for @moveSaved.
  ///
  /// In en, this message translates to:
  /// **'{move} saved for {name}.'**
  String moveSaved(String move, String name);

  /// No description provided for @errEnterWholeNumber.
  ///
  /// In en, this message translates to:
  /// **'Enter a whole number.'**
  String get errEnterWholeNumber;

  /// No description provided for @moveInHelp.
  ///
  /// In en, this message translates to:
  /// **'New stock arrived.'**
  String get moveInHelp;

  /// No description provided for @moveOutHelp.
  ///
  /// In en, this message translates to:
  /// **'Sold or taken out.'**
  String get moveOutHelp;

  /// No description provided for @moveCountHelp.
  ///
  /// In en, this message translates to:
  /// **'You counted the shelf. Enter how many are really there.'**
  String get moveCountHelp;

  /// No description provided for @counted.
  ///
  /// In en, this message translates to:
  /// **'Counted'**
  String get counted;

  /// No description provided for @quantity.
  ///
  /// In en, this message translates to:
  /// **'Quantity'**
  String get quantity;

  /// No description provided for @costEach.
  ///
  /// In en, this message translates to:
  /// **'Cost each'**
  String get costEach;

  /// No description provided for @sellingPriceEach.
  ///
  /// In en, this message translates to:
  /// **'Selling price each'**
  String get sellingPriceEach;

  /// No description provided for @totalLine.
  ///
  /// In en, this message translates to:
  /// **'Total {amount}'**
  String totalLine(String amount);

  /// No description provided for @saveStockIn.
  ///
  /// In en, this message translates to:
  /// **'Save stock in'**
  String get saveStockIn;

  /// No description provided for @saveStockOut.
  ///
  /// In en, this message translates to:
  /// **'Save stock out'**
  String get saveStockOut;

  /// No description provided for @saveCount.
  ///
  /// In en, this message translates to:
  /// **'Save count'**
  String get saveCount;

  /// No description provided for @customerOptional.
  ///
  /// In en, this message translates to:
  /// **'Customer (optional)'**
  String get customerOptional;

  /// No description provided for @walkInCustomer.
  ///
  /// In en, this message translates to:
  /// **'Walk-in customer'**
  String get walkInCustomer;

  /// No description provided for @toDo.
  ///
  /// In en, this message translates to:
  /// **'To do'**
  String get toDo;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @noOrdersToHandle.
  ///
  /// In en, this message translates to:
  /// **'No orders to handle'**
  String get noOrdersToHandle;

  /// No description provided for @noFinishedOrders.
  ///
  /// In en, this message translates to:
  /// **'No finished orders yet'**
  String get noFinishedOrders;

  /// No description provided for @noOrdersToHandleBody.
  ///
  /// In en, this message translates to:
  /// **'When a customer orders something you sell in the app, it shows up here.'**
  String get noOrdersToHandleBody;

  /// No description provided for @noFinishedOrdersBody.
  ///
  /// In en, this message translates to:
  /// **'Shipped and cancelled orders are kept here.'**
  String get noFinishedOrdersBody;

  /// No description provided for @shopCancelOrderBody.
  ///
  /// In en, this message translates to:
  /// **'The customer sees it as cancelled. Stock you already took out stays out; record a Stock in to put it back.'**
  String get shopCancelOrderBody;

  /// No description provided for @keepIt.
  ///
  /// In en, this message translates to:
  /// **'Keep it'**
  String get keepIt;

  /// No description provided for @orderConfirmedDone.
  ///
  /// In en, this message translates to:
  /// **'Confirmed. The stock went out and is in History.'**
  String get orderConfirmedDone;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @markedOnItsWay.
  ///
  /// In en, this message translates to:
  /// **'Marked as on its way.'**
  String get markedOnItsWay;

  /// No description provided for @shipped.
  ///
  /// In en, this message translates to:
  /// **'Shipped'**
  String get shipped;

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// No description provided for @sales.
  ///
  /// In en, this message translates to:
  /// **'Sales'**
  String get sales;

  /// No description provided for @counts.
  ///
  /// In en, this message translates to:
  /// **'Counts'**
  String get counts;

  /// No description provided for @noMovementsYet.
  ///
  /// In en, this message translates to:
  /// **'No movements yet'**
  String get noMovementsYet;

  /// No description provided for @noMovementsYetBody.
  ///
  /// In en, this message translates to:
  /// **'Open an item and tap In, Out or Count.'**
  String get noMovementsYetBody;

  /// No description provided for @showingLatest.
  ///
  /// In en, this message translates to:
  /// **'Showing the latest {count}. Open an item to see all of its history.'**
  String showingLatest(int count);

  /// No description provided for @searchNameOrPhone.
  ///
  /// In en, this message translates to:
  /// **'Search name or phone'**
  String get searchNameOrPhone;

  /// No description provided for @noCustomersYet.
  ///
  /// In en, this message translates to:
  /// **'No customers yet'**
  String get noCustomersYet;

  /// No description provided for @noCustomersYetBody.
  ///
  /// In en, this message translates to:
  /// **'Add regulars here, then pick them when you record a stock out.'**
  String get noCustomersYetBody;

  /// No description provided for @deleteNameQuestion.
  ///
  /// In en, this message translates to:
  /// **'Delete {name}?'**
  String deleteNameQuestion(String name);

  /// No description provided for @deleteCustomerBody.
  ///
  /// In en, this message translates to:
  /// **'Past stock outs keep their name.'**
  String get deleteCustomerBody;

  /// No description provided for @addressOptional.
  ///
  /// In en, this message translates to:
  /// **'Address (optional)'**
  String get addressOptional;

  /// No description provided for @addCustomer.
  ///
  /// In en, this message translates to:
  /// **'Add customer'**
  String get addCustomer;

  /// No description provided for @recentPurchases.
  ///
  /// In en, this message translates to:
  /// **'Recent purchases'**
  String get recentPurchases;

  /// No description provided for @saving.
  ///
  /// In en, this message translates to:
  /// **'Saving…'**
  String get saving;

  /// No description provided for @shops.
  ///
  /// In en, this message translates to:
  /// **'Shops'**
  String get shops;

  /// No description provided for @searchShops.
  ///
  /// In en, this message translates to:
  /// **'Search name, email or phone'**
  String get searchShops;

  /// No description provided for @expiring.
  ///
  /// In en, this message translates to:
  /// **'Expiring'**
  String get expiring;

  /// No description provided for @noShopsHere.
  ///
  /// In en, this message translates to:
  /// **'No shops here'**
  String get noShopsHere;

  /// No description provided for @noShopsHereBody.
  ///
  /// In en, this message translates to:
  /// **'New shops appear when someone signs up in the app.'**
  String get noShopsHereBody;

  /// No description provided for @signedUpOn.
  ///
  /// In en, this message translates to:
  /// **'Signed up {date}'**
  String signedUpOn(String date);

  /// No description provided for @untilDaysLeft.
  ///
  /// In en, this message translates to:
  /// **'Until {date} · {days, plural, =1{1 day left} other{{days} days left}}'**
  String untilDaysLeft(String date, int days);

  /// No description provided for @shopWorksUntil.
  ///
  /// In en, this message translates to:
  /// **'Shop works until the end of'**
  String get shopWorksUntil;

  /// No description provided for @shopNowRunsUntil.
  ///
  /// In en, this message translates to:
  /// **'{shop} now runs until {date}.'**
  String shopNowRunsUntil(String shop, String date);

  /// No description provided for @stopShopQuestion.
  ///
  /// In en, this message translates to:
  /// **'Stop {shop} now?'**
  String stopShopQuestion(String shop);

  /// No description provided for @stopShopBody.
  ///
  /// In en, this message translates to:
  /// **'The shop becomes read-only straight away. Its data is kept, and renewing turns it back on.'**
  String get stopShopBody;

  /// No description provided for @stopNow.
  ///
  /// In en, this message translates to:
  /// **'Stop now'**
  String get stopNow;

  /// No description provided for @shopStopped.
  ///
  /// In en, this message translates to:
  /// **'{shop} has been stopped.'**
  String shopStopped(String shop);

  /// No description provided for @waitingForYou.
  ///
  /// In en, this message translates to:
  /// **'Waiting for you to turn it on.'**
  String get waitingForYou;

  /// No description provided for @runsUntil.
  ///
  /// In en, this message translates to:
  /// **'Runs until {date}'**
  String runsUntil(String date);

  /// No description provided for @addTimeFrom.
  ///
  /// In en, this message translates to:
  /// **'Add time from {date}'**
  String addTimeFrom(String date);

  /// No description provided for @addTimeFromToday.
  ///
  /// In en, this message translates to:
  /// **'Add time from today'**
  String get addTimeFromToday;

  /// No description provided for @addMonths.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{+ 1 month} other{+ {count} months}}'**
  String addMonths(int count);

  /// No description provided for @addOneYear.
  ///
  /// In en, this message translates to:
  /// **'+ 1 year'**
  String get addOneYear;

  /// No description provided for @pickEndDate.
  ///
  /// In en, this message translates to:
  /// **'Pick an end date'**
  String get pickEndDate;

  /// No description provided for @stopThisShopNow.
  ///
  /// In en, this message translates to:
  /// **'Stop this shop now'**
  String get stopThisShopNow;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading'**
  String get loading;

  /// No description provided for @errDeliveryFeeTooLarge.
  ///
  /// In en, this message translates to:
  /// **'That delivery fee is too large.'**
  String get errDeliveryFeeTooLarge;

  /// No description provided for @errTooManyPaymentMethods.
  ///
  /// In en, this message translates to:
  /// **'A shop can list at most {max} ways to pay.'**
  String errTooManyPaymentMethods(int max);

  /// No description provided for @errPaymentMethodIncomplete.
  ///
  /// In en, this message translates to:
  /// **'Fill in the account name and number for each way to pay, or remove it.'**
  String get errPaymentMethodIncomplete;

  /// No description provided for @errPaymentMethodTooLong.
  ///
  /// In en, this message translates to:
  /// **'That account name or number is too long.'**
  String get errPaymentMethodTooLong;

  /// No description provided for @paymentBank.
  ///
  /// In en, this message translates to:
  /// **'Bank account'**
  String get paymentBank;

  /// No description provided for @shopSettings.
  ///
  /// In en, this message translates to:
  /// **'Shop settings'**
  String get shopSettings;

  /// No description provided for @shopPhoneHelp.
  ///
  /// In en, this message translates to:
  /// **'Customers call and Viber you on this number.'**
  String get shopPhoneHelp;

  /// No description provided for @deliveryFee.
  ///
  /// In en, this message translates to:
  /// **'Delivery fee'**
  String get deliveryFee;

  /// No description provided for @deliveryFeeHelp.
  ///
  /// In en, this message translates to:
  /// **'Added to each delivery order. Leave empty for free delivery.'**
  String get deliveryFeeHelp;

  /// No description provided for @waysToPay.
  ///
  /// In en, this message translates to:
  /// **'Ways to pay'**
  String get waysToPay;

  /// No description provided for @waysToPayHelp.
  ///
  /// In en, this message translates to:
  /// **'Customers see these on their order, with a copy button.'**
  String get waysToPayHelp;

  /// No description provided for @addWayToPay.
  ///
  /// In en, this message translates to:
  /// **'Add a way to pay'**
  String get addWayToPay;

  /// No description provided for @accountName.
  ///
  /// In en, this message translates to:
  /// **'Account name'**
  String get accountName;

  /// No description provided for @walletPhone.
  ///
  /// In en, this message translates to:
  /// **'Wallet phone number'**
  String get walletPhone;

  /// No description provided for @bankAccountNumber.
  ///
  /// In en, this message translates to:
  /// **'Bank and account number'**
  String get bankAccountNumber;

  /// No description provided for @bankAccountNumberHint.
  ///
  /// In en, this message translates to:
  /// **'KBZ Bank 0123 4567 8901'**
  String get bankAccountNumberHint;

  /// No description provided for @settingsSaved.
  ///
  /// In en, this message translates to:
  /// **'Settings saved.'**
  String get settingsSaved;

  /// No description provided for @setUpPayment.
  ///
  /// In en, this message translates to:
  /// **'Set up delivery and payment'**
  String get setUpPayment;

  /// No description provided for @setUpPaymentBody.
  ///
  /// In en, this message translates to:
  /// **'Add your phone, delivery fee and how customers pay you.'**
  String get setUpPaymentBody;

  /// No description provided for @deliveryAndPayment.
  ///
  /// In en, this message translates to:
  /// **'Delivery and payment'**
  String get deliveryAndPayment;

  /// No description provided for @freeDelivery.
  ///
  /// In en, this message translates to:
  /// **'Free delivery'**
  String get freeDelivery;

  /// No description provided for @deliveryFeeLine.
  ///
  /// In en, this message translates to:
  /// **'Delivery {fee}'**
  String deliveryFeeLine(String fee);

  /// No description provided for @noWaysToPay.
  ///
  /// In en, this message translates to:
  /// **'No ways to pay yet'**
  String get noWaysToPay;

  /// No description provided for @call.
  ///
  /// In en, this message translates to:
  /// **'Call'**
  String get call;

  /// No description provided for @cannotCall.
  ///
  /// In en, this message translates to:
  /// **'This phone can\'t make calls. The number is {phone}.'**
  String cannotCall(String phone);

  /// No description provided for @viberNotInstalled.
  ///
  /// In en, this message translates to:
  /// **'Viber isn\'t on this phone.'**
  String get viberNotInstalled;

  /// No description provided for @contactTheShop.
  ///
  /// In en, this message translates to:
  /// **'Contact the shop'**
  String get contactTheShop;

  /// No description provided for @total.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get total;

  /// No description provided for @pickupNoFee.
  ///
  /// In en, this message translates to:
  /// **'None, you pick up'**
  String get pickupNoFee;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {


  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en': return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}
