import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

/// The translations for Burmese (`my`).
class AppLocalizationsMy extends AppLocalizations {
  AppLocalizationsMy([String locale = 'my']) : super(locale);

  @override
  String get errQuantityNegative => 'အရေအတွက်က အနုတ် မဖြစ်ရပါ။';

  @override
  String get errQuantityAtLeastOne => 'အရေအတွက် အနည်းဆုံး ၁ ထည့်ပါ။';

  @override
  String errOnlyInStock(int count) {
    return 'စတော့ထဲမှာ $count ခုပဲ ကျန်ပါတယ်။';
  }

  @override
  String get errQuantityTooLarge => 'အရေအတွက် များလွန်းပါတယ်။';

  @override
  String get errCartEmpty => 'ဈေးခြင်းထဲမှာ ဘာမှ မရှိသေးပါ။';

  @override
  String errTooManyOrderLines(int max) {
    return 'အော်ဒါတစ်ခုမှာ ပစ္စည်း $max မျိုးအထိပဲ ထည့်လို့ရပါတယ်။';
  }

  @override
  String get errPhoneFormat => 'ဖုန်းနံပါတ်ကို 09xxxxxxxxx ပုံစံနဲ့ ထည့်ပါ။';

  @override
  String get errAddressEmpty => 'ပို့ရမယ့် လိပ်စာ ထည့်ပါ။';

  @override
  String errProductUnavailable(String name) {
    return '$name ကို မရနိုင်တော့ပါ။';
  }

  @override
  String errOnlyLeftOf(int count, String name) {
    return '$name က $count ခုပဲ ကျန်ပါတယ်။';
  }

  @override
  String get errShopNameEmpty => 'ဆိုင်နာမည် ထည့်ပါ။';

  @override
  String errShopNameTooLong(int max) {
    return 'ဆိုင်နာမည်ကို စာလုံး $max လုံးအောက် ထားပါ။';
  }

  @override
  String get errPhotoTooBig => 'ပုံကို ချုံ့ပြီးတာတောင် ကြီးနေသေးပါတယ်။ တခြားပုံ စမ်းကြည့်ပါ။';

  @override
  String get errItemNameEmpty => 'ပစ္စည်းနာမည် ထည့်ပါ။';

  @override
  String errNameTooLong(int max) {
    return 'နာမည်ကို စာလုံး $max လုံးအောက် ထားပါ။';
  }

  @override
  String errCodeTooLong(int max) {
    return 'ကုဒ်ကို စာလုံး $max လုံးအောက် ထားပါ။';
  }

  @override
  String errUnitTooLong(int max) {
    return 'ယူနစ်ကို စာလုံး $max လုံးအောက် ထားပါ။';
  }

  @override
  String get errPriceTooLarge => 'ဈေးနှုန်း များလွန်းပါတယ်။';

  @override
  String get errLowStockTooLarge => 'စတော့နည်း သတိပေးအဆင့် များလွန်းပါတယ်။';

  @override
  String get errPickCategory => 'စာရင်းထဲက အမျိုးအစား တစ်ခု ရွေးပါ။';

  @override
  String errAnimeTooLong(int max) {
    return 'Anime နာမည်ကို စာလုံး $max လုံးအောက် ထားပါ။';
  }

  @override
  String errTextTooLong(int max) {
    return 'စာလုံး $max လုံးအောက် ထားပါ။';
  }

  @override
  String get errPhotoAddressUnknown => 'ဒီပုံလိပ်စာကို app က မသိပါ။';

  @override
  String get errListedNeedsPrice => 'App ထဲမှာ ရောင်းဖို့ ရောင်းဈေး သတ်မှတ်ပါ။';

  @override
  String get errShopLoading => 'ဆိုင်ကို ဖွင့်နေတုန်းပါ။';

  @override
  String get errItemGone => 'ဒီပစ္စည်း မရှိတော့ပါ။';

  @override
  String errNoteTooLong(int max) {
    return 'မှတ်ချက်ကို စာလုံး $max လုံးအောက် ထားပါ။';
  }

  @override
  String get errNameEmpty => 'နာမည် ထည့်ပါ။';

  @override
  String get errNotAllowed => 'ခွင့်မပြုပါ။ ဆိုင်သက်တမ်း ကုန်သွားရင် သက်တမ်းတိုးဖို့ ပိုင်ရှင်ကို ဆက်သွယ်ပါ။';

  @override
  String get errOffline => 'အင်တာနက် မရှိပါ။ အင်တာနက် ရတော့မှ ပြန်စမ်းပါ။';

  @override
  String get moveIn => 'စတော့အဝင်';

  @override
  String get moveOut => 'စတော့အထွက်';

  @override
  String get moveCount => 'ရေတွက်';

  @override
  String get sortFeatured => 'အကြံပြု';

  @override
  String get sortPriceLow => 'ဈေးအနည်းဆုံး';

  @override
  String get sortPriceHigh => 'ဈေးအများဆုံး';

  @override
  String get sortName => 'နာမည် A မှ Z';

  @override
  String get deliveryMethodDelivery => 'အိမ်အရောက်ပို့';

  @override
  String get deliveryMethodPickup => 'ဆိုင်မှာ လာယူ';

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
  String get categoryOther => 'အခြား';

  @override
  String get cancel => 'မလုပ်တော့ပါ';

  @override
  String get signIn => 'အကောင့်ဝင်ရန်';

  @override
  String get signOut => 'အကောင့်ထွက်ရန်';

  @override
  String get signOutQuestion => 'အကောင့်က ထွက်မလား။';

  @override
  String get couldNotLoad => 'ဖွင့်လို့ မရပါ';

  @override
  String get shopStatusWaiting => 'စောင့်ဆိုင်းဆဲ';

  @override
  String get shopStatusActive => 'ဖွင့်ထား';

  @override
  String get shopStatusExpired => 'သက်တမ်းကုန်';

  @override
  String shopDaysLeftShort(int days) {
    return '$days ရက် ကျန်';
  }

  @override
  String shopExpiredBanner(String date) {
    return 'သင့်ဆိုင် သက်တမ်း $date မှာ ကုန်သွားပါပြီ။ အားလုံးကို ကြည့်လို့ရပေမယ့် ပြင်လို့ မရပါ။ သက်တမ်းတိုးဖို့ ပိုင်ရှင်ကို ဆက်သွယ်ပါ။';
  }

  @override
  String shopExpiresBanner(int days, String date) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days ရက်',
    );
    return 'သင့်ဆိုင် သက်တမ်း $_temp0 နေရင် ကုန်ပါမယ် ($date)။ သက်တမ်းတိုးဖို့ ပိုင်ရှင်ကို ဆက်သွယ်ပါ။';
  }

  @override
  String get typeEmailFirst => 'အီးမေးလ် အရင်ရိုက်ပြီး ဒါကို ထပ်နှိပ်ပါ။';

  @override
  String passwordResetSent(String email) {
    return 'စကားဝှက် ပြန်သတ်မှတ်ရန် အီးမေးလ်ကို $email သို့ ပို့ပြီးပါပြီ။';
  }

  @override
  String get createAnAccount => 'အကောင့်အသစ် ဖွင့်ရန်';

  @override
  String get welcomeBack => 'ပြန်လာတာ ကြိုဆိုပါတယ်';

  @override
  String get signUpSubtitle => 'ဝယ်ဖို့၊ အော်ဒါစောင့်ကြည့်ဖို့နဲ့ ဆိုင်ဖွင့်ဖို့ အကောင့်တစ်ခုတည်း။';

  @override
  String get signInSubtitle => 'ဝယ်ယူဖို့နဲ့ အော်ဒါတွေ ကြည့်ဖို့ အကောင့်ဝင်ပါ။';

  @override
  String get email => 'အီးမေးလ်';

  @override
  String get password => 'စကားဝှက်';

  @override
  String get errEmailEmpty => 'အီးမေးလ် ထည့်ပါ။';

  @override
  String get errPasswordEmpty => 'စကားဝှက် ထည့်ပါ။';

  @override
  String get hidePassword => 'စကားဝှက် ဖျောက်ရန်';

  @override
  String get showPassword => 'စကားဝှက် ပြရန်';

  @override
  String get createAccount => 'အကောင့်ဖွင့်ရန်';

  @override
  String get forgotPassword => 'စကားဝှက် မေ့သွားလား။';

  @override
  String get deleteMyAccount => 'ကျွန်ုပ်၏ အကောင့်ကို ဖျက်ရန်';

  @override
  String get deleteMyAccountQuestion => 'အကောင့်ကို ဖျက်မလား။';

  @override
  String get closeShopBody => 'သင့်အကောင့်မှာ ဆိုင်နဲ့ စတော့မှတ်တမ်းတွေ ရှိလို့ ကျွန်ုပ်တို့ကပဲ ပိတ်ပေးပါတယ်။ ဆိုင်ပိတ်ပြီး အကောင့်ဖျက်ဖို့ ဆက်သွယ်ပါ။';

  @override
  String closeShopBodyContact(String contact) {
    return 'သင့်အကောင့်မှာ ဆိုင်နဲ့ စတော့မှတ်တမ်းတွေ ရှိလို့ ကျွန်ုပ်တို့ကပဲ ပိတ်ပေးပါတယ်။ ဆိုင်ပိတ်ပြီး အကောင့်ဖျက်ဖို့ ဆက်သွယ်ပါ- $contact';
  }

  @override
  String get ok => 'အိုကေ';

  @override
  String get accountDeleted => 'သင့်အကောင့်ကို ဖျက်ပြီးပါပြီ။';

  @override
  String get wrongPassword => 'စကားဝှက် မှားနေပါတယ်။';

  @override
  String get deleteAccountBody => 'ပြန်ယူလို့ မရပါ။ စောင့်ဆိုင်းဆဲ အော်ဒါတွေ ပယ်ဖျက်ပါမယ်။ အရင်အော်ဒါတွေကို ဖုန်းနံပါတ်နဲ့ လိပ်စာ မပါဘဲ ဆိုင်မှာ ဆက်ထားပါမယ်။';

  @override
  String get yourPassword => 'သင့်စကားဝှက်';

  @override
  String get delete => 'ဖျက်ရန်';

  @override
  String get oneLastStep => 'နောက်ဆုံး တစ်ဆင့်';

  @override
  String get nameYourShop => 'ဆိုင်နာမည် ပေးပါ';

  @override
  String get nameYourShopHelp => 'နောက်မှ ပြင်လို့ရပါတယ်။ ပိုင်ရှင်က ခွင့်ပြုတာနဲ့ ဆိုင်ဖွင့်ပါမယ်။';

  @override
  String get shopName => 'ဆိုင်နာမည်';

  @override
  String get phoneOptional => 'ဖုန်း (မထည့်လည်းရ)';

  @override
  String get createShop => 'ဆိုင်ဖွင့်ရန်';

  @override
  String shopWaitingForApproval(String shop) {
    return '$shop ကို ခွင့်ပြုချက် စောင့်နေပါတယ်';
  }

  @override
  String shopWaitingBody(String appName) {
    return '$appName ပိုင်ရှင်က သင့်ဆိုင်ကို ဖွင့်ပေးပါမယ်။ ဖွင့်ပေးတာနဲ့ ဒီစာမျက်နှာက ဆိုင်ကို အလိုလို ဖွင့်ပေးပါမယ်။';
  }

  @override
  String contactLine(String contact) {
    return 'ဆက်သွယ်ရန်- $contact';
  }

  @override
  String accountLine(String email) {
    return 'အကောင့်- $email';
  }

  @override
  String get tabShop => 'ဆိုင်';

  @override
  String get tabCart => 'ဈေးခြင်း';

  @override
  String get tabOrders => 'အော်ဒါ';

  @override
  String get tabAccount => 'အကောင့်';

  @override
  String get myOrders => 'ကျွန်ုပ်၏ အော်ဒါများ';

  @override
  String get signInToSeeOrders => 'အော်ဒါတွေ ကြည့်ဖို့ အကောင့်ဝင်ပါ';

  @override
  String get signInToSeeOrdersBody => 'သင်တင်ထားတဲ့ အော်ဒါတွေကို ဆိုင်က ဘာလုပ်နေလဲဆိုတာနဲ့အတူ ဒီမှာ ပြပါမယ်။';

  @override
  String get goToAccount => 'အကောင့်သို့ သွားရန်';

  @override
  String get browseFigures => 'Figure တွေ ကြည့်ရန်';

  @override
  String get signedInAs => 'ဝင်ထားသော အကောင့်';

  @override
  String get signedIn => 'အကောင့်ဝင်ထားပါတယ်';

  @override
  String get openAShop => 'ဆိုင်ဖွင့်ရန်';

  @override
  String get openAShopSubtitle => 'ကိုယ့်စတော့ကို ရောင်းပြီး စီမံပါ';

  @override
  String get browsingAsGuest => 'ဧည့်သည်အဖြစ် ကြည့်နေပါတယ်';

  @override
  String get guestIntro => 'စိတ်ကြိုက် ကြည့်ပါ။ အကောင့်ရှိရင်-';

  @override
  String get benefitCheckout => 'နှိပ်ရုံနဲ့ ဝယ်လို့ရ';

  @override
  String get benefitCheckoutLine => 'ဖုန်းနဲ့ လိပ်စာကို မှတ်ထားပေးပါတယ်။';

  @override
  String get benefitFollow => 'အော်ဒါတိုင်း စောင့်ကြည့်လို့ရ';

  @override
  String get benefitFollowLine => 'ဆိုင်က အတည်ပြုတာ၊ ပို့တာကို သိရပါမယ်။';

  @override
  String get benefitShop => 'ကိုယ်ပိုင်ဆိုင် ဖွင့်လို့ရ';

  @override
  String get benefitShopLine => 'စတော့စီမံပြီး ဒီမှာ figure တွေ ရောင်းပါ။';

  @override
  String get keepBrowsing => 'ဆက်ကြည့်ရန်';

  @override
  String get guestSubtitle => 'ဝယ်ဖို့နဲ့ အော်ဒါစောင့်ကြည့်ဖို့ အကောင့်ဝင်ပါ။';

  @override
  String get withAnAccount => 'အကောင့်ရှိရင်';

  @override
  String get inStockNow => 'အခု ရနိုင်တာတွေ';

  @override
  String ordersPlaced(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'အော်ဒါ $count ခု တင်ပြီးပါပြီ။ ဆိုင်တစ်ဆိုင်ချင်းစီက ကိုယ့်အော်ဒါကို အတည်ပြုပါမယ်။',
      one: 'အော်ဒါ တင်ပြီးပါပြီ။ ဆိုင်က မကြာခင် အတည်ပြုပေးပါမယ်။',
    );
    return '$_temp0';
  }

  @override
  String couldNotPlaceOrder(String error) {
    return 'အော်ဒါ တင်လို့ မရပါ- $error';
  }

  @override
  String get checkout => 'ငွေရှင်းရန်';

  @override
  String get phone => 'ဖုန်း';

  @override
  String get deliveryAddress => 'ပို့ရမယ့် လိပ်စာ';

  @override
  String get deliveryAddressHint => 'မြို့နယ်၊ လမ်း၊ အမှတ်အသား';

  @override
  String get noteOptional => 'မှတ်ချက် (မထည့်လည်းရ)';

  @override
  String get estimatedTotal => 'ခန့်မှန်း စုစုပေါင်း';

  @override
  String get payShopDirectly => 'အော်ဒါတင်ပြီးမှ ဆိုင်ကို ငွေပေးပါ- ပေးနည်းက အော်ဒါထဲမှာ ပါပါတယ်။ ပစ္စည်းရောက်မှ ငွေချေလည်း ရပါတယ်။';

  @override
  String get placeOrder => 'အော်ဒါတင်ရန်';

  @override
  String get cartEmpty => 'ဈေးခြင်းထဲမှာ ဘာမှ မရှိသေးပါ';

  @override
  String get cartEmptyBody => 'ထည့်လိုက်တဲ့ figure တွေ ဒီမှာ ပေါ်ပါမယ်။';

  @override
  String itemCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ခု',
    );
    return '$_temp0';
  }

  @override
  String get continueShopping => 'ဆက်ဝယ်ရန်';

  @override
  String get orderSummary => 'အော်ဒါ အနှစ်ချုပ်';

  @override
  String figuresCount(int count) {
    return 'Figure ($count)';
  }

  @override
  String get setByShop => 'ငွေရှင်းချိန်မှာ ပေါင်းပါမယ်';

  @override
  String cartManyShops(int shops) {
    return 'ဒါတွေက ဆိုင် $shops ဆိုင်က လာတာမို့ ဆိုင်တစ်ဆိုင်ချင်းစီအတွက် အော်ဒါတစ်ခုစီ ရပါမယ်။ ပို့ခကိုလည်း ဆိုင်တစ်ဆိုင်ချင်း သတ်မှတ်ပါတယ်။';
  }

  @override
  String get cartOneShop => 'ငွေရှင်းချိန်မှာ အိမ်အရောက်ပို့ ဒါမှမဟုတ် ဆိုင်မှာ လာယူ ရွေးပါ။';

  @override
  String priceEach(String price) {
    return 'တစ်ခုကို $price';
  }

  @override
  String get remove => 'ဖယ်ရန်';

  @override
  String get decrease => 'လျှော့ရန်';

  @override
  String get increase => 'တိုးရန်';

  @override
  String get noOrdersYet => 'အော်ဒါ မရှိသေးပါ';

  @override
  String get noOrdersYetBody => 'ဝယ်လိုက်တာနဲ့ အော်ဒါ ဒီမှာ ပေါ်ပါမယ်။';

  @override
  String get couldNotLoadOrders => 'အော်ဒါတွေကို ဖွင့်လို့ မရပါ';

  @override
  String get statusWaitingForShop => 'ဆိုင်ကို စောင့်နေ';

  @override
  String get statusConfirmed => 'အတည်ပြုပြီး';

  @override
  String get statusPickedUp => 'လာယူပြီး';

  @override
  String get statusOnItsWay => 'ပို့နေပြီ';

  @override
  String get statusCancelled => 'ပယ်ဖျက်ပြီး';

  @override
  String get cancelOrderQuestion => 'ဒီအော်ဒါကို ပယ်ဖျက်မလား။';

  @override
  String get keepOrder => 'အော်ဒါ ဆက်ထားရန်';

  @override
  String get cancelOrder => 'အော်ဒါ ပယ်ဖျက်ရန်';

  @override
  String get orderCancelled => 'အော်ဒါ ပယ်ဖျက်ပြီးပါပြီ။';

  @override
  String couldNotCancelOrder(String error) {
    return 'ဒီအော်ဒါကို ပယ်ဖျက်လို့ မရပါ- $error';
  }

  @override
  String noteLine(String note) {
    return 'မှတ်ချက်- $note';
  }

  @override
  String get figureGone => 'ဒီ figure ကို မရနိုင်တော့ပါ';

  @override
  String onlyLeft(int count) {
    return '$count ခုပဲ ကျန်';
  }

  @override
  String inStockCount(int count) {
    return 'စတော့ $count ခု';
  }

  @override
  String get soldOut => 'ကုန်သွားပြီ';

  @override
  String moreFrom(String anime) {
    return '$anime မှ နောက်ထပ်';
  }

  @override
  String moreOfCategory(String category) {
    return 'နောက်ထပ်- $category';
  }

  @override
  String get seeEverythingFromShop => 'ဒီဆိုင်က အားလုံး ကြည့်ရန်';

  @override
  String inYourCart(int count) {
    return 'ဈေးခြင်းထဲမှာ $count ခု';
  }

  @override
  String get addToCart => 'ဈေးခြင်းထဲ ထည့်ရန်';

  @override
  String addedToCart(String name) {
    return '$name ကို ထည့်ပြီးပါပြီ';
  }

  @override
  String get viewCart => 'ဈေးခြင်း ကြည့်ရန်';

  @override
  String get noFiguresYet => 'Figure မရှိသေးပါ';

  @override
  String get noFiguresYetBody => 'ဆိုင်တွေ ထည့်တာနဲ့ figure အသစ်တွေ ဒီမှာ ပေါ်ပါမယ်။';

  @override
  String figuresShownOf(int shown, int total) {
    return 'Figure $total ခုထဲက $shown ခု';
  }

  @override
  String figuresCountPlain(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Figure $count ခု',
    );
    return '$_temp0';
  }

  @override
  String get clearAll => 'အားလုံး ရှင်းရန်';

  @override
  String get noFiguresMatch => 'ကိုက်ညီတဲ့ figure မရှိပါ';

  @override
  String get noFiguresMatchBody => 'တခြားစာလုံး ရှာကြည့်ပါ၊ ဒါမှမဟုတ် filter လျှော့ပါ။';

  @override
  String get showAllFigures => 'Figure အားလုံး ပြရန်';

  @override
  String get couldNotLoadFigures => 'Figure တွေကို ဖွင့်လို့ မရပါ';

  @override
  String priceFrom(String price) {
    return '$price မှ';
  }

  @override
  String priceUpTo(String price) {
    return '$price အထိ';
  }

  @override
  String get anyPrice => 'ဈေးမရွေး';

  @override
  String get searchHint => 'Figure ဒါမှမဟုတ် anime ရှာရန်';

  @override
  String get clearSearch => 'ရှာထားတာ ရှင်းရန်';

  @override
  String get filters => 'Filter များ';

  @override
  String get all => 'အားလုံး';

  @override
  String get inStock => 'ရနိုင်';

  @override
  String get sortAndFilter => 'စီရန်နဲ့ Filter';

  @override
  String get reset => 'ပြန်စရန်';

  @override
  String get sortBy => 'စီရန်';

  @override
  String get inStockOnly => 'ရနိုင်တာပဲ';

  @override
  String get inStockOnlyHelp => 'ကုန်သွားတဲ့ figure တွေကို ဖျောက်ပါ';

  @override
  String get price => 'ဈေးနှုန်း';

  @override
  String get min => 'အနည်းဆုံး';

  @override
  String get max => 'အများဆုံး';

  @override
  String get minMoreThanMax => 'အနည်းဆုံးက အများဆုံးထက် များနေပါတယ်။';

  @override
  String priceUnder(String amount) {
    return '$amount အောက်';
  }

  @override
  String priceOver(String amount) {
    return '$amount အထက်';
  }

  @override
  String get category => 'အမျိုးအစား';

  @override
  String get anime => 'Anime';

  @override
  String get checkPriceRange => 'ဈေးနှုန်း အပိုင်းအခြားကို စစ်ပါ';

  @override
  String showFigures(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Figure $count ခု ပြရန်',
    );
    return '$_temp0';
  }

  @override
  String get newItem => 'ပစ္စည်းအသစ်';

  @override
  String get newCustomer => 'ဖောက်သည်အသစ်';

  @override
  String get tabStock => 'စတော့';

  @override
  String get tabHistory => 'မှတ်တမ်း';

  @override
  String get tabCustomers => 'ဖောက်သည်';

  @override
  String get shopReadOnly => 'ပိုင်ရှင်က သက်တမ်းတိုးပေးတဲ့အထိ သင့်ဆိုင်ကို ကြည့်ရုံပဲ ရပါမယ်။';

  @override
  String get edit => 'ပြင်ရန်';

  @override
  String activeUntil(String date) {
    return '$date အထိ ဖွင့်ထား';
  }

  @override
  String expiredOn(String date) {
    return '$date မှာ သက်တမ်းကုန်';
  }

  @override
  String daysLeftRenew(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days ရက် ကျန်ပါတယ်။',
    );
    return '$_temp0 သက်တမ်းတိုးဖို့ ပိုင်ရှင်ကို ဆက်သွယ်ပါ။';
  }

  @override
  String get readOnlyRenew => 'ကြည့်ရုံပဲ ရပါတယ်။ သက်တမ်းတိုးဖို့ ပိုင်ရှင်ကို ဆက်သွယ်ပါ။';

  @override
  String get save => 'သိမ်းရန်';

  @override
  String get statItems => 'ပစ္စည်း';

  @override
  String get statLow => 'နည်းနေ';

  @override
  String get statOut => 'ကုန်';

  @override
  String stockWorthAtCost(String value) {
    return 'အရင်းဈေးနဲ့ စတော့တန်ဖိုး $value';
  }

  @override
  String get searchNameOrCode => 'နာမည် ဒါမှမဟုတ် ကုဒ် ရှာရန်';

  @override
  String get lowStock => 'စတော့နည်း';

  @override
  String get outOfStock => 'စတော့ကုန်';

  @override
  String get hidden => 'ဖျောက်ထား';

  @override
  String get noItemsYet => 'ပစ္စည်း မရှိသေးပါ';

  @override
  String get noItemsYetBody => 'ရောင်းမယ့် ပထမဆုံးပစ္စည်း ထည့်ဖို့ \"ပစ္စည်းအသစ်\" ကို နှိပ်ပါ။';

  @override
  String get nothingMatches => 'ကိုက်ညီတာ မရှိပါ';

  @override
  String get inTheApp => 'App ထဲမှာ';

  @override
  String itemHidden(String name) {
    return '$name ကို ဖျောက်ထားပါပြီ။';
  }

  @override
  String itemBack(String name) {
    return '$name ပြန်ပေါ်လာပါပြီ။';
  }

  @override
  String get hideFromStockList => 'စတော့စာရင်းက ဖျောက်ရန်';

  @override
  String get showInStockListAgain => 'စတော့စာရင်းမှာ ပြန်ပြရန်';

  @override
  String get itemIsGone => 'ဒီပစ္စည်း မရှိတော့ပါ';

  @override
  String get moveInShort => 'အဝင်';

  @override
  String get noMovesYet => 'စတော့ အဝင်အထွက် မရှိသေးပါ။';

  @override
  String get sellingPrice => 'ရောင်းဈေး';

  @override
  String get costPrice => 'အရင်းဈေး';

  @override
  String get profitEach => 'တစ်ခုချင်း အမြတ်';

  @override
  String get lowStockAt => 'စတော့နည်း သတိပေးအဆင့်';

  @override
  String get code => 'ကုဒ်';

  @override
  String errMustBeWholeNumber(String field) {
    return '$field က ကိန်းပြည့် ဖြစ်ရပါမယ်။';
  }

  @override
  String get lowStockLevel => 'စတော့နည်း အဆင့်';

  @override
  String get startingQuantity => 'စစချင်း အရေအတွက်';

  @override
  String get editItem => 'ပစ္စည်း ပြင်ရန်';

  @override
  String get name => 'နာမည်';

  @override
  String get codeOptional => 'ကုဒ် (မထည့်လည်းရ)';

  @override
  String get codeHint => 'SKU / ဘားကုဒ်';

  @override
  String get unit => 'ယူနစ်';

  @override
  String get unitHint => 'ခု၊ ဘူး၊ ကီလို';

  @override
  String get warnAtOrBelow => 'ဒီအရေအတွက် ဒါမှမဟုတ် အောက်ရောက်ရင် သတိပေး';

  @override
  String get changeQuantityHelp => 'မှတ်တမ်း မှန်နေစေဖို့ အရေအတွက်ကို ပစ္စည်းစာမျက်နှာက အဝင်၊ အထွက် ဒါမှမဟုတ် ရေတွက် နဲ့ ပြောင်းပါ။';

  @override
  String get addItem => 'ပစ္စည်း ထည့်ရန်';

  @override
  String get addAPhoto => 'ပုံထည့်ရန်';

  @override
  String get photo => 'ပုံ';

  @override
  String get photoHelp => 'ဖောက်သည်တွေ ဆိုင်ထဲမှာ မြင်ရပါမယ်။ မသိမ်းခင် ပုံကို ချုံ့ပေးပါတယ်။';

  @override
  String get camera => 'ကင်မရာ';

  @override
  String get gallery => 'ဓာတ်ပုံများ';

  @override
  String get sellInApp => 'App ထဲမှာ ရောင်းရန်';

  @override
  String get sellInAppOn => 'ဖောက်သည်တွေက သင့်ဆိုင်နာမည်နဲ့အတူ ဆိုင်ထဲမှာ မြင်ရပါမယ်။ စတော့က ဒီပစ္စည်းအတိုင်း လိုက်ပြောင်းပါတယ်။';

  @override
  String get sellInAppOff => 'App ထဲက ဖောက်သည်တွေကို ပြဖို့ ဖွင့်ပါ။';

  @override
  String get descriptionOptional => 'အသေးစိတ် (မထည့်လည်းရ)';

  @override
  String get descriptionHint => 'အရွယ်အစား၊ ထုတ်လုပ်သူ၊ အခြေအနေ၊ ဘူးထဲမှာ ဘာပါလဲ';

  @override
  String get errQuantityWhole => 'အရေအတွက်က ကိန်းပြည့် ဖြစ်ရပါမယ်။';

  @override
  String get errPriceWhole => 'ဈေးနှုန်းက ကျပ် ကိန်းပြည့် ဖြစ်ရပါမယ်။';

  @override
  String moveSaved(String move, String name) {
    return '$name အတွက် $move သိမ်းပြီးပါပြီ။';
  }

  @override
  String get errEnterWholeNumber => 'ကိန်းပြည့် ထည့်ပါ။';

  @override
  String get moveInHelp => 'စတော့အသစ် ရောက်လာပါပြီ။';

  @override
  String get moveOutHelp => 'ရောင်းလိုက်တာ ဒါမှမဟုတ် ထုတ်လိုက်တာ။';

  @override
  String get moveCountHelp => 'စင်ပေါ်က ပစ္စည်းကို ရေတွက်ထားတယ်။ တကယ်ရှိတဲ့ အရေအတွက် ထည့်ပါ။';

  @override
  String get counted => 'ရေတွက်ရတာ';

  @override
  String get quantity => 'အရေအတွက်';

  @override
  String get costEach => 'တစ်ခုချင်း အရင်း';

  @override
  String get sellingPriceEach => 'တစ်ခုချင်း ရောင်းဈေး';

  @override
  String totalLine(String amount) {
    return 'စုစုပေါင်း $amount';
  }

  @override
  String get saveStockIn => 'စတော့အဝင် သိမ်းရန်';

  @override
  String get saveStockOut => 'စတော့အထွက် သိမ်းရန်';

  @override
  String get saveCount => 'ရေတွက်ချက် သိမ်းရန်';

  @override
  String get customerOptional => 'ဖောက်သည် (မထည့်လည်းရ)';

  @override
  String get walkInCustomer => 'ဆိုင်ကို လာဝယ်သူ';

  @override
  String get toDo => 'လုပ်ရန်';

  @override
  String get done => 'ပြီးပြီ';

  @override
  String get noOrdersToHandle => 'လုပ်စရာ အော်ဒါ မရှိပါ';

  @override
  String get noFinishedOrders => 'ပြီးဆုံးသွားတဲ့ အော်ဒါ မရှိသေးပါ';

  @override
  String get noOrdersToHandleBody => 'App ထဲမှာ ရောင်းထားတာကို ဖောက်သည် မှာတာနဲ့ ဒီမှာ ပေါ်ပါမယ်။';

  @override
  String get noFinishedOrdersBody => 'ပို့ပြီးတဲ့ အော်ဒါနဲ့ ပယ်ဖျက်ထားတဲ့ အော်ဒါတွေကို ဒီမှာ ထားပါတယ်။';

  @override
  String get shopCancelOrderBody => 'ဖောက်သည်က ပယ်ဖျက်ပြီးလို့ မြင်ရပါမယ်။ ထုတ်ပြီးသား စတော့က ထွက်ထားဆဲပါ- ပြန်ထည့်ဖို့ စတော့အဝင် မှတ်ပါ။';

  @override
  String get keepIt => 'ဆက်ထားရန်';

  @override
  String get orderConfirmedDone => 'အတည်ပြုပြီးပါပြီ။ စတော့ ထွက်သွားပြီး မှတ်တမ်းထဲ ရောက်ပါပြီ။';

  @override
  String get confirm => 'အတည်ပြုရန်';

  @override
  String get markedOnItsWay => 'ပို့နေပြီလို့ မှတ်လိုက်ပါပြီ။';

  @override
  String get shipped => 'ပို့ပြီး';

  @override
  String get today => 'ဒီနေ့';

  @override
  String get sales => 'အရောင်း';

  @override
  String get counts => 'ရေတွက်ချက်';

  @override
  String get noMovementsYet => 'အဝင်အထွက် မရှိသေးပါ';

  @override
  String get noMovementsYetBody => 'ပစ္စည်းတစ်ခု ဖွင့်ပြီး အဝင်၊ အထွက် ဒါမှမဟုတ် ရေတွက် ကို နှိပ်ပါ။';

  @override
  String showingLatest(int count) {
    return 'နောက်ဆုံး $count ခုကို ပြထားပါတယ်။ မှတ်တမ်းအားလုံး ကြည့်ဖို့ ပစ္စည်းကို ဖွင့်ပါ။';
  }

  @override
  String get searchNameOrPhone => 'နာမည် ဒါမှမဟုတ် ဖုန်း ရှာရန်';

  @override
  String get noCustomersYet => 'ဖောက်သည် မရှိသေးပါ';

  @override
  String get noCustomersYetBody => 'ပုံမှန်ဝယ်သူတွေကို ဒီမှာ ထည့်ထားပြီး စတော့အထွက် မှတ်တဲ့အခါ ရွေးပါ။';

  @override
  String deleteNameQuestion(String name) {
    return '$name ကို ဖျက်မလား။';
  }

  @override
  String get deleteCustomerBody => 'အရင် စတော့အထွက်တွေမှာ နာမည် ဆက်ရှိနေပါမယ်။';

  @override
  String get addressOptional => 'လိပ်စာ (မထည့်လည်းရ)';

  @override
  String get addCustomer => 'ဖောက်သည် ထည့်ရန်';

  @override
  String get recentPurchases => 'မကြာသေးခင်က ဝယ်ထားတာတွေ';

  @override
  String get saving => 'သိမ်းနေတယ်…';

  @override
  String get shops => 'ဆိုင်များ';

  @override
  String get searchShops => 'နာမည်၊ အီးမေးလ် ဒါမှမဟုတ် ဖုန်း ရှာရန်';

  @override
  String get expiring => 'သက်တမ်းကုန်တော့မယ်';

  @override
  String get noShopsHere => 'ဒီမှာ ဆိုင် မရှိပါ';

  @override
  String get noShopsHereBody => 'App ထဲမှာ တစ်ယောက်ယောက် စာရင်းသွင်းရင် ဆိုင်အသစ် ပေါ်လာပါမယ်။';

  @override
  String signedUpOn(String date) {
    return '$date မှာ စာရင်းသွင်း';
  }

  @override
  String untilDaysLeft(String date, int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days ရက် ကျန်',
    );
    return '$date အထိ · $_temp0';
  }

  @override
  String get shopWorksUntil => 'ဆိုင်ဖွင့်ထားမယ့် နောက်ဆုံးနေ့';

  @override
  String shopNowRunsUntil(String shop, String date) {
    return '$shop ကို $date အထိ ဖွင့်ထားပါပြီ။';
  }

  @override
  String stopShopQuestion(String shop) {
    return '$shop ကို အခု ရပ်မလား။';
  }

  @override
  String get stopShopBody => 'ဆိုင်က ချက်ချင်း ကြည့်ရုံပဲ ရပါမယ်။ ဒေတာတွေ ဆက်ရှိပြီး သက်တမ်းတိုးရင် ပြန်ဖွင့်ပါမယ်။';

  @override
  String get stopNow => 'အခု ရပ်ရန်';

  @override
  String shopStopped(String shop) {
    return '$shop ကို ရပ်လိုက်ပါပြီ။';
  }

  @override
  String get waitingForYou => 'သင် ဖွင့်ပေးဖို့ စောင့်နေပါတယ်။';

  @override
  String runsUntil(String date) {
    return '$date အထိ ဖွင့်ထား';
  }

  @override
  String addTimeFrom(String date) {
    return '$date ကစပြီး အချိန်တိုးရန်';
  }

  @override
  String get addTimeFromToday => 'ဒီနေ့ကစပြီး အချိန်တိုးရန်';

  @override
  String addMonths(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '+ $count လ',
    );
    return '$_temp0';
  }

  @override
  String get addOneYear => '+ ၁ နှစ်';

  @override
  String get pickEndDate => 'ပြီးဆုံးရက် ရွေးရန်';

  @override
  String get stopThisShopNow => 'ဒီဆိုင်ကို အခု ရပ်ရန်';

  @override
  String get loading => 'ဖွင့်နေတယ်';

  @override
  String get errDeliveryFeeTooLarge => 'ပို့ခ များလွန်းပါတယ်။';

  @override
  String errTooManyPaymentMethods(int max) {
    return 'ဆိုင်တစ်ဆိုင်မှာ ငွေပေးနည်း $max မျိုးအထိပဲ ထည့်လို့ရပါတယ်။';
  }

  @override
  String get errPaymentMethodIncomplete => 'ငွေပေးနည်းတိုင်းအတွက် အကောင့်နာမည်နဲ့ နံပါတ် ဖြည့်ပါ၊ ဒါမှမဟုတ် ဖယ်ပါ။';

  @override
  String get errPaymentMethodTooLong => 'အကောင့်နာမည် ဒါမှမဟုတ် နံပါတ် ရှည်လွန်းပါတယ်။';

  @override
  String get paymentBank => 'ဘဏ်အကောင့်';

  @override
  String get shopSettings => 'ဆိုင် ဆက်တင်';

  @override
  String get shopPhoneHelp => 'ဖောက်သည်တွေ ဒီနံပါတ်နဲ့ ဖုန်းခေါ်၊ Viber ဆက်ပါမယ်။';

  @override
  String get deliveryFee => 'ပို့ခ';

  @override
  String get deliveryFeeHelp => 'အိမ်အရောက်ပို့ အော်ဒါတိုင်းမှာ ပေါင်းပါမယ်။ အခမဲ့ပို့ရင် အလွတ်ထားပါ။';

  @override
  String get waysToPay => 'ငွေပေးနည်းများ';

  @override
  String get waysToPayHelp => 'ဖောက်သည်တွေ သူတို့အော်ဒါမှာ ကော်ပီခလုတ်နဲ့အတူ မြင်ရပါမယ်။';

  @override
  String get addWayToPay => 'ငွေပေးနည်း ထည့်ရန်';

  @override
  String get accountName => 'အကောင့်နာမည်';

  @override
  String get walletPhone => 'Wallet ဖုန်းနံပါတ်';

  @override
  String get bankAccountNumber => 'ဘဏ်နဲ့ အကောင့်နံပါတ်';

  @override
  String get bankAccountNumberHint => 'KBZ Bank 0123 4567 8901';

  @override
  String get settingsSaved => 'ဆက်တင် သိမ်းပြီးပါပြီ။';

  @override
  String get setUpPayment => 'ပို့ဆောင်ရေးနဲ့ ငွေပေးချေမှု သတ်မှတ်ရန်';

  @override
  String get setUpPaymentBody => 'ဖုန်း၊ ပို့ခနဲ့ ဖောက်သည်တွေ ငွေပေးမယ့်နည်း ထည့်ပါ။';

  @override
  String get deliveryAndPayment => 'ပို့ဆောင်ရေးနဲ့ ငွေပေးချေမှု';

  @override
  String get freeDelivery => 'အခမဲ့ ပို့ပေး';

  @override
  String deliveryFeeLine(String fee) {
    return 'ပို့ခ $fee';
  }

  @override
  String get noWaysToPay => 'ငွေပေးနည်း မရှိသေးပါ';

  @override
  String get call => 'ဖုန်းခေါ်ရန်';

  @override
  String cannotCall(String phone) {
    return 'ဒီဖုန်းနဲ့ ဖုန်းခေါ်လို့ မရပါ။ နံပါတ်က $phone ပါ။';
  }

  @override
  String get viberNotInstalled => 'ဒီဖုန်းမှာ Viber မရှိပါ။';

  @override
  String get contactTheShop => 'ဆိုင်ကို ဆက်သွယ်ရန်';

  @override
  String get total => 'စုစုပေါင်း';

  @override
  String get pickupNoFee => 'မရှိပါ၊ ကိုယ်တိုင် လာယူ';

  @override
  String get copy => 'ကော်ပီ';

  @override
  String copied(String number) {
    return '$number ကို ကော်ပီကူးပြီးပါပြီ';
  }

  @override
  String get screenshotGone => 'ဒီ screenshot မရှိတော့ပါ။';

  @override
  String get screenshotSent => 'Screenshot ပို့ပြီးပါပြီ။ ဆိုင်က စစ်ပေးပါမယ်။';

  @override
  String get screenshotSentLine => 'ငွေလွှဲ screenshot ပို့ပြီး';

  @override
  String get view => 'ကြည့်ရန်';

  @override
  String howToPay(String total) {
    return 'ဆိုင်ကို $total ပေးပါ';
  }

  @override
  String get sendPaymentScreenshot => 'ငွေလွှဲ screenshot ပို့ရန်';

  @override
  String get replaceScreenshot => 'တခြား screenshot ပို့ရန်';

  @override
  String get customerSentPayment => 'ဖောက်သည်က ငွေလွှဲ screenshot ပို့ထားပါတယ်';

  @override
  String get blacklist => 'ပိတ်ထားသူများ';

  @override
  String get blockSomeone => 'တစ်ယောက်ယောက်ကို ပိတ်ရန်';

  @override
  String get blockThisOwner => 'ဒီပိုင်ရှင်ကို ပိတ်ရန်';

  @override
  String get block => 'ပိတ်ရန်';

  @override
  String get unblock => 'ပြန်ဖွင့်ရန်';

  @override
  String get remark => 'မှတ်ချက်';

  @override
  String get remarkHint => 'ဘာကြောင့် ပိတ်တာလဲ။ သင်ပဲ မြင်ရပါမယ်။';

  @override
  String get blockExplain => 'ပိတ်ထားတဲ့ အကောင့်က ဝင်လို့ရပေမယ့် အော်ဒါတင်တာ၊ ဆိုင်ဖွင့်တာ၊ ဘာမှပြင်တာ မလုပ်နိုင်ပါ။ ဘာမှ မဖျက်ပါ။';

  @override
  String get searchBlacklist => 'အီးမေးလ် ဒါမှမဟုတ် မှတ်ချက် ရှာရန်';

  @override
  String get nobodyBlocked => 'ပိတ်ထားသူ မရှိပါ';

  @override
  String get nobodyBlockedBody => 'သင်ပိတ်ထားတဲ့ အကောင့်တွေ သင့်မှတ်ချက်နဲ့အတူ ဒီမှာ ပေါ်ပါမယ်။';

  @override
  String blockedOn(String date) {
    return '$date မှာ ပိတ်ခဲ့';
  }

  @override
  String emailBlocked(String email) {
    return '$email ကို ပိတ်လိုက်ပါပြီ။';
  }

  @override
  String emailUnblocked(String email) {
    return '$email ကို ပြန်ဖွင့်လိုက်ပါပြီ။';
  }

  @override
  String get remarkSaved => 'မှတ်ချက် သိမ်းပြီးပါပြီ။';

  @override
  String unblockQuestion(String email) {
    return '$email ကို ပြန်ဖွင့်မလား။';
  }

  @override
  String get unblockBody => 'သူတို့ app ကို ချက်ချင်း ပြန်သုံးလို့ရပါမယ်။ ဆိုင်ဖွင့်ထားဆဲဆိုရင် ဆိုင်ပါ ပြန်သုံးလို့ရပါမယ်။';

  @override
  String get accountBlocked => 'သင့်အကောင့်ကို ပိတ်ထားပါတယ်';

  @override
  String accountBlockedBody(String appName) {
    return 'ဒီအကောင့်နဲ့ $appName ကို ဆက်သုံးလို့ မရတော့ပါ။ မှားနေတယ်ထင်ရင် ဆက်သွယ်ပါ။';
  }

  @override
  String get errEmailInvalid => 'မှန်ကန်တဲ့ အီးမေးလ်လိပ်စာ ထည့်ပါ။';

  @override
  String get errRemarkEmpty => 'မှတ်ချက် ရေးပါ- ဘာကြောင့် ပိတ်တာလဲ။';

  @override
  String get errCannotBlockYourself => 'ကိုယ့်အကောင့်ကို ကိုယ် ပိတ်လို့ မရပါ။';

  @override
  String get users => 'အသုံးပြုသူများ';

  @override
  String get searchUsers => 'အီးမေးလ် ဒါမှမဟုတ် ဆိုင်နာမည် ရှာရန်';

  @override
  String get customers => 'ဖောက်သည်များ';

  @override
  String get shopAdmins => 'ဆိုင်ပိုင်ရှင်များ';

  @override
  String get blockedFilter => 'ပိတ်ထား';

  @override
  String get blockedTag => 'ပိတ်ထား';

  @override
  String get you => 'သင်';

  @override
  String get roleCustomer => 'ဖောက်သည်';

  @override
  String roleShopAdmin(String shop) {
    return '$shop ၏ ဆိုင်ပိုင်ရှင်';
  }

  @override
  String lastSeenOn(String date) {
    return 'နောက်ဆုံး $date မှာ သုံးခဲ့';
  }

  @override
  String get noUsersHere => 'ဒီမှာ အကောင့် မရှိပါ';

  @override
  String get usersFootnote => 'အကောင့်တစ်ခုက app ဗားရှင်းအသစ်ကို ဖွင့်တာနဲ့ ဒီမှာ ပေါ်လာပါမယ်။';

  @override
  String get language => 'ဘာသာစကား';

  @override
  String get languagePhone => 'ဖုန်းရဲ့ ဘာသာစကား';
}
