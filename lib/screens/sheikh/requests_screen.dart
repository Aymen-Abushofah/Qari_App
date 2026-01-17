import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/theme/app_theme.dart';
import '../../services/firebase_auth_service.dart';
import '../../services/firestore_service.dart';
import '../../models/student.dart';

import '../../widgets/common/error_card.dart';

class RequestsScreen extends StatefulWidget {
  const RequestsScreen({super.key});

  @override
  State<RequestsScreen> createState() => _RequestsScreenState();
}

class _RequestsScreenState extends State<RequestsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _firestoreService = FirestoreService();
  final _authService = FirebaseAuthService();
  bool _isAdmin = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
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
              'لا تملك صلاحيات كافية لعرض صفحة إدارة الطلبات. يرجى التواصل مع المدير إذا كنت تعتقد أن هذا خطأ.',
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
          'إدارة الطلبات',
          style: GoogleFonts.tajawal(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelStyle: GoogleFonts.tajawal(fontWeight: FontWeight.bold),
          tabs: const [
            Tab(text: 'الطلاب'),
            Tab(text: 'أولياء الأمور'),
            Tab(text: 'الشيوخ'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildRequestTab('student'),
          _buildRequestTab('parent'),
          _buildRequestTab('sheikh'),
        ],
      ),
    );
  }

  Widget _buildRequestTab(String type) {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestoreService.getRequestsByType(type),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return _buildEmptyState('حدث خطأ في تحميل البيانات');
        }

        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          String message = 'لا توجد طلبات';
          if (type == 'student') message = 'لا توجد طلبات طلاب';
          if (type == 'parent') message = 'لا توجد طلبات أولياء أمور';
          if (type == 'sheikh') message = 'لا توجد طلبات شيوخ';
          return _buildEmptyState(message);
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final doc = docs[index];
            final data = doc.data() as Map<String, dynamic>;
            final requestId = doc.id;
            final uid = data['uid'] ?? '';

            return _buildRequestCard(
              title: data['name'] ?? 'بدون اسم',
              subtitle: _getSubtitleForType(type, data),
              icon: _getIconForType(type),
              color: _getColorForType(type),
              onAccept: () async {
                try {
                  // Approval logic:
                  // 1. Update user approved status
                  if (uid.isNotEmpty) {
                    await _firestoreService.approveUser(uid);

                    // 1b. If student, create student profile for current Sheikh
                    if (type == 'student') {
                      final currentSheikhId = _authService.currentUser?.uid;
                      if (currentSheikhId != null) {
                        final student = Student(
                          id: uid,
                          name: data['name'] ?? 'بدون اسم',
                          age: data['age'] ?? 0,
                          sheikhId: currentSheikhId,
                          enrollmentDate: DateTime.now(),
                          notes: 'تمت الموافقة من قِبل المشرف',
                        );
                        // Save student document using service
                        await _firestoreService.createStudent(student);
                      }
                    }
                  }
                  // 2. Mark request as accepted
                  await _firestoreService.updateRequestStatus(
                    requestId,
                    'accepted',
                  );
                  _showSnackBar('تم قبول الطلب بنجاح');
                } catch (e) {
                  _showSnackBar('حدث خطأ: $e', isError: true);
                }
              },
              onReject: () async {
                try {
                  // 1. Update request status in 'requests' collection
                  await _firestoreService.updateRequestStatus(
                    requestId,
                    'rejected',
                  );

                  // 2. Mark user as rejected in 'users' collection so they see the notification
                  if (uid.isNotEmpty) {
                    await _firestoreService.rejectUser(uid);
                  }

                  _showSnackBar('تم رفض الطلب', isError: true);
                } catch (e) {
                  _showSnackBar('حدث خطأ: $e', isError: true);
                }
              },
            );
          },
        );
      },
    );
  }

  String _getSubtitleForType(String type, Map<String, dynamic> data) {
    if (type == 'student') {
      return 'الهاتف: ${data['phone'] ?? 'غير متوفر'}';
    } else if (type == 'parent') {
      return 'الهاتف: ${data['phone'] ?? 'غير متوفر'}\nالبريد: ${data['email'] ?? 'غير متوفر'}';
    } else {
      return 'الهاتف: ${data['phone'] ?? 'غير متوفر'}\nالبريد: ${data['email'] ?? 'غير متوفر'}';
    }
  }

  IconData _getIconForType(String type) {
    if (type == 'student') return Icons.person;
    if (type == 'parent') return Icons.family_restroom;
    return Icons.mosque;
  }

  Color _getColorForType(String type) {
    if (type == 'student') return Colors.teal;
    if (type == 'parent') return Colors.orange;
    return AppTheme.primaryColor;
  }

  Widget _buildRequestCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onAccept,
    required VoidCallback onReject,
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
                  title,
                  style: GoogleFonts.tajawal(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: GoogleFonts.tajawal(
                    fontSize: 12,
                    color: Theme.of(context).textTheme.bodySmall?.color,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          Column(
            children: [
              IconButton(
                onPressed: onAccept,
                icon: const Icon(Icons.check_circle_rounded),
                color: AppTheme.successColor,
                tooltip: 'قبول',
              ),
              IconButton(
                onPressed: onReject,
                icon: const Icon(Icons.cancel_rounded),
                color: AppTheme.errorColor,
                tooltip: 'رفض',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox_rounded, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            message,
            style: GoogleFonts.tajawal(
              fontSize: 16,
              color: Theme.of(context).textTheme.bodySmall?.color,
            ),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.tajawal()),
        backgroundColor: isError ? AppTheme.errorColor : AppTheme.successColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}
