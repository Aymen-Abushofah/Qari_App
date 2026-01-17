import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:rxdart/rxdart.dart';
import 'package:url_launcher/url_launcher_string.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/app_strings.dart';
import '../../models/student.dart';
import '../../models/student_record.dart';
import '../../services/firebase_auth_service.dart';
import '../../services/firestore_service.dart';
import '../user_selection/user_selection_screen.dart';
import '../sheikh/monthly_report_detail_screen.dart';
import '../common/daily_report_detail_screen.dart';

/// ParentDashboardScreen: The central hub for parents to monitor their children's progress.
///
/// Responsibilities:
/// 1. Children Oversight: Displays cards for each child linked to the account.
/// 2. Real-time Updates: Uses a nested stream pattern to show today's hifz status live.
/// 3. Communication: Provides a directory of Sheikhs with direct "Call" functionality.
/// 4. Historical Access: Links to detailed daily and monthly performance reports.
class ParentDashboardScreen extends StatefulWidget {
  const ParentDashboardScreen({super.key});

  @override
  State<ParentDashboardScreen> createState() => _ParentDashboardScreenState();
}

class _ParentDashboardScreenState extends State<ParentDashboardScreen> {
  final _firestoreService = FirestoreService();
  final _authService = FirebaseAuthService();
  int _currentIndex = 0;
  Map<String, dynamic>? _userData;

  late Stream<List<Map<String, dynamic>>> _childrenStream;

  @override
  void initState() {
    super.initState();
    _initStreams();
    _loadUserData();
  }

  /// Fetches private profile data (e.g. name) for personalized UI greeting.
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

  /// Sets up a complex stream mapping: Parent -> [Students] -> today's [StudentRecord].
  void _initStreams() {
    final parentId = _authService.currentUser?.uid ?? '';

    _childrenStream = _firestoreService.getStudentsByParent(parentId).switchMap(
      (students) {
        if (students.isEmpty) return Stream.value([]);

        final recordStreams = students.map((student) {
          return _firestoreService.getRecordsForDate(DateTime.now()).map((
            records,
          ) {
            final todayRecord = records.cast<StudentRecord?>().firstWhere(
              (r) => r?.studentId == student.id,
              orElse: () => null,
            );
            return {'student': student, 'todayRecord': todayRecord};
          });
        }).toList();

        return CombineLatestStream.list(recordStreams);
      },
    );
  }

  /// Logs out and resets the navigation stack to the landing screen.
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
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'لوحة ولي الأمر',
          style: GoogleFonts.tajawal(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: AppTheme.secondaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: _handleLogout,
            icon: const Icon(Icons.logout_rounded),
            tooltip: AppStrings.logout,
          ),
        ],
      ),
      body: _currentIndex == 0 ? _buildChildrenSection() : _buildSheikhsList(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        selectedItemColor: AppTheme.secondaryColor,
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.family_restroom_rounded),
            label: 'أبنائي',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble_outline_rounded),
            label: 'تواصل مع الشيوخ',
          ),
        ],
      ),
    );
  }

  Widget _buildChildrenSection() {
    return Column(
      children: [
        if (_userData != null)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            color: AppTheme.secondaryColor.withValues(alpha: 0.1),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${AppStrings.welcomeParent} ${_userData!['name']}',
                  style: GoogleFonts.amiri(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.secondaryColor,
                  ),
                ),
                Text(
                  'نسأل الله أن يبارك في أبنائك ويجعلهم من أهل القرآن',
                  style: GoogleFonts.tajawal(
                    fontSize: 14,
                    color: AppTheme.secondaryColor.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
        Expanded(
          child: StreamBuilder<List<Map<String, dynamic>>>(
            stream: _childrenStream,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final childrenData = snapshot.data ?? [];

              if (childrenData.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.child_care_rounded,
                        size: 80,
                        color: Colors.grey.shade300,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'لا يوجد أبناء مرتبطين بحسابك حالياً',
                        style: GoogleFonts.tajawal(
                          fontSize: 18,
                          color: Theme.of(context).textTheme.bodySmall?.color,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'يرجى التواصل مع الإدارة لربط أبنائك',
                        style: GoogleFonts.tajawal(
                          fontSize: 14,
                          color: Theme.of(context).disabledColor,
                        ),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: childrenData.length,
                itemBuilder: (context, index) {
                  final data = childrenData[index];
                  return _buildChildCard(data['student'], data['todayRecord']);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSheikhsList() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _firestoreService.getSheikhs(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final sheikhs = snapshot.data ?? [];
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: sheikhs.length,
          itemBuilder: (context, index) {
            final sheikh = sheikhs[index];
            final name = sheikh['name'] ?? 'بدون اسم';
            final phone = sheikh['phone'] ?? '';

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
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 8,
                ),
                leading: CircleAvatar(
                  backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
                  child: Icon(
                    Icons.person_rounded,
                    color: AppTheme.primaryColor,
                  ),
                ),
                title: Text(
                  name,
                  style: GoogleFonts.tajawal(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  phone.isNotEmpty ? phone : 'لا يوجد رقم',
                  style: GoogleFonts.tajawal(color: Colors.grey),
                ),
                trailing: phone.isNotEmpty
                    ? IconButton(
                        onPressed: () => launchUrlString('tel:$phone'),
                        icon: const Icon(
                          Icons.phone_enabled_rounded,
                          color: Colors.green,
                        ),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.green.withValues(alpha: 0.1),
                        ),
                      )
                    : null,
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildChildCard(Student child, StudentRecord? todayRecord) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.secondaryColor.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: AppTheme.secondaryColor,
                  child: Text(
                    child.name.isNotEmpty ? child.name[0] : 'أ',
                    style: GoogleFonts.tajawal(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        child.name,
                        style: GoogleFonts.tajawal(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'العمر: ${child.age} سنوات',
                        style: GoogleFonts.tajawal(
                          fontSize: 14,
                          color: Theme.of(context).textTheme.bodySmall?.color,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                _buildProgressItem(
                  'المستوى الحالي',
                  'جزء ${child.currentJuz} - سورة ${child.currentSurah} - آية ${child.currentAyah}',
                  Icons.flag_rounded,
                  Colors.orange.shade700,
                ),
                const SizedBox(height: 12),
                if (todayRecord != null) ...[
                  if (todayRecord.attendanceStatus != AttendanceStatus.present)
                    _buildProgressItem(
                      'الحالة اليوم',
                      _getAttendanceLabel(todayRecord.attendanceStatus),
                      Icons.person_off_rounded,
                      AppTheme.errorColor,
                    )
                  else ...[
                    if (todayRecord.hifzFromSurah != null)
                      _buildProgressItem(
                        'حفظ اليوم',
                        '${todayRecord.hifzFromSurah} (${todayRecord.hifzFromAyah}) - ${todayRecord.hifzToSurah} (${todayRecord.hifzToAyah})',
                        Icons.star_rounded,
                        AppTheme.primaryColor,
                      ),
                  ],
                ] else
                  _buildProgressItem(
                    'الحالة اليوم',
                    'لم يتم الرصد بعد',
                    Icons.warning_amber_rounded,
                    Colors.grey,
                  ),
                const Divider(height: 32),
                _buildProgressItem(
                  'حالة اليوم',
                  _getAttendanceText(todayRecord?.attendanceStatus),
                  Icons.event_available_rounded,
                  _getAttendanceColor(todayRecord?.attendanceStatus),
                ),
                if (todayRecord?.notes != null &&
                    todayRecord!.notes!.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.amber.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.amber.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.note_rounded,
                          color: Colors.amber,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'ملاحظة الشيخ: ${todayRecord.notes}',
                            style: GoogleFonts.tajawal(
                              fontSize: 13,
                              color: Colors.amber.shade900,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      final now = DateTime.now();
                      _firestoreService.getStudentRecords(child.id).first.then((
                        records,
                      ) {
                        if (!mounted) return;
                        final monthRecords = records
                            .where(
                              (r) =>
                                  r.date.month == now.month &&
                                  r.date.year == now.year,
                            )
                            .toList();

                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => MonthlyReportDetailScreen(
                              student: child,
                              month: DateTime(now.year, now.month),
                              records: monthRecords,
                            ),
                          ),
                        );
                      });
                    },
                    icon: const Icon(Icons.assessment_outlined),
                    label: Text('التقرير الشهري', style: GoogleFonts.tajawal()),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: const BorderSide(color: AppTheme.secondaryColor),
                      foregroundColor: AppTheme.secondaryColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      if (todayRecord != null) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => DailyReportDetailScreen(
                              student: child,
                              record: todayRecord,
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
                    label: Text('السجل اليومي', style: GoogleFonts.tajawal()),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      backgroundColor: AppTheme.secondaryColor,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
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

  Widget _buildProgressItem(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: GoogleFonts.tajawal(
                fontSize: 12,
                color: Theme.of(context).textTheme.bodySmall?.color,
              ),
            ),
            Text(
              value,
              style: GoogleFonts.tajawal(
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _getAttendanceText(AttendanceStatus? status) {
    if (status == null) return 'لم يتم التحضير بعد';
    switch (status) {
      case AttendanceStatus.present:
        return 'حاضر';
      case AttendanceStatus.absentExcused:
        return 'غائب (بعذر)';
      case AttendanceStatus.absentUnexcused:
        return 'غائب (بدون عذر)';
    }
  }

  Color _getAttendanceColor(AttendanceStatus? status) {
    if (status == null) return Colors.grey;
    switch (status) {
      case AttendanceStatus.present:
        return AppTheme.successColor;
      case AttendanceStatus.absentExcused:
        return Colors.orange;
      case AttendanceStatus.absentUnexcused:
        return AppTheme.errorColor;
    }
  }
}
