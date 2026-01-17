import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:rxdart/rxdart.dart';
import '../../core/constants/app_strings.dart';
import '../../models/student.dart';
import '../../models/student_record.dart';
import '../../services/firebase_auth_service.dart';
import '../../services/firestore_service.dart';
import '../user_selection/user_selection_screen.dart';
import '../sheikh/monthly_report_detail_screen.dart';
import '../common/daily_report_detail_screen.dart';

/// StudentDashboardScreen: A gamified dashboard for the student persona.
///
/// Core Features:
/// 1. Motivation Engine: Tracks and displays a "streak" of excellent performance days.
/// 2. Progress Visualization: Shows the student's current position (Juz, Surah, Ayah).
/// 3. Performance Summary: Highlights the number of "Excellent" ratings received.
/// 4. Direct Reporting: Allows students to view their own daily and monthly records.
class StudentDashboardScreen extends StatefulWidget {
  const StudentDashboardScreen({super.key});

  @override
  State<StudentDashboardScreen> createState() => _StudentDashboardScreenState();
}

class _StudentDashboardScreenState extends State<StudentDashboardScreen> {
  final _firestoreService = FirestoreService();
  final _authService = FirebaseAuthService();

  late Stream<Map<String, dynamic>> _dashboardStream;
  Map<String, dynamic>? _userData;

  @override
  void initState() {
    super.initState();
    _initStream();
    _loadUserData();
  }

  /// Fetches the private student profile name from Firestore.
  Future<void> _loadUserData() async {
    final uid = _authService.currentUser?.uid;
    if (uid != null) {
      final doc = await _firestoreService.getUserData(uid);
      if (doc.exists && mounted) {
        setState(() {
          _userData = doc.data() as Map<String, dynamic>?;
        });
      }
    }
  }

  /// Sets up a reactive join between student metadata and their historical records.
  void _initStream() {
    final uid = _authService.currentUser?.uid ?? '';
    _dashboardStream = CombineLatestStream.combine2(
      _firestoreService.getStudentByUid(uid),
      _firestoreService.getStudentRecords(uid),
      (Student? student, List<StudentRecord> records) {
        return {'student': student, 'records': records};
      },
    );
  }

  /// Streak logic: count consecutive days with attendance "present"
  /// and performance "excellent" or "veryGood".
  int _calculateStreak(List<StudentRecord> records) {
    int currentStreak = 0;
    // Streak logic: count consecutive days with attendance "present" and performance "excellent" or "veryGood"
    for (var record in records) {
      if (record.attendanceStatus == AttendanceStatus.present &&
          (record.performance == PerformanceLevel.excellent ||
              record.performance == PerformanceLevel.veryGood)) {
        currentStreak++;
      } else if (record.attendanceStatus == AttendanceStatus.absentExcused) {
        break;
      } else {
        break;
      }
    }
    return currentStreak;
  }

  void _handleLogout() async {
    await _authService.logout();
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const UserSelectionScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Map<String, dynamic>>(
      stream: _dashboardStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final data = snapshot.data;
        final Student? student = data?['student'];
        final List<StudentRecord> records = data?['records'] ?? [];
        final streak = _calculateStreak(records);

        if (student == null) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('لوحتي القرآنية'),
              actions: [
                IconButton(
                  onPressed: _handleLogout,
                  icon: const Icon(Icons.logout),
                ),
              ],
            ),
            body: const Center(child: Text('جاري إعداد بياناتك القرآنية...')),
          );
        }

        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          appBar: AppBar(
            title: Text(
              'لوحتي القرآنية',
              style: GoogleFonts.amiri(
                fontWeight: FontWeight.bold,
                fontSize: 24,
              ),
            ),
            centerTitle: true,
            backgroundColor: Colors.teal,
            foregroundColor: Colors.white,
            actions: [
              IconButton(
                onPressed: _handleLogout,
                icon: const Icon(Icons.logout_rounded),
                tooltip: AppStrings.logout,
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                if (_userData != null) ...[
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      '${AppStrings.welcomeStudent} ${_userData!['name']}',
                      style: GoogleFonts.amiri(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.teal.shade800,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                _buildMotivationHeader(streak),
                const SizedBox(height: 24),
                _buildProgressCard(student),
                const SizedBox(height: 24),
                _buildStatsSection(records),
                const SizedBox(height: 24),
                _buildActionButtons(student, records),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMotivationHeader(int streak) {
    final bool hasReward = streak >= 10;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Colors.teal, Colors.tealAccent],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.teal.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.local_fire_department_rounded,
                color: Colors.orange,
                size: 40,
              ),
              const SizedBox(width: 12),
              Text(
                '$streak',
                style: GoogleFonts.tajawal(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          Text(
            'أيام من التميز المتواصل!',
            style: GoogleFonts.tajawal(
              fontSize: 18,
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
          const SizedBox(height: 20),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: (streak % 10) / 10,
              minHeight: 12,
              backgroundColor: Colors.white.withValues(alpha: 0.2),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            hasReward
                ? 'مبروك! لقد استحققت جائزة!'
                : 'باقي ${10 - (streak % 10)} أيام للحصول على مفاجأة!',
            style: GoogleFonts.tajawal(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          if (hasReward) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.card_giftcard_rounded, color: Colors.white),
                  const SizedBox(width: 8),
                  Text(
                    'يوم إجازة مكافأة',
                    style: GoogleFonts.tajawal(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildProgressCard(Student student) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.teal.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'موقعي الحالي في الحفظ',
            style: GoogleFonts.tajawal(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildProgressRow(
            'الجزء',
            student.currentJuz.toString(),
            Icons.layers_rounded,
          ),
          const Divider(height: 24),
          _buildProgressRow(
            'السورة',
            'سورة ${student.currentSurah}',
            Icons.auto_stories_rounded,
          ),
          const Divider(height: 24),
          _buildProgressRow(
            'الآية',
            'الآية رقم ${student.currentAyah}',
            Icons.bookmark_rounded,
          ),
        ],
      ),
    );
  }

  Widget _buildProgressRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: Colors.teal, size: 24),
        const SizedBox(width: 16),
        Text(
          label,
          style: GoogleFonts.tajawal(
            color: Theme.of(context).textTheme.bodySmall?.color,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: GoogleFonts.tajawal(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildStatsSection(List<StudentRecord> records) {
    final excellentCount = records
        .where((r) => r.performance == PerformanceLevel.excellent)
        .length;

    return Row(
      children: [
        Expanded(
          child: _buildSmallStatCard(
            'تقدير ممتاز',
            excellentCount.toString(),
            Icons.star_rounded,
            Colors.amber,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildSmallStatCard(
            'مستوى التقدم',
            'ممتاز',
            Icons.trending_up_rounded,
            Colors.green,
          ),
        ),
      ],
    );
  }

  Widget _buildSmallStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.1)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 30),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.tajawal(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.tajawal(
              fontSize: 12,
              color: Theme.of(context).textTheme.bodySmall?.color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(Student student, List<StudentRecord> records) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 60,
          child: ElevatedButton.icon(
            onPressed: () {
              final now = DateTime.now();
              final monthRecords = records
                  .where(
                    (r) => r.date.month == now.month && r.date.year == now.year,
                  )
                  .toList();

              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => MonthlyReportDetailScreen(
                    student: student,
                    month: DateTime(now.year, now.month),
                    records: monthRecords,
                  ),
                ),
              );
            },
            icon: const Icon(Icons.assessment_rounded),
            label: Text(
              'تقريري المفصل',
              style: GoogleFonts.tajawal(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          height: 60,
          child: OutlinedButton.icon(
            onPressed: () {
              final record = records.isEmpty
                  ? null
                  : records.firstWhere(
                      (r) =>
                          r.date.day == DateTime.now().day &&
                          r.date.month == DateTime.now().month &&
                          r.date.year == DateTime.now().year,
                      orElse: () => records.first,
                    );

              if (record != null && record.date.day == DateTime.now().day) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => DailyReportDetailScreen(
                      student: student,
                      record: record,
                    ),
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'لا يوجد سجل تم إدخاله لهذا اليوم بعد',
                      style: GoogleFonts.tajawal(),
                    ),
                    backgroundColor: Colors.orange,
                  ),
                );
              }
            },
            icon: const Icon(Icons.history_rounded),
            label: Text(
              'سجل المراجعة اليومي',
              style: GoogleFonts.tajawal(fontSize: 16),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.teal,
              side: const BorderSide(color: Colors.teal),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
