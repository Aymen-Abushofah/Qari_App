import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';
import '../../services/firestore_service.dart';
import '../../services/firebase_auth_service.dart';
import '../../widgets/common/error_card.dart';

/// ManageUsersScreen: An administrative interface for Sheikhs to manage other system users.
///
/// Features:
/// 1. Tabbed Navigation: Switch between 'Parents' and 'Sheikhs' lists.
/// 2. Stream-based Display: Real-time updates as users are added or removed.
/// 3. Secure Deletion: Includes a confirmation dialog and triggers cascade deletion in Firestore.
class ManageUsersScreen extends StatefulWidget {
  const ManageUsersScreen({super.key});

  @override
  State<ManageUsersScreen> createState() => _ManageUsersScreenState();
}

class _ManageUsersScreenState extends State<ManageUsersScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _firestoreService = FirestoreService();
  final _authService = FirebaseAuthService();
  bool _isAdmin = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _checkAdminStatus();
  }

  Future<void> _checkAdminStatus() async {
    final uid = _authService.currentUser?.uid;
    if (uid != null) {
      final doc = await _firestoreService.getUserData(uid);
      if (mounted) {
        setState(() {
          _isAdmin = doc.get('isAdmin') == true;
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// Triggers the deletion of a user and all their associated data from Firestore.
  /// Shows a success or error SnackBar upon completion.
  Future<void> _deleteUser(String uid, String role) async {
    try {
      await _firestoreService.deleteUserWithData(uid, role);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'تم حذف ${role == 'parent' ? 'ولي الأمر' : 'الشيخ'} وجميع البيانات المرتبطة',
              style: GoogleFonts.tajawal(),
            ),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('حدث خطأ أثناء الحذف', style: GoogleFonts.tajawal()),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (!_isAdmin) {
      return Scaffold(
        appBar: AppBar(
          title: Text(
            'تحذير الوصول',
            style: GoogleFonts.tajawal(fontWeight: FontWeight.bold),
          ),
          backgroundColor: Colors.red,
          foregroundColor: Colors.white,
          centerTitle: true,
        ),
        body: ErrorCard(
          title: 'عذراً، هذا القسم للمشرفين فقط',
          message:
              'لا تملك صلاحيات كافية لعرض صفحة إدارة المستخدمين. يرجى التواصل مع المدير إذا كنت تعتقد أن هذا خطأ.',
          icon: Icons.lock_person_rounded,
          actions: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back_rounded),
                label: Text(
                  'العودة للرئيسية',
                  style: GoogleFonts.tajawal(fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'إدارة المستخدمين',
          style: GoogleFonts.tajawal(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelStyle: GoogleFonts.tajawal(fontWeight: FontWeight.bold),
          tabs: const [
            Tab(text: 'أولياء الأمور'),
            Tab(text: 'الشيوخ'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildParentsList(), _buildSheikhsList()],
      ),
    );
  }

  /// Fetches and builds a list of parent users from Firestore.
  Widget _buildParentsList() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _firestoreService.getParents(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final parents = snapshot.data ?? [];
        if (parents.isEmpty) {
          return Center(
            child: Text(
              'لا يوجد أولياء أمور',
              style: GoogleFonts.tajawal(
                color: Theme.of(context).textTheme.bodySmall?.color,
              ),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: parents.length,
          itemBuilder: (context, index) {
            final parent = parents[index];
            return _buildUserCard(
              name: parent['name'] ?? 'بدون اسم',
              subtitle: parent['phone'] ?? '',
              icon: Icons.family_restroom,
              color: Colors.orange,
              onDelete: () => _deleteUser(parent['uid'] ?? '', 'parent'),
            );
          },
        );
      },
    );
  }

  /// Fetches and builds a list of sheikh users from Firestore.
  Widget _buildSheikhsList() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _firestoreService.getSheikhs(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final sheikhs = snapshot.data ?? [];
        if (sheikhs.isEmpty) {
          return Center(
            child: Text(
              'لا يوجد شيوخ',
              style: GoogleFonts.tajawal(
                color: Theme.of(context).textTheme.bodySmall?.color,
              ),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: sheikhs.length,
          itemBuilder: (context, index) {
            final sheikh = sheikhs[index];
            return _buildUserCard(
              name: sheikh['name'] ?? 'بدون اسم',
              subtitle: 'معلم',
              icon: Icons.mosque,
              color: AppTheme.primaryColor,
              onDelete: () => _deleteUser(sheikh['uid'] ?? '', 'sheikh'),
            );
          },
        );
      },
    );
  }

  /// Builds a unified card representation for any user type.
  /// Includes user details and a delete button with a confirmation dialog.
  Widget _buildUserCard({
    required String name,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onDelete,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
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
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: GoogleFonts.tajawal(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Theme.of(context).textTheme.titleSmall?.color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: GoogleFonts.tajawal(
                    fontSize: 12,
                    color: Theme.of(context).textTheme.bodySmall?.color,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text(
                    'تأكيد الحذف',
                    style: GoogleFonts.tajawal(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).textTheme.titleLarge?.color,
                    ),
                  ),
                  content: Text(
                    'هل أنت متأكد من حذف هذا المستخدم؟',
                    style: GoogleFonts.tajawal(
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        'إلغاء',
                        style: GoogleFonts.tajawal(color: Colors.grey),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        onDelete();
                      },
                      child: Text(
                        'حذف',
                        style: GoogleFonts.tajawal(color: AppTheme.errorColor),
                      ),
                    ),
                  ],
                ),
              );
            },
            icon: const Icon(Icons.delete_outline_rounded),
            color: AppTheme.errorColor,
            tooltip: 'حذف',
          ),
        ],
      ),
    );
  }
}
