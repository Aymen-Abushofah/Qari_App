/// Centralized Arabic strings for the Qari app
class AppStrings {
  // App identity
  static const String appName = 'قارئ';
  static const String appSlogan = 'نظام متابعة حفظ القرآن الكريم';
  static const String copyright = '© 2026 قارئ - جميع الحقوق محفوظة';

  // User selection screen
  static const String selectUserType = 'اختر نوع المستخدم';
  static const String sheikh = 'الشيخ / المعلم';
  static const String sheikhDescription = 'إدارة الطلاب ومتابعة الحفظ';
  static const String parent = 'ولي الأمر';
  static const String parentDescription = 'متابعة تقدم أبنائك';
  static const String student = 'الطالب';
  static const String studentDescription = 'عرض تقدمك في الحفظ';

  // Auth screen
  static const String login = 'تسجيل الدخول';
  static const String signup = 'إنشاء حساب';
  static const String email = 'البريد الإلكتروني';
  static const String phone = 'رقم الجوال';
  static const String password = 'كلمة المرور';
  static const String confirmPassword = 'تأكيد كلمة المرور';
  static const String fullName = 'الاسم الكامل';
  static const String pinCode = 'رمز PIN';
  static const String loginButton = 'دخول';
  static const String signupButton = 'إنشاء حساب';
  static const String forgotPassword = 'نسيت كلمة المرور؟';
  static const String alreadyHaveAccount = 'لديك حساب بالفعل؟';
  static const String dontHaveAccount = 'ليس لديك حساب؟';

  // Validation messages
  static const String requiredField = 'هذا الحقل مطلوب';
  static const String invalidEmail = 'البريد الإلكتروني غير صحيح';
  static const String passwordTooShort = 'كلمة المرور قصيرة جداً';
  static const String passwordsNotMatch = 'كلمات المرور غير متطابقة';

  // General
  static const String loading = 'جاري التحميل...';
  static const String error = 'حدث خطأ';
  static const String success = 'تم بنجاح';
  static const String cancel = 'إلغاء';
  static const String confirm = 'تأكيد';
  static const String save = 'حفظ';
  static const String next = 'التالي';
  static const String back = 'رجوع';
  static const String search = 'بحث';
  static const String add = 'إضافة';
  static const String edit = 'تعديل';
  static const String delete = 'حذف';
  static const String noData = 'لا توجد بيانات';
  static const String today = 'اليوم';

  // Sheikh Dashboard
  static const String dashboard = 'الرئيسية';
  static const String students = 'الطلاب';
  static const String management = 'الإدارة';
  static const String reports = 'التقارير';
  static const String messages = 'الرسائل';
  static const String logout = 'تسجيل الخروج';
  static const String requests = 'الطلبات';
  static const String welcomeSheikh = 'مرحباً شيخنا';
  static const String welcomeParent = 'مرحباً بك يا';
  static const String welcomeStudent = 'مرحباً بك يا بطلنا';
  static const String todayStats = 'إحصائيات اليوم';
  static const String totalStudents = 'إجمالي الطلاب';
  static const String presentToday = 'الحاضرون اليوم';
  static const String absentToday = 'الغائبون اليوم';
  static const String completedHifz = 'أتموا الحفظ';

  // Student Management
  static const String studentsManagement = 'إدارة الطلاب';
  static const String addStudent = 'إضافة طالب';
  static const String editStudent = 'تعديل بيانات الطالب';
  static const String deleteStudent = 'حذف الطالب';
  static const String deleteStudentConfirm = 'هل أنت متأكد من حذف هذا الطالب؟';
  static const String studentName = 'اسم الطالب';
  static const String studentAge = 'العمر';
  static const String parentName = 'اسم ولي الأمر';
  static const String selectParent = 'اختر ولي الأمر';
  static const String noParent = 'بدون ولي أمر';
  static const String searchStudentOrParent = 'بحث بالاسم أو اسم ولي الأمر';
  static const String enrollmentDate = 'تاريخ التسجيل';
  static const String currentProgress = 'التقدم الحالي';
  static const String juz = 'جزء';
  static const String surah = 'سورة';
  static const String ayah = 'آية';

  // Student Data Entry
  static const String studentDetails = 'بيانات الطالب';
  static const String dataEntry = 'إدخال البيانات';
  static const String calendar = 'التقويم';
  static const String dailyHifz = 'الحفظ اليومي';
  static const String dailyReview = 'المراجعة اليومية';
  static const String fromSurah = 'من سورة';
  static const String toSurah = 'إلى سورة';
  static const String fromAyah = 'من آية';
  static const String toAyah = 'إلى آية';
  static const String mistakes = 'الأخطاء';
  static const String performance = 'الأداء';
  static const String attendance = 'الحضور';
  static const String listener = 'المستمع';
  static const String notes = 'ملاحظات';
  static const String saveRecord = 'حفظ السجل';

  // Attendance Status
  static const String present = 'حاضر';
  static const String absentExcused = 'غياب بإذن';
  static const String absentUnexcused = 'غياب بدون إذن';
  static const String late = 'متأخر';

  // Performance Levels
  static const String excellent = 'ممتاز';
  static const String veryGood = 'جيد جداً';
  static const String good = 'جيد';
  static const String acceptable = 'مقبول';
  static const String weak = 'ضعيف';

  // Listener Types
  static const String listenerSheikh = 'الشيخ';
  static const String listenerAssistant = 'المساعد';
  static const String listenerOtherSheikh = 'شيخ آخر';

  // Reports
  static const String dailyReport = 'التقرير اليومي';
  static const String monthlyReport = 'التقرير الشهري';
  static const String generateReport = 'إنشاء التقرير';
  static const String selectDate = 'اختر التاريخ';
  static const String selectMonth = 'اختر الشهر';
  static const String noRecordsToday = 'لا توجد سجلات لهذا اليوم';
  static const String attendanceRate = 'نسبة الحضور';
  static const String averagePerformance = 'متوسط الأداء';

  // Messages
  static const String conversations = 'المحادثات';
  static const String noConversations = 'لا توجد محادثات';
  static const String typeMessage = 'اكتب رسالتك...';
  static const String send = 'إرسال';
  static const String newMessage = 'رسالة جديدة';
}
