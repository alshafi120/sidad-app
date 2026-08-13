/// Application string constants — Arabic-first with professional fintech wording.
library;

abstract final class AppStrings {
  // ── Brand ────────────────────────────────────────────────────────
  static const String appName = 'سداد';
  static const String appNameEn = 'Sidad';
  static const String tagline = 'إدارة ديونك... بكل سهولة';

  // ── Auth — Login ────────────────────────────────────────────────
  static const String welcomeBack = 'مرحباً بك';
  static const String loginTitle = 'تسجيل الدخول';
  static const String loginSubtitle =
      'أدخل بريدك الإلكتروني وكلمة المرور للدخول';
  static const String loginBtn = 'تسجيل الدخول';
  static const String loginNow = 'سجّل دخولك الآن';

  // ── Auth — Register ─────────────────────────────────────────────
  static const String registerTitle = 'إنشاء حساب جديد';
  static const String registerSubtitle = 'أنشئ حسابك للبدء في إدارة مديونياتك';
  static const String registerBtn = 'إنشاء الحساب';
  static const String registerNow = 'سجّل الآن';

  // ── Auth — Fields ───────────────────────────────────────────────
  static const String email = 'البريد الإلكتروني';
  static const String emailHint = 'example@mail.com';
  static const String emailRequired = 'الرجاء إدخال البريد الإلكتروني';
  static const String emailInvalid = 'البريد الإلكتروني غير صحيح';
  static const String password = 'كلمة المرور';
  static const String passwordHint = '••••••••';
  static const String passwordRequired = 'الرجاء إدخال كلمة المرور';
  static const String passwordTooShort =
      'كلمة المرور يجب أن تكون 8 أحرف على الأقل';
  static const String confirmPassword = 'تأكيد كلمة المرور';
  static const String confirmPasswordHint = '••••••••';
  static const String confirmPasswordRequired = 'الرجاء تأكيد كلمة المرور';
  static const String passwordMismatch = 'كلمة المرور غير متطابقة';
  static const String fullName = 'الاسم الكامل';
  static const String fullNameHint = 'أدخل اسمك الكامل';
  static const String nameRequired = 'الرجاء إدخال الاسم';
  static const String phoneNumber = 'رقم الجوال';
  static const String enterPhone = 'أدخل رقم الجوال';
  static const String phoneRequired = 'الرجاء إدخال رقم الجوال';
  static const String phoneInvalid = 'رقم الجوال غير صحيح';
  static const String forgotPassword = 'نسيت كلمة المرور؟';

  // ── Auth — Navigation ───────────────────────────────────────────
  static const String noAccount = 'ليس لديك حساب؟';
  static const String haveAccount = 'لديك حساب بالفعل؟';
  static const String or = 'أو';

  // ── Auth — OTP (kept for future use) ────────────────────────────
  static const String sendOtp = 'إرسال رمز التحقق';
  static const String otpTitle = 'رمز التحقق';
  static const String otpSubtitle = 'أدخل الرمز المرسل إلى رقم جوالك';
  static const String verify = 'تحقق';
  static const String resendOtp = 'إعادة إرسال الرمز';
  static const String resendIn = 'إعادة الإرسال بعد';

  // ── Role Selection ───────────────────────────────────────────────
  static const String selectRole = 'اختر نوع حسابك';
  static const String merchant = 'تاجر';
  static const String merchantDesc = 'سجّل المديونيات وتابع حسابات عملائك';
  static const String customer = 'عميل';
  static const String customerDesc = 'تابع مديونياتك وسجل معاملاتك';
  static const String continueBtn = 'متابعة';

  // ── Dashboard ────────────────────────────────────────────────────
  static const String dashboard = 'لوحة التحكم';
  static const String totalDebts = 'إجمالي المديونيات';
  static const String activeCustomers = 'العملاء النشطين';
  static const String settledDebts = 'المديونيات المسدّدة';
  static const String pendingDebts = 'المديونيات المعلّقة';
  static const String recentTransactions = 'أحدث العمليات';
  static const String viewAll = 'عرض الكل';
  static const String quickActions = 'إجراءات سريعة';

  // ── Customers ────────────────────────────────────────────────────
  static const String customers = 'العملاء';
  static const String customerList = 'قائمة العملاء';
  static const String addCustomer = 'إضافة عميل جديد';
  static const String customerName = 'اسم العميل';
  static const String customerPhone = 'رقم جوال العميل';
  static const String customerNotes = 'ملاحظات';
  static const String saveCustomer = 'حفظ بيانات العميل';
  static const String searchCustomers = 'البحث في العملاء...';
  static const String noCustomers = 'لا يوجد عملاء بعد';
  static const String noCustomersDesc = 'أضف عميلك الأول لبدء تتبع المديونيات';

  // ── Debts ─────────────────────────────────────────────────────────
  static const String debts = 'المديونيات';
  static const String addDebt = 'تسجيل مديونية جديدة';
  static const String debtAmount = 'المبلغ';
  static const String debtDescription = 'وصف المعاملة';
  static const String debtDate = 'تاريخ المعاملة';
  static const String dueDate = 'تاريخ الاستحقاق';
  static const String saveDebt = 'تسجيل المديونية';
  static const String debtDetails = 'تفاصيل المديونية';
  static const String markAsPaid = 'تسجيل كمسدّدة';
  static const String partialPayment = 'سداد جزئي';
  static const String remaining = 'المتبقي';
  static const String paid = 'مسدّدة';
  static const String pending = 'معلّقة';
  static const String overdue = 'متأخرة';
  static const String noDebts = 'لا توجد مديونيات';
  static const String noDebtsDesc = 'سجّل أول معاملة لبدء التتبع';

  // ── Notifications ────────────────────────────────────────────────
  static const String notifications = 'الإشعارات';
  static const String noNotifications = 'لا توجد إشعارات';
  static const String noNotificationsDesc =
      'ستظهر الإشعارات هنا عند وجود تحديثات';
  static const String markAllRead = 'تحديد الكل كمقروء';
  static const String today = 'اليوم';
  static const String yesterday = 'أمس';
  static const String earlier = 'سابقاً';

  // ── Profile & Settings ───────────────────────────────────────────
  static const String profile = 'الملف الشخصي';
  static const String settings = 'الإعدادات';
  static const String editProfile = 'تعديل الملف الشخصي';
  static const String language = 'اللغة';
  static const String darkMode = 'الوضع الداكن';
  static const String notificationSettings = 'إعدادات الإشعارات';
  static const String privacy = 'الخصوصية والأمان';
  static const String helpSupport = 'المساعدة والدعم';
  static const String about = 'عن التطبيق';
  static const String logout = 'تسجيل الخروج';
  static const String logoutConfirm = 'هل تريد تسجيل الخروج؟';
  static const String version = 'الإصدار';

  // ── General ──────────────────────────────────────────────────────
  static const String save = 'حفظ';
  static const String cancel = 'إلغاء';
  static const String delete = 'حذف';
  static const String edit = 'تعديل';
  static const String confirm = 'تأكيد';
  static const String success = 'تمت العملية بنجاح';
  static const String error = 'حدث خطأ';
  static const String retry = 'إعادة المحاولة';
  static const String loading = 'جاري التحميل...';
  static const String noConnection = 'لا يوجد اتصال بالإنترنت';
  static const String currency = 'ر.ي';
  static const String currencyCode = 'YER';
}
