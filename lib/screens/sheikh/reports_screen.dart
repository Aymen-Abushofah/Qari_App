import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:rxdart/rxdart.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/app_strings.dart';
import '../../models/student.dart';
import '../../models/student_record.dart';
import '../../services/firestore_service.dart';
import 'student_detail_screen.dart';
import 'monthly_report_detail_screen.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar(
            expandedHeight: 140,
            pinned: true,
            elevation: 0,
            automaticallyImplyLeading: false,
            backgroundColor: AppTheme.primaryColor,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppTheme.primaryColor, AppTheme.primaryLight],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 80),
                    child: Align(
                      alignment: Alignment.bottomRight,
                      child: Text(
                        AppStrings.reports,
                        style: GoogleFonts.tajawal(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            bottom: TabBar(
              controller: _tabController,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
              indicatorColor: Colors.white,
              indicatorWeight: 3,
              labelStyle: GoogleFonts.tajawal(fontWeight: FontWeight.w600),
              tabs: [
                Tab(
                  icon: const Icon(Icons.today_rounded, size: 20),
                  text: AppStrings.dailyReport,
                ),
                Tab(
                  icon: const Icon(Icons.calendar_month_rounded, size: 20),
                  text: AppStrings.monthlyReport,
                ),
              ],
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabController,
          children: const [DailyReportTab(), MonthlyReportTab()],
        ),
      ),
    );
  }
}

class DailyReportTab extends StatefulWidget {
  const DailyReportTab({super.key});

  @override
  State<DailyReportTab> createState() => _DailyReportTabState();
}

class _DailyReportTabState extends State<DailyReportTab>
    with AutomaticKeepAliveClientMixin {
  final _firestoreService = FirestoreService();
  DateTime _selectedDate = DateTime.now();
  late Stream<List<dynamic>> _dailyReportStream;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _initStream();
  }

  void _initStream() {
    _dailyReportStream = CombineLatestStream.list([
      _firestoreService.getAllStudents().asBroadcastStream(),
      _firestoreService.getRecordsForDate(_selectedDate).asBroadcastStream(),
    ]).asBroadcastStream();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    return StreamBuilder<List<dynamic>>(
      stream: _dailyReportStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline, size: 48, color: AppTheme.errorColor),
                const SizedBox(height: 16),
                Text(
                  'حدث خطأ في تحميل البيانات',
                  style: GoogleFonts.tajawal(color: AppTheme.textSecondary),
                ),
              ],
            ),
          );
        }

        final students = snapshot.data?[0] as List<Student>? ?? [];
        final records = snapshot.data?[1] as List<StudentRecord>? ?? [];

        final presentCount = records.where((r) => r.isPresent).length;
        final hifzCount = records.where((r) => r.hasHifz).length;

        return RefreshIndicator(
          onRefresh: () async => setState(() => _initStream()),
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              // Date picker
              Container(
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.chevron_right_rounded),
                          onPressed: () {
                            setState(() {
                              _selectedDate = _selectedDate.add(
                                const Duration(days: 1),
                              );
                              _initStream();
                            });
                          },
                        ),
                        GestureDetector(
                          onTap: _pickDate,
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryColor.withValues(
                                    alpha: 0.1,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  Icons.calendar_today_rounded,
                                  color: AppTheme.primaryColor,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                                style: GoogleFonts.tajawal(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(
                                    context,
                                  ).textTheme.titleLarge?.color,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.chevron_left_rounded),
                          onPressed: () {
                            setState(() {
                              _selectedDate = _selectedDate.subtract(
                                const Duration(days: 1),
                              );
                              _initStream();
                            });
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Progress bars
                    _buildProgressRow(
                      'الحضور',
                      presentCount,
                      students.length,
                      AppTheme.successColor,
                    ),
                    const SizedBox(height: 10),
                    _buildProgressRow(
                      'الحفظ',
                      hifzCount,
                      students.length,
                      AppTheme.primaryColor,
                    ),
                  ],
                ),
              ),
              // Student list
              if (students.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Text(
                      AppStrings.noData,
                      style: GoogleFonts.tajawal(color: AppTheme.textSecondary),
                    ),
                  ),
                )
              else
                ...students.map((student) {
                  final record = records
                      .where((r) => r.studentId == student.id)
                      .firstOrNull;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: _buildStudentReportCard(student, record),
                  );
                }),
              const SizedBox(height: 80), // Bottom padding
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (date != null) {
      setState(() {
        _selectedDate = date;
        _initStream();
      });
    }
  }

  Widget _buildProgressRow(String label, int value, int total, Color color) {
    final percentage = total == 0 ? 0.0 : value / total;
    return Row(
      children: [
        SizedBox(
          width: 60,
          child: Text(
            label,
            style: GoogleFonts.tajawal(
              fontSize: 12,
              color: Theme.of(context).textTheme.bodySmall?.color,
            ),
          ),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: percentage,
              backgroundColor: color.withValues(alpha: 0.1),
              valueColor: AlwaysStoppedAnimation(color),
              minHeight: 10,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          '$value/$total',
          style: GoogleFonts.tajawal(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildStudentReportCard(Student student, StudentRecord? record) {
    return GestureDetector(
      onTap: () => Navigator.of(context)
          .push(
            MaterialPageRoute(
              builder: (_) => StudentDetailScreen(student: student),
            ),
          )
          .then((_) => setState(() => _initStream())),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => Navigator.of(context)
                .push(
                  MaterialPageRoute(
                    builder: (_) => StudentDetailScreen(student: student),
                  ),
                )
                .then((_) => setState(() => _initStream())),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          student.name,
                          style: GoogleFonts.tajawal(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: Theme.of(
                              context,
                            ).textTheme.titleSmall?.color,
                          ),
                        ),
                        const SizedBox(height: 4),
                        if (record != null && record.hasHifz)
                          Row(
                            children: [
                              Icon(
                                Icons.auto_stories,
                                size: 14,
                                color: AppTheme.primaryColor,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${record.hifzFromSurah} → ${record.hifzToSurah}',
                                style: GoogleFonts.tajawal(
                                  fontSize: 12,
                                  color: Theme.of(
                                    context,
                                  ).textTheme.bodySmall?.color,
                                ),
                              ),
                            ],
                          )
                        else
                          Text(
                            record == null ? 'لم يُسجل بعد' : 'لا يوجد حفظ',
                            style: GoogleFonts.tajawal(
                              fontSize: 12,
                              color: Theme.of(
                                context,
                              ).textTheme.bodySmall?.color,
                            ),
                          ),
                      ],
                    ),
                  ),
                  // Status & Performance
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: record == null
                              ? Colors.grey.withValues(alpha: 0.1)
                              : (record.isPresent
                                        ? AppTheme.successColor
                                        : AppTheme.errorColor)
                                    .withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          record == null
                              ? '-'
                              : (record.isPresent
                                    ? AppStrings.present
                                    : 'غائب'),
                          style: GoogleFonts.tajawal(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: record == null
                                ? Theme.of(context).disabledColor
                                : (record.isPresent
                                      ? AppTheme.successColor
                                      : AppTheme.errorColor),
                          ),
                        ),
                      ),
                      if (record?.performance != null) ...[
                        const SizedBox(height: 4),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: List.generate(5, (i) {
                            final level =
                                PerformanceLevel.values.length -
                                1 -
                                record!.performance!.index;
                            return Icon(
                              i < level ? Icons.star : Icons.star_border,
                              size: 12,
                              color: Colors.amber,
                            );
                          }),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.chevron_left,
                    color: Theme.of(context).disabledColor,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class MonthlyReportTab extends StatefulWidget {
  const MonthlyReportTab({super.key});

  @override
  State<MonthlyReportTab> createState() => _MonthlyReportTabState();
}

class _MonthlyReportTabState extends State<MonthlyReportTab>
    with AutomaticKeepAliveClientMixin {
  final _firestoreService = FirestoreService();
  DateTime _selectedMonth = DateTime.now();
  late Stream<List<dynamic>> _monthlyReportStream;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _initStream();
  }

  void _initStream() {
    _monthlyReportStream = CombineLatestStream.list([
      _firestoreService.getAllStudents().asBroadcastStream(),
      _firestoreService.getRecordsForMonth(_selectedMonth).asBroadcastStream(),
    ]).asBroadcastStream();
  }

  String _getArabicMonth(int month) {
    const months = [
      'يناير',
      'فبراير',
      'مارس',
      'أبريل',
      'مايو',
      'يونيو',
      'يوليو',
      'أغسطس',
      'سبتمبر',
      'أكتوبر',
      'نوفمبر',
      'ديسمبر',
    ];
    return months[month - 1];
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    return StreamBuilder<List<dynamic>>(
      stream: _monthlyReportStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline, size: 48, color: AppTheme.errorColor),
                const SizedBox(height: 16),
                Text(
                  'حدث خطأ في تحميل البيانات',
                  style: GoogleFonts.tajawal(color: AppTheme.textSecondary),
                ),
              ],
            ),
          );
        }

        final students = snapshot.data?[0] as List<Student>? ?? [];
        final allMonthRecords = snapshot.data?[1] as List<StudentRecord>? ?? [];

        return RefreshIndicator(
          onRefresh: () async => setState(() => _initStream()),
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              // Month picker
              Container(
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_right_rounded),
                      onPressed: () {
                        setState(() {
                          _selectedMonth = DateTime(
                            _selectedMonth.year,
                            _selectedMonth.month + 1,
                          );
                          _initStream();
                        });
                      },
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        gradient: AppTheme.primaryGradient,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${_getArabicMonth(_selectedMonth.month)} ${_selectedMonth.year}',
                        style: GoogleFonts.tajawal(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_left_rounded),
                      onPressed: () {
                        setState(() {
                          _selectedMonth = DateTime(
                            _selectedMonth.year,
                            _selectedMonth.month - 1,
                          );
                          _initStream();
                        });
                      },
                    ),
                  ],
                ),
              ),
              // Monthly summary
              if (students.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Text(
                      AppStrings.noData,
                      style: GoogleFonts.tajawal(color: AppTheme.textSecondary),
                    ),
                  ),
                )
              else
                ...students.map((student) {
                  final monthRecords = allMonthRecords
                      .where((r) => r.studentId == student.id)
                      .toList();
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: _buildMonthlyStudentCard(student, monthRecords),
                  );
                }),
              const SizedBox(height: 80), // Bottom padding
            ],
          ),
        );
      },
    );
  }

  Widget _buildMonthlyStudentCard(
    Student student,
    List<StudentRecord> records,
  ) {
    int getDaysInMonth(DateTime date) {
      return DateTime(date.year, date.month + 1, 0).day;
    }

    final totalDays = getDaysInMonth(_selectedMonth);
    final presentDays = records.where((r) => r.isPresent).length;
    final hifzDays = records.where((r) => r.hasHifz).length;
    final attendanceRate = records.isEmpty ? 0.0 : presentDays / totalDays;

    return GestureDetector(
      onTap: () => Navigator.of(context)
          .push(
            MaterialPageRoute(
              builder: (_) => MonthlyReportDetailScreen(
                student: student,
                month: _selectedMonth,
                records: records,
              ),
            ),
          )
          .then((_) => setState(() => _initStream())),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => Navigator.of(context)
                .push(
                  MaterialPageRoute(
                    builder: (_) => MonthlyReportDetailScreen(
                      student: student,
                      month: _selectedMonth,
                      records: records,
                    ),
                  ),
                )
                .then((_) => setState(() => _initStream())),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              student.name,
                              style: GoogleFonts.tajawal(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                                color: Theme.of(
                                  context,
                                ).textTheme.titleSmall?.color,
                              ),
                            ),
                            Text(
                              '${AppStrings.juz} ${student.currentJuz}',
                              style: GoogleFonts.tajawal(
                                fontSize: 12,
                                color: Theme.of(
                                  context,
                                ).textTheme.bodySmall?.color,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Circular progress
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox(
                            width: 50,
                            height: 50,
                            child: CircularProgressIndicator(
                              value: attendanceRate,
                              backgroundColor: Colors.grey.shade200,
                              valueColor: AlwaysStoppedAnimation(
                                attendanceRate > 0.7
                                    ? AppTheme.successColor
                                    : attendanceRate > 0.4
                                    ? Colors.orange
                                    : AppTheme.errorColor,
                              ),
                              strokeWidth: 5,
                            ),
                          ),
                          Text(
                            '${(attendanceRate * 100).round()}%',
                            style: GoogleFonts.tajawal(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(
                                context,
                              ).textTheme.titleSmall?.color,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _buildMonthStat(
                        Icons.event_available,
                        '$presentDays/$totalDays',
                        'حضور',
                        AppTheme.successColor,
                      ),
                      const SizedBox(width: 16),
                      _buildMonthStat(
                        Icons.auto_stories,
                        '$hifzDays',
                        'حفظ',
                        AppTheme.primaryColor,
                      ),
                      const Spacer(),
                      Icon(
                        Icons.chevron_left,
                        color: Theme.of(context).disabledColor,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMonthStat(
    IconData icon,
    String value,
    String label,
    Color color,
  ) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: color),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: GoogleFonts.tajawal(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              style: GoogleFonts.tajawal(
                fontSize: 10,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
