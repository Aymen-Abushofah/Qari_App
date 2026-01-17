import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_theme.dart';
import '../../core/constants/app_strings.dart';
import '../../services/firebase_auth_service.dart';
import '../../services/firestore_service.dart';
import '../user_selection/user_selection_screen.dart';
import 'students_display_screen.dart';
import 'students_management_screen.dart';
import 'reports_screen.dart';
import 'parents_list_screen.dart';
import 'requests_screen.dart';
import 'settings_screen.dart';
import 'manage_users_screen.dart';
import 'permissions_screen.dart';

import 'package:rxdart/rxdart.dart';
import '../../models/student.dart';
import '../../models/student_record.dart';

/// SheikhDashboardScreen: The central hub for the Sheikh persona.
///
/// Key Capabilities:
/// 1. Real-time Oversight: Displays live stats for student attendance and hifz progress.
/// 2. Role-Based Navigation: Unlocks "Admin" features (Requests, Permissions) if the user has isAdmin privileges.
/// 3. Modular Interface: Uses an IndexedStack to switch between Dashboard, Student List, Management, and Reports without losing state.
/// 4. Session Control: Provides logout and profile management via a custom Drawer.
class SheikhDashboardScreen extends StatefulWidget {
  const SheikhDashboardScreen({super.key});

  @override
  State<SheikhDashboardScreen> createState() => _SheikhDashboardScreenState();
}

class _SheikhDashboardScreenState extends State<SheikhDashboardScreen> {
  int _currentIndex = 0;
  final _authService = FirebaseAuthService();
  final _firestoreService = FirestoreService();

  /// Cached user data to check for admin status and display name.
  Map<String, dynamic>? _userData;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  /// Fetches private user metadata from Firestore to determine permissions.
  Future<void> _loadUserData() async {
    try {
      final uid = _authService.currentUser?.uid;
      if (uid != null) {
        final doc = await _firestoreService.getUserData(uid);
        if (doc.exists && mounted) {
          setState(() {
            _userData = doc.data() as Map<String, dynamic>?;
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading user data: $e');
    }
  }

  /// Terminates the current session and forces navigation back to the entry screen.
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
      drawer: Drawer(
        child: Column(
          children: [
            UserAccountsDrawerHeader(
              decoration: BoxDecoration(gradient: AppTheme.primaryGradient),
              currentAccountPicture: CircleAvatar(
                backgroundColor: Colors.white,
                child: Icon(
                  Icons.mosque_rounded,
                  size: 40,
                  color: AppTheme.primaryColor,
                ),
              ),
              accountName: Text(
                _authService.currentUser?.displayName ?? AppStrings.sheikh,
                style: GoogleFonts.tajawal(fontWeight: FontWeight.bold),
              ),
              accountEmail: Text(
                _authService.currentUser?.email ?? '',
                style: GoogleFonts.tajawal(),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.dashboard_rounded),
              title: Text('الرئيسية', style: GoogleFonts.tajawal()),
              onTap: () {
                Navigator.pop(context);
                setState(() => _currentIndex = 0);
              },
            ),
            if (_userData?['isAdmin'] == true) ...[
              const Divider(),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Text(
                  'إدارة النظام',
                  style: GoogleFonts.tajawal(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.person_add_rounded),
                title: Text(AppStrings.requests, style: GoogleFonts.tajawal()),
                trailing: StreamBuilder<int>(
                  stream: _firestoreService.getAllPendingRequestsCount(),
                  builder: (context, snapshot) {
                    final count = snapshot.data ?? 0;
                    if (count == 0) return const SizedBox.shrink();
                    return Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '$count',
                        style: GoogleFonts.tajawal(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    );
                  },
                ),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const RequestsScreen()),
                  ).then((_) => setState(() {}));
                },
              ),
              ListTile(
                leading: const Icon(Icons.manage_accounts_rounded),
                title: Text('إدارة المستخدمين', style: GoogleFonts.tajawal()),
                subtitle: Text(
                  'الشيوخ وأولياء الأمور',
                  style: GoogleFonts.tajawal(
                    fontSize: 10,
                    color: Theme.of(context).textTheme.bodySmall?.color,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ManageUsersScreen(),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.security_rounded),
                title: Text('الصلاحيات', style: GoogleFonts.tajawal()),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const PermissionsScreen(),
                    ),
                  );
                },
              ),
            ],
            ListTile(
              leading: const Icon(Icons.settings_rounded),
              title: Text('الإعدادات', style: GoogleFonts.tajawal()),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SettingsScreen()),
                );
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout_rounded, color: Colors.red),
              title: Text(
                AppStrings.logout,
                style: GoogleFonts.tajawal(color: Colors.red),
              ),
              onTap: _handleLogout,
            ),
          ],
        ),
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _buildHomeScreen(),
          const StudentsDisplayScreen(),
          const StudentsManagementScreen(),
          const ReportsScreen(),
          ParentsListScreen(),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(0, Icons.home_rounded, AppStrings.dashboard),
                _buildNavItem(1, Icons.people_rounded, AppStrings.students),
                _buildNavItem(2, Icons.settings_rounded, AppStrings.management),
                _buildNavItem(3, Icons.assessment_rounded, AppStrings.reports),
                _buildNavItem(4, Icons.family_restroom_rounded, 'الأهل'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = _currentIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(
          horizontal: isSelected ? 16 : 12,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primaryColor.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected
                  ? AppTheme.primaryColor
                  : Theme.of(context).unselectedWidgetColor,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.tajawal(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected
                    ? AppTheme.primaryColor
                    : Theme.of(context).unselectedWidgetColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHomeScreen() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppTheme.primaryColor, AppTheme.primaryLight],
          stops: const [0.0, 0.3],
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Row(
                children: [
                  // Menu Button (opens drawer)
                  Builder(
                    builder: (context) => IconButton(
                      onPressed: () => Scaffold.of(context).openDrawer(),
                      icon: const Icon(
                        Icons.menu_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                      tooltip: 'القائمة',
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _userData?['name'] ?? AppStrings.sheikh,
                          style: GoogleFonts.amiri(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () {},
                    icon: const Icon(
                      Icons.notifications_none_rounded,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            // Stats Cards
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(
                    20,
                    20,
                    20,
                    100,
                  ), // Added bottom padding
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppStrings.todayStats,
                        style: GoogleFonts.tajawal(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).textTheme.titleLarge?.color,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildStatsGrid(),
                      const SizedBox(height: 24),
                      _buildQuickActions(),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Stat Calculations:
  /// Combines student definitions with today's records to compute:
  /// - Total Student Count.
  /// - Attendance Ratio (Present/Absent).
  /// - Total Hifz Submissions.
  Widget _buildStatsGrid() {
    // We use a StreamBuilder to reactively update tiles when a Sheikh
    // submits a record in the StudentDetailScreen.

    return StreamBuilder<Map<String, int>>(
      stream:
          CombineLatestStream.list([
            _firestoreService.getAllStudents().asBroadcastStream(),
            _firestoreService
                .getRecordsForDate(DateTime.now())
                .asBroadcastStream(),
          ]).map((list) {
            final students = list[0] as List<Student>;
            final todayRecords = list[1] as List<StudentRecord>;

            final studentIds = students.map((s) => s.id).toSet();
            final relevantTodayRecords = todayRecords
                .where((r) => studentIds.contains(r.studentId))
                .toList();

            final presentCount = relevantTodayRecords
                .where((r) => r.attendanceStatus == AttendanceStatus.present)
                .length;

            final absentCount = relevantTodayRecords
                .where((r) => r.attendanceStatus != AttendanceStatus.present)
                .length;

            return {
              'totalStudents': students.length,
              'present': presentCount,
              'absent': absentCount,
              'totalRecords': relevantTodayRecords
                  .where((r) => r.hasHifz)
                  .length,
            };
          }).asBroadcastStream(),
      builder: (context, snapshot) {
        final stats =
            snapshot.data ??
            {'totalStudents': 0, 'present': 0, 'absent': 0, 'totalRecords': 0};

        return GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 1.2,
          children: [
            _buildStatCard(
              AppStrings.totalStudents,
              '${stats['totalStudents']}',
              Icons.people_rounded,
              AppTheme.primaryColor,
            ),
            _buildStatCard(
              AppStrings.presentToday,
              '${stats['present']}',
              Icons.check_circle_rounded,
              AppTheme.successColor,
            ),
            _buildStatCard(
              AppStrings.absentToday,
              '${stats['absent']}',
              Icons.cancel_rounded,
              AppTheme.errorColor,
            ),
            _buildStatCard(
              AppStrings.completedHifz,
              '${stats['totalRecords']}',
              Icons.auto_stories_rounded,
              AppTheme.secondaryColor,
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.1),
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
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 12),
              Text(
                value,
                style: GoogleFonts.tajawal(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).textTheme.headlineMedium?.color,
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            title,
            style: GoogleFonts.tajawal(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Theme.of(context).textTheme.bodyMedium?.color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'إجراءات سريعة',
          style: GoogleFonts.tajawal(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).textTheme.titleLarge?.color,
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            SizedBox(
              width: (MediaQuery.of(context).size.width - 52) / 2,
              child: _buildActionButton(
                'بدء الحلقة',
                Icons.play_circle_rounded,
                AppTheme.primaryColor,
                () => setState(() => _currentIndex = 1),
              ),
            ),
            if (_userData?['isAdmin'] == true)
              SizedBox(
                width: (MediaQuery.of(context).size.width - 52) / 2,
                child: _buildActionButton(
                  AppStrings.requests,
                  Icons.person_add_rounded,
                  AppTheme.secondaryColor,
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const RequestsScreen()),
                  ).then((_) => setState(() {})),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButton(
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color, color.withValues(alpha: 0.8)],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.3),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.tajawal(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
