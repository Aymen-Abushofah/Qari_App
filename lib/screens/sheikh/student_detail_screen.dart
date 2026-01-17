import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/app_strings.dart';
import '../../models/student.dart';
import '../../models/student_record.dart';
import '../../services/firestore_service.dart';
import 'package:rxdart/rxdart.dart';

/// StudentDetailScreen: The primary engine for tracking daily student progress.
///
/// Key Features:
/// 1. Data Entry: Unified form for attendance, hifz (memorization), and review progress.
/// 2. Performance Tracking: Allows rating student performance (Excellent, Good, etc.).
/// 3. Calendar View: Visual heatmap showing attendance and progress history.
/// 4. Reporting: Tabular view of all historical records for the student.
/// 5. Peer/Sheikh Listening: Supports recording who listened to the student (Sheikh or peer).
class StudentDetailScreen extends StatefulWidget {
  final Student student;

  const StudentDetailScreen({super.key, required this.student});

  @override
  State<StudentDetailScreen> createState() => _StudentDetailScreenState();
}

class _StudentDetailScreenState extends State<StudentDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _firestoreService = FirestoreService();
  late Stream<List<dynamic>> _dataStream;

  // Progress controllers
  late TextEditingController _currentJuzController;
  late TextEditingController _currentSurahController;
  late TextEditingController _currentAyahController;

  // Form controllers
  AttendanceStatus _attendanceStatus = AttendanceStatus.present;
  PerformanceLevel? _performance;
  ListenerType _listenerType = ListenerType.sheikh;
  String? _selectedListenerId;

  final _hifzFromSurahController = TextEditingController();
  final _hifzFromAyahController = TextEditingController();
  final _hifzToSurahController = TextEditingController();
  final _hifzToAyahController = TextEditingController();
  final _hifzMistakesController = TextEditingController(text: '0');

  final _reviewFromSurahController = TextEditingController();
  final _reviewFromAyahController = TextEditingController();
  final _reviewToSurahController = TextEditingController();
  final _reviewToAyahController = TextEditingController();
  final _reviewMistakesController = TextEditingController(text: '0');

  final _notesController = TextEditingController();

  final DateTime _selectedDate = DateTime.now();
  DateTime _calendarMonth = DateTime.now();

  bool get _isAbsent => _attendanceStatus != AttendanceStatus.present;
  bool _isAlreadySubmitted = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    // Initialize progress controllers with student data
    _currentJuzController = TextEditingController(
      text: widget.student.currentJuz.toString(),
    );
    _currentSurahController = TextEditingController(
      text: widget.student.currentSurah,
    );
    _currentAyahController = TextEditingController(
      text: widget.student.currentAyah.toString(),
    );

    _dataStream = CombineLatestStream.list([
      _firestoreService.getStudentRecords(widget.student.id),
      _firestoreService.getSheikhs(),
      _firestoreService.getStudentByUid(widget.student.id),
    ]).asBroadcastStream();
  }

  /// Synchronizes the form state with an existing record if one was
  /// already submitted for the current session.
  void _setupTodayRecord(StudentRecord? record) {
    if (record != null && !_isAlreadySubmitted) {
      if (record.date.year == DateTime.now().year &&
          record.date.month == DateTime.now().month &&
          record.date.day == DateTime.now().day) {
        _isAlreadySubmitted = true;
        _attendanceStatus = record.attendanceStatus;
        _performance = record.performance;
        _listenerType = record.listenerType ?? ListenerType.sheikh;
        _selectedListenerId = record.listenerId;
        _hifzFromSurahController.text = record.hifzFromSurah ?? '';
        _hifzFromAyahController.text = record.hifzFromAyah?.toString() ?? '';
        _hifzToSurahController.text = record.hifzToSurah ?? '';
        _hifzToAyahController.text = record.hifzToAyah?.toString() ?? '';
        _hifzMistakesController.text = record.hifzMistakes.toString();
        _reviewFromSurahController.text = record.reviewFromSurah ?? '';
        _reviewFromAyahController.text =
            record.reviewFromAyah?.toString() ?? '';
        _reviewToSurahController.text = record.reviewToSurah ?? '';
        _reviewToAyahController.text = record.reviewToAyah?.toString() ?? '';
        _reviewMistakesController.text = record.reviewMistakes.toString();
        _notesController.text = record.notes ?? '';
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _currentJuzController.dispose();
    _currentSurahController.dispose();
    _currentAyahController.dispose();
    _hifzFromSurahController.dispose();
    _hifzFromAyahController.dispose();
    _hifzToSurahController.dispose();
    _hifzToAyahController.dispose();
    _hifzMistakesController.dispose();
    _reviewFromSurahController.dispose();
    _reviewFromAyahController.dispose();
    _reviewToSurahController.dispose();
    _reviewToAyahController.dispose();
    _reviewMistakesController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  /// Updates the student's global progress markers (Juz, Surah, Ayah).
  Future<void> _updateProgress() async {
    final updatedStudent = widget.student.copyWith(
      currentJuz:
          int.tryParse(_currentJuzController.text) ?? widget.student.currentJuz,
      currentSurah: _currentSurahController.text.isNotEmpty
          ? _currentSurahController.text
          : widget.student.currentSurah,
      currentAyah:
          int.tryParse(_currentAyahController.text) ??
          widget.student.currentAyah,
    );

    await _firestoreService.updateStudent(updatedStudent);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 8),
              Text('تم تحديث مستوى الطالب بنجاح', style: GoogleFonts.tajawal()),
            ],
          ),
          backgroundColor: AppTheme.successColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  /// Commits a new StudentRecord to Firestore for the selected date.
  /// Handles both attendance-only (absent) and full progress (present) scenarios.
  Future<void> _saveRecord() async {
    final record = StudentRecord(
      id: '', // Firestore will generate an ID
      studentId: widget.student.id,
      date: _selectedDate,
      hifzFromSurah: _isAbsent
          ? null
          : (_hifzFromSurahController.text.isNotEmpty
                ? _hifzFromSurahController.text
                : null),
      hifzFromAyah: _isAbsent
          ? null
          : int.tryParse(_hifzFromAyahController.text),
      hifzToSurah: _isAbsent
          ? null
          : (_hifzToSurahController.text.isNotEmpty
                ? _hifzToSurahController.text
                : null),
      hifzToAyah: _isAbsent ? null : int.tryParse(_hifzToAyahController.text),
      hifzMistakes: _isAbsent
          ? 0
          : (int.tryParse(_hifzMistakesController.text) ?? 0),
      reviewFromSurah: _isAbsent
          ? null
          : (_reviewFromSurahController.text.isNotEmpty
                ? _reviewFromSurahController.text
                : null),
      reviewFromAyah: _isAbsent
          ? null
          : int.tryParse(_reviewFromAyahController.text),
      reviewToSurah: _isAbsent
          ? null
          : (_reviewToSurahController.text.isNotEmpty
                ? _reviewToSurahController.text
                : null),
      reviewToAyah: _isAbsent
          ? null
          : int.tryParse(_reviewToAyahController.text),
      reviewMistakes: _isAbsent
          ? 0
          : (int.tryParse(_reviewMistakesController.text) ?? 0),
      attendanceStatus: _attendanceStatus,
      performance: _isAbsent ? null : _performance,
      listenerType: _isAbsent ? null : _listenerType,
      listenerId: _isAbsent ? null : _selectedListenerId,
      notes: _notesController.text.isNotEmpty ? _notesController.text : null,
      createdAt: DateTime.now(),
    );

    await _firestoreService.addStudentRecord(record);

    if (mounted) {
      setState(() {
        _isAlreadySubmitted = true;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 8),
              Text(AppStrings.success, style: GoogleFonts.tajawal()),
            ],
          ),
          backgroundColor: AppTheme.successColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          duration: const Duration(seconds: 2),
        ),
      );

      _tabController.animateTo(1);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          widget.student.name,
          style: GoogleFonts.tajawal(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        backgroundColor: AppTheme.primaryColor,
        elevation: 0,
        leading: const BackButton(color: Colors.white),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelStyle: GoogleFonts.tajawal(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
          tabs: const [
            Tab(
              icon: Icon(Icons.edit_note_rounded, size: 20),
              text: 'إدخال البيانات',
            ),
            Tab(
              icon: Icon(Icons.calendar_month_rounded, size: 20),
              text: 'التقويم',
            ),
            Tab(icon: Icon(Icons.analytics_rounded, size: 20), text: 'السجلات'),
          ],
        ),
      ),
      body: StreamBuilder<List<dynamic>>(
        stream: _dataStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 48,
                    color: AppTheme.errorColor,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'خطأ في تحميل البيانات: ${snapshot.error}',
                    style: GoogleFonts.tajawal(color: AppTheme.textSecondary),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          final records = snapshot.data?[0] as List<StudentRecord>? ?? [];
          final sheikhs =
              snapshot.data?[1] as List<Map<String, dynamic>>? ?? [];
          final liveStudent = snapshot.data != null && snapshot.data!.length > 2
              ? snapshot.data![2] as Student?
              : null;

          // Try to load today's record if it exists
          final todayRecord = records.where((r) {
            final today = DateTime.now();
            return r.date.year == today.year &&
                r.date.month == today.month &&
                r.date.day == today.day;
          }).firstOrNull;

          if (todayRecord != null && !_isAlreadySubmitted) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                setState(() {
                  _setupTodayRecord(todayRecord);
                });
              }
            });
          }

          return TabBarView(
            controller: _tabController,
            children: [
              _buildDataEntryTab(sheikhs, liveStudent ?? widget.student),
              _buildCalendarTab(records),
              _buildReportsTab(records),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDataEntryTab(
    List<Map<String, dynamic>> activeSheikhs,
    Student currentStudent,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Current Progress Card
          _buildGradientCard(
            title: 'مستوى الحفظ الحالي',
            icon: Icons.flag_rounded,
            color: Colors.orange.shade700,
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildModernTextField(
                        'الجزء',
                        _currentJuzController,
                        isNumber: true,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: _buildModernTextField(
                        'اسم السورة',
                        _currentSurahController,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildModernTextField(
                        'رقم الآية',
                        _currentAyahController,
                        isNumber: true,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _updateProgress,
                    icon: const Icon(Icons.update_rounded, size: 18),
                    label: Text(
                      'تحديث المستوى',
                      style: GoogleFonts.tajawal(fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange.shade700,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Date and Attendance Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).cardColor,
                  Theme.of(context).cardColor.withValues(alpha: 0.8),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 20,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              children: [
                // Date display
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.calendar_today_rounded,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppStrings.today,
                          style: GoogleFonts.tajawal(
                            fontSize: 12,
                            color: AppTheme.textSecondary,
                          ),
                        ),
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
                    const Spacer(),
                    if (_isAlreadySubmitted)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.successColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppTheme.successColor),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.check_circle,
                              size: 16,
                              color: AppTheme.successColor,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'تم الرصد',
                              style: GoogleFonts.tajawal(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.successColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                const Divider(height: 32),
                // Attendance Dropdown
                DropdownButtonFormField<AttendanceStatus>(
                  value: _attendanceStatus,
                  decoration: InputDecoration(
                    labelText: AppStrings.attendance,
                    prefixIcon: Icon(
                      Icons.person_pin_circle_rounded,
                      color: _getAttendanceColor(_attendanceStatus),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Theme.of(context).dividerColor,
                      ),
                    ),
                  ),
                  items: AttendanceStatus.values.map((status) {
                    return DropdownMenuItem(
                      value: status,
                      child: Text(
                        _getAttendanceLabel(status),
                        style: GoogleFonts.tajawal(
                          fontWeight: FontWeight.w500,
                          color: _getAttendanceColor(status),
                        ),
                      ),
                    );
                  }).toList(),
                  onChanged: _isAlreadySubmitted
                      ? null
                      : (value) {
                          if (value != null) {
                            setState(() => _attendanceStatus = value);
                          }
                        },
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          if (!_isAbsent) ...[
            // Hifz Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 20,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.menu_book, color: AppTheme.primaryColor),
                      const SizedBox(width: 8),
                      Text(
                        AppStrings.dailyHifz,
                        style: GoogleFonts.tajawal(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _hifzFromSurahController,
                          enabled: !_isAlreadySubmitted,
                          decoration: InputDecoration(
                            labelText: AppStrings.surah,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _hifzFromAyahController,
                          enabled: !_isAlreadySubmitted,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: AppStrings.ayah,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Icon(Icons.arrow_downward, color: Colors.grey),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _hifzToSurahController,
                          enabled: !_isAlreadySubmitted,
                          decoration: InputDecoration(
                            labelText: AppStrings.surah,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _hifzToAyahController,
                          enabled: !_isAlreadySubmitted,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: AppStrings.ayah,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _hifzMistakesController,
                    enabled: !_isAlreadySubmitted,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: AppStrings.mistakes,
                      prefixIcon: const Icon(
                        Icons.warning_amber_rounded,
                        color: Colors.orange,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Review Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 20,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.history_edu, color: AppTheme.secondaryColor),
                      const SizedBox(width: 8),
                      Text(
                        AppStrings.dailyReview,
                        style: GoogleFonts.tajawal(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _reviewFromSurahController,
                          enabled: !_isAlreadySubmitted,
                          decoration: InputDecoration(
                            labelText: AppStrings.surah,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _reviewFromAyahController,
                          enabled: !_isAlreadySubmitted,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: AppStrings.ayah,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Icon(Icons.arrow_downward, color: Colors.grey),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _reviewToSurahController,
                          enabled: !_isAlreadySubmitted,
                          decoration: InputDecoration(
                            labelText: AppStrings.surah,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _reviewToAyahController,
                          enabled: !_isAlreadySubmitted,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: AppStrings.ayah,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _reviewMistakesController,
                    enabled: !_isAlreadySubmitted,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: AppStrings.mistakes,
                      prefixIcon: const Icon(
                        Icons.warning_amber_rounded,
                        color: Colors.orange,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Performance Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 20,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.star, color: Colors.amber),
                      const SizedBox(width: 8),
                      Text(
                        AppStrings.performance,
                        style: GoogleFonts.tajawal(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  DropdownButtonFormField<PerformanceLevel>(
                    value: _performance,
                    decoration: InputDecoration(
                      labelText: AppStrings.performance,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    items: PerformanceLevel.values.map((level) {
                      return DropdownMenuItem(
                        value: level,
                        child: Text(
                          _getPerformanceLabel(level),
                          style: GoogleFonts.tajawal(),
                        ),
                      );
                    }).toList(),
                    onChanged: _isAlreadySubmitted
                        ? null
                        : (value) => setState(() => _performance = value),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<ListenerType>(
                    value: _listenerType, // Fixed: logic for listener type
                    decoration: InputDecoration(
                      labelText: AppStrings.listener,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    items: ListenerType.values.map((type) {
                      return DropdownMenuItem(
                        value: type,
                        child: Text(
                          type == ListenerType.sheikh
                              ? AppStrings.sheikh
                              : AppStrings.listenerOtherSheikh,
                          style: GoogleFonts.tajawal(),
                        ),
                      );
                    }).toList(),
                    onChanged: _isAlreadySubmitted
                        ? null
                        : (value) => setState(() => _listenerType = value!),
                  ),
                  if (_listenerType == ListenerType.anotherSheikh) ...[
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _selectedListenerId,
                      decoration: InputDecoration(
                        labelText: 'اختر الشيخ المستمع',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      items: activeSheikhs.map((sheikh) {
                        return DropdownMenuItem(
                          value: sheikh['uid'] as String,
                          child: Text(
                            sheikh['name'] ?? 'Unknown',
                            style: GoogleFonts.tajawal(),
                          ),
                        );
                      }).toList(),
                      onChanged: _isAlreadySubmitted
                          ? null
                          : (value) =>
                                setState(() => _selectedListenerId = value),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],

          // Notes
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 20,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.note_alt, color: Colors.blue),
                    const SizedBox(width: 8),
                    Text(
                      AppStrings.notes,
                      style: GoogleFonts.tajawal(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _notesController,
                  enabled: !_isAlreadySubmitted,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'أضف ملاحظاتك هنا...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),

          // Submit Button
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _isAlreadySubmitted ? null : _saveRecord,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 4,
              ),
              child: Text(
                _isAlreadySubmitted
                    ? 'تم رصد الحفظ لهذا اليوم'
                    : AppStrings.saveRecord,
                style: GoogleFonts.tajawal(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildGradientCard({
    required String title,
    required IconData icon,
    required Color color,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: GoogleFonts.tajawal(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).textTheme.titleMedium?.color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildModernTextField(
    String label,
    TextEditingController controller, {
    bool isNumber = false,
  }) {
    return TextField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      textDirection: TextDirection.rtl,
      style: GoogleFonts.tajawal(),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.tajawal(
          fontSize: 12,
          color: AppTheme.textSecondary,
        ),
        filled: true,
        fillColor: Theme.of(context).inputDecorationTheme.fillColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppTheme.primaryColor, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
    );
  }

  Widget _buildCalendarTab(List<StudentRecord> records) {
    final today = DateTime.now();
    final daysInMonth = _getDaysInMonth(_calendarMonth);
    final firstDayOfMonth = DateTime(
      _calendarMonth.year,
      _calendarMonth.month,
      1,
    );
    int firstWeekday = (firstDayOfMonth.weekday + 1) % 7;
    const dayNames = ['س', 'ح', 'ن', 'ث', 'ر', 'خ', 'ج'];

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          color: Theme.of(context).cardColor,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_right_rounded),
                onPressed: () => setState(
                  () => _calendarMonth = DateTime(
                    _calendarMonth.year,
                    _calendarMonth.month + 1,
                  ),
                ),
              ),
              Text(
                '${_getArabicMonth(_calendarMonth.month)} ${_calendarMonth.year}',
                style: GoogleFonts.tajawal(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).textTheme.titleLarge?.color,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_left_rounded),
                onPressed: () => setState(
                  () => _calendarMonth = DateTime(
                    _calendarMonth.year,
                    _calendarMonth.month - 1,
                  ),
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: Theme.of(context).cardColor,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: dayNames
                .map(
                  (name) => SizedBox(
                    width: 40,
                    child: Center(
                      child: Text(
                        name,
                        style: GoogleFonts.tajawal(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (int i = 0; i < firstWeekday; i++)
                  SizedBox(
                    width: (MediaQuery.of(context).size.width - 32 - 48) / 7,
                    height: (MediaQuery.of(context).size.width - 32 - 48) / 7,
                  ),
                for (int day = 1; day <= daysInMonth; day++)
                  _buildCalendarDay(day, records, today),
              ],
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.all(16),
          color: Theme.of(context).cardColor,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildLegendItem(AppTheme.successColor, 'حضور + حفظ'),
              _buildLegendItem(Colors.orange, 'حضور فقط'),
              _buildLegendItem(AppTheme.errorColor, 'غياب'),
              _buildLegendItem(Colors.blue, 'اليوم'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCalendarDay(
    int day,
    List<StudentRecord> records,
    DateTime today,
  ) {
    final date = DateTime(_calendarMonth.year, _calendarMonth.month, day);
    final isToday =
        today.year == date.year &&
        today.month == date.month &&
        today.day == date.day;
    final record = records
        .where(
          (r) =>
              r.date.year == date.year &&
              r.date.month == date.month &&
              r.date.day == date.day,
        )
        .firstOrNull;

    // Determine background color based on status
    Color dayColor = Colors.white;
    Color borderColor = Theme.of(context).dividerColor.withValues(alpha: 0.1);
    Color textColor =
        Theme.of(context).textTheme.bodyMedium?.color ?? Colors.black;

    if (record != null) {
      if (record.isPresent && record.hasHifz) {
        dayColor = AppTheme.successColor.withValues(alpha: 0.15);
        borderColor = AppTheme.successColor;
        textColor = AppTheme.successColor;
      } else if (record.isPresent) {
        dayColor = Colors.orange.withValues(alpha: 0.15);
        borderColor = Colors.orange;
        textColor = Colors.orange.shade700;
      } else {
        dayColor = AppTheme.errorColor.withValues(alpha: 0.15);
        borderColor = AppTheme.errorColor;
        textColor = AppTheme.errorColor;
      }
    } else {
      textColor = Theme.of(context).disabledColor;
    }

    if (isToday) {
      borderColor = Colors.blue;
      textColor = Colors.blue;
      if (record == null) {
        dayColor = Colors.blue.withValues(alpha: 0.05);
      }
    }

    final cellSize = (MediaQuery.of(context).size.width - 32 - 48) / 7;

    return GestureDetector(
      onTap: record != null ? () => _showDayDetails(date, record) : null,
      child: Container(
        width: cellSize,
        height: cellSize,
        decoration: BoxDecoration(
          color: dayColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: borderColor, width: isToday ? 2 : 1),
        ),
        child: Center(
          child: Text(
            day.toString(),
            style: GoogleFonts.tajawal(
              fontWeight: isToday ? FontWeight.bold : FontWeight.w500,
              color: textColor,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }

  void _showDayDetails(DateTime date, StudentRecord record) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(context).dividerColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '${date.day}/${date.month}/${date.year}',
              style: GoogleFonts.tajawal(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildDetailRow(
              'الحضور',
              _getAttendanceLabel(record.attendanceStatus),
            ),
            if (record.hasHifz) ...[
              const SizedBox(height: 8),
              _buildDetailRow(
                'الحفظ',
                '${record.hifzFromSurah} (${record.hifzFromAyah}) → ${record.hifzToSurah} (${record.hifzToAyah})',
              ),
            ],
            if (record.hasReview) ...[
              const SizedBox(height: 8),
              _buildDetailRow(
                'المراجعة',
                '${record.reviewFromSurah} → ${record.reviewToSurah}',
              ),
            ],
            if (record.performance != null) ...[
              const SizedBox(height: 8),
              _buildDetailRow(
                'الأداء',
                _getPerformanceLabel(record.performance!),
              ),
            ],
            if (record.notes != null && record.notes!.isNotEmpty) ...[
              const SizedBox(height: 8),
              _buildDetailRow('ملاحظات', record.notes!),
            ],
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$label: ',
          style: GoogleFonts.tajawal(
            fontWeight: FontWeight.w600,
            color: AppTheme.primaryColor,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.tajawal(
              color: Theme.of(context).textTheme.bodyMedium?.color,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildReportsTab(List<StudentRecord> records) {
    return records.isEmpty
        ? Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.history,
                  size: 64,
                  color: AppTheme.textSecondary.withValues(alpha: 0.5),
                ),
                const SizedBox(height: 16),
                Text(
                  'لا توجد سجلات',
                  style: GoogleFonts.tajawal(
                    fontSize: 16,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          )
        : ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: records.length,
            itemBuilder: (context, index) {
              final record = records[records.length - 1 - index];
              return _buildRecordCard(record);
            },
          );
  }

  Widget _buildRecordCard(StudentRecord record) {
    return Container(
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
          onTap: () => _showDayDetails(record.date, record),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: _getAttendanceColor(
                              record.attendanceStatus,
                            ).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            record.isPresent
                                ? Icons.check_circle
                                : Icons.cancel,
                            color: _getAttendanceColor(record.attendanceStatus),
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          '${record.date.day}/${record.date.month}/${record.date.year}',
                          style: GoogleFonts.tajawal(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(
                              context,
                            ).textTheme.titleSmall?.color,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _getAttendanceColor(
                          record.attendanceStatus,
                        ).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _getAttendanceLabel(record.attendanceStatus),
                        style: GoogleFonts.tajawal(
                          fontSize: 12,
                          color: _getAttendanceColor(record.attendanceStatus),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                if (record.hasHifz) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(
                        Icons.auto_stories,
                        size: 16,
                        color: AppTheme.primaryColor,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${record.hifzFromSurah} → ${record.hifzToSurah}',
                        style: GoogleFonts.tajawal(
                          fontSize: 13,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      if (record.performance != null) ...[
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: _getPerformanceColor(
                              record.performance!,
                            ).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            _getPerformanceLabel(record.performance!),
                            style: GoogleFonts.tajawal(
                              fontSize: 11,
                              color: _getPerformanceColor(record.performance!),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.2),
            border: Border.all(color: color),
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: GoogleFonts.tajawal(
            fontSize: 10,
            color: Theme.of(context).textTheme.bodySmall?.color,
          ),
        ),
      ],
    );
  }

  String _getAttendanceLabel(AttendanceStatus status) {
    switch (status) {
      case AttendanceStatus.present:
        return AppStrings.present;
      case AttendanceStatus.absentExcused:
        return AppStrings.absentExcused;
      case AttendanceStatus.absentUnexcused:
        return AppStrings.absentUnexcused;
    }
  }

  Color _getAttendanceColor(AttendanceStatus status) {
    switch (status) {
      case AttendanceStatus.present:
        return AppTheme.successColor;
      case AttendanceStatus.absentExcused:
      case AttendanceStatus.absentUnexcused:
        return AppTheme.errorColor;
    }
  }

  String _getPerformanceLabel(PerformanceLevel level) {
    switch (level) {
      case PerformanceLevel.excellent:
        return AppStrings.excellent;
      case PerformanceLevel.veryGood:
        return AppStrings.veryGood;
      case PerformanceLevel.good:
        return AppStrings.good;
      case PerformanceLevel.acceptable:
        return AppStrings.acceptable;
      case PerformanceLevel.weak:
        return AppStrings.weak;
    }
  }

  Color _getPerformanceColor(PerformanceLevel level) {
    switch (level) {
      case PerformanceLevel.excellent:
        return AppTheme.successColor;
      case PerformanceLevel.veryGood:
        return Colors.green.shade400;
      case PerformanceLevel.good:
        return Colors.orange;
      case PerformanceLevel.acceptable:
        return Colors.orange.shade700;
      case PerformanceLevel.weak:
        return AppTheme.errorColor;
    }
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

  int _getDaysInMonth(DateTime date) =>
      DateTime(date.year, date.month + 1, 0).day;
}
