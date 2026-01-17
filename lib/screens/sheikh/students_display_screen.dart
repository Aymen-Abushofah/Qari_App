import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:rxdart/rxdart.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/app_strings.dart';
import '../../models/student.dart';
import '../../models/student_record.dart';
import '../../services/firestore_service.dart';
import 'student_detail_screen.dart';

/// StudentsDisplayScreen: The primary "daily session" view for the Sheikh.
///
/// Responsibilities:
/// 1. Session Oversight: Lists all active students and their current status for today.
/// 2. Live Monitoring: Uses a combined stream to show whether a student has been marked present/absent in real-time.
/// 3. Navigation: Acts as the gateway to the `StudentDetailScreen` for data entry.
/// 4. Global Search: Allows quick filtering of students by name.
class StudentsDisplayScreen extends StatefulWidget {
  const StudentsDisplayScreen({super.key});

  @override
  State<StudentsDisplayScreen> createState() => _StudentsDisplayScreenState();
}

class _StudentsDisplayScreenState extends State<StudentsDisplayScreen> {
  final _firestoreService = FirestoreService();
  String _searchQuery = '';
  final _searchController = TextEditingController();
  final _searchFocus = FocusNode();

  /// Reactive stream joining Student profile data with today's StudentRecord.
  late Stream<List<Map<String, dynamic>>> _combinedStream;

  @override
  void initState() {
    super.initState();
    _initStream();
  }

  /// Sets up a reactive join between the student list and today's attendance/hifz records.
  void _initStream() {
    _combinedStream = CombineLatestStream.combine2(
      _firestoreService.getAllStudents(),
      _firestoreService.getRecordsForDate(DateTime.now()),
      (List<Student> students, List<StudentRecord> records) {
        return students.map((student) {
          // Check if a record exists for this specific student today.
          final StudentRecord? todayRecord = records
              .cast<StudentRecord?>()
              .firstWhere(
                (r) => r?.studentId == student.id,
                orElse: () => null,
              );
          return {'student': student, 'record': todayRecord};
        }).toList();
      },
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _combinedStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final allItems = snapshot.data ?? [];
          final filteredItems = allItems.where((item) {
            final Student student = item['student'];
            return student.name.toLowerCase().contains(
              _searchQuery.toLowerCase(),
            );
          }).toList();

          return RefreshIndicator(
            onRefresh: () async {
              setState(() {
                _initStream();
              });
            },
            color: AppTheme.primaryColor,
            child: NestedScrollView(
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
                          colors: [
                            AppTheme.primaryColor,
                            AppTheme.primaryLight,
                          ],
                        ),
                      ),
                      child: SafeArea(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 10, 20, 60),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    AppStrings.students,
                                    style: GoogleFonts.tajawal(
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  Text(
                                    '${allItems.length} طالب مسجل',
                                    style: GoogleFonts.tajawal(
                                      fontSize: 14,
                                      color: Colors.white70,
                                    ),
                                  ),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.school_rounded,
                                  color: Colors.white,
                                  size: 28,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  bottom: PreferredSize(
                    preferredSize: const Size.fromHeight(60),
                    child: Container(
                      height: 60,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(color: AppTheme.primaryColor),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: TextField(
                          controller: _searchController,
                          focusNode: _searchFocus,
                          onChanged: (value) =>
                              setState(() => _searchQuery = value),
                          textDirection: TextDirection.rtl,
                          style: GoogleFonts.tajawal(),
                          decoration: InputDecoration(
                            hintText: 'ابحث باسم الطالب...',
                            hintStyle: GoogleFonts.tajawal(
                              color: Theme.of(
                                context,
                              ).textTheme.bodyMedium?.color,
                            ),
                            prefixIcon: Icon(
                              Icons.search,
                              color: AppTheme.primaryColor,
                            ),
                            suffixIcon: _searchQuery.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.close, size: 20),
                                    color: AppTheme.textSecondary,
                                    onPressed: () {
                                      _searchController.clear();
                                      setState(() => _searchQuery = '');
                                      _searchFocus.unfocus();
                                    },
                                  )
                                : null,
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 14,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
              body: filteredItems.isEmpty
                  ? Center(
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryColor.withValues(
                                  alpha: 0.1,
                                ),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                _searchQuery.isEmpty
                                    ? Icons.person_off_rounded
                                    : Icons.search_off,
                                size: 48,
                                color: AppTheme.primaryColor,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _searchQuery.isEmpty
                                  ? 'لا يوجد طلاب'
                                  : 'لا توجد نتائج لـ "$_searchQuery"',
                              style: GoogleFonts.tajawal(
                                fontSize: 16,
                                color: Theme.of(
                                  context,
                                ).textTheme.bodyMedium?.color,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: filteredItems.length,
                      itemBuilder: (context, index) {
                        final item = filteredItems[index];
                        final Student student = item['student'];
                        final StudentRecord? record = item['record'];
                        return _StudentCard(
                          student: student,
                          todayRecord: record,
                          onTap: () => _navigateToStudent(student),
                        );
                      },
                    ),
            ),
          );
        },
      ),
    );
  }

  /// Opens the detailed input screen for a specific student.
  void _navigateToStudent(Student student) {
    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (_) => StudentDetailScreen(student: student),
          ),
        )
        // Refresh UI on back to update the "marked/unmarked" status icons.
        .then((_) => setState(() {}));
  }
}

/// A compact card showing a student's basic info and their status for the current session.
class _StudentCard extends StatelessWidget {
  final Student student;
  final StudentRecord? todayRecord;
  final VoidCallback onTap;

  const _StudentCard({
    required this.student,
    this.todayRecord,
    required this.onTap,
  });

  /// Logic for status coloring based on attendance.
  Color _getStatusColor(BuildContext context) {
    if (todayRecord == null) return Theme.of(context).disabledColor;
    switch (todayRecord!.attendanceStatus) {
      case AttendanceStatus.present:
        return AppTheme.successColor;
      case AttendanceStatus.absentExcused:
      case AttendanceStatus.absentUnexcused:
        return AppTheme.errorColor;
    }
  }

  /// Logic for status text labels.
  String get _statusText {
    if (todayRecord == null) return 'لم يُسجل';
    switch (todayRecord!.attendanceStatus) {
      case AttendanceStatus.present:
        return AppStrings.present;
      case AttendanceStatus.absentExcused:
        return AppStrings.absentExcused;
      case AttendanceStatus.absentUnexcused:
        return AppStrings.absentUnexcused;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
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
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // --- Identity ---
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      student.name,
                      style: GoogleFonts.tajawal(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              // --- Daily Status ---
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _getStatusColor(context).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          todayRecord?.isPresent == true
                              ? Icons.check_circle
                              : Icons.circle_outlined,
                          size: 12,
                          color: _getStatusColor(context),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _statusText,
                          style: GoogleFonts.tajawal(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: _getStatusColor(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Current progress snippet
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.menu_book_rounded,
                        size: 14,
                        color: AppTheme.secondaryColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${AppStrings.juz} ${student.currentJuz}',
                        style: GoogleFonts.tajawal(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Theme.of(context).textTheme.bodyMedium?.color,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_left_rounded,
                color: Theme.of(context).disabledColor,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
