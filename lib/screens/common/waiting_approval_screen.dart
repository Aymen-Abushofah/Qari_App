import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../user_selection/user_selection_screen.dart';
import '../sheikh/sheikh_dashboard_screen.dart';
import '../parent/parent_dashboard_screen.dart';
import '../student/student_dashboard_screen.dart';
import '../../services/firebase_auth_service.dart';
import '../../services/firestore_service.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/common/error_card.dart';

class WaitingApprovalScreen extends StatefulWidget {
  const WaitingApprovalScreen({super.key});

  @override
  State<WaitingApprovalScreen> createState() => _WaitingApprovalScreenState();
}

class _WaitingApprovalScreenState extends State<WaitingApprovalScreen> {
  final _authService = FirebaseAuthService();
  final _firestoreService = FirestoreService();
  bool _isChecking = false;

  Future<void> _checkStatus() async {
    setState(() => _isChecking = true);

    try {
      final uid = _authService.currentUser?.uid;
      if (uid != null) {
        final doc = await _firestoreService.getUserData(uid);
        if (doc.exists && mounted) {
          final data = doc.data() as Map<String, dynamic>;
          final bool isApproved = data['isApproved'] ?? false;
          final String type = data['type'] ?? '';

          if (isApproved) {
            _navigateToDashboard(type);
            return;
          }
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'ما زال حسابك قيد المراجعة. شكراً لصبرك.',
              style: GoogleFonts.tajawal(),
            ),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        String msg = e.toString();
        if (e is FirebaseException) {
          msg = '[${e.code}] ${e.message ?? ''}';
        }
        msg = msg
            .replaceAll(RegExp(r'Firestore \(\d+\.\d+\.\d+\):?'), '')
            .replaceAll('Exception: ', '')
            .replaceAll('[cloud_firestore/', '[')
            .trim();

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('حدث خطأ: $msg')));
      }
    } finally {
      if (mounted) {
        setState(() => _isChecking = false);
      }
    }
  }

  void _navigateToDashboard(String type) {
    Widget dashboard;
    switch (type) {
      case 'sheikh':
        dashboard = const SheikhDashboardScreen();
        break;
      case 'parent':
        dashboard = const ParentDashboardScreen();
        break;
      case 'student':
        dashboard = const StudentDashboardScreen();
        break;
      default:
        dashboard = const UserSelectionScreen();
    }

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => dashboard),
      (route) => false,
    );
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
    final user = _authService.currentUser;

    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          // If document is missing, it might have been deleted already
          return const UserSelectionScreen();
        }

        final data = snapshot.data!.data() as Map<String, dynamic>;
        final bool isApproved = data['isApproved'] ?? false;
        final bool isRejected = data['isRejected'] ?? false;
        final String type = data['type'] ?? '';

        // Auto-navigate if approved while on this screen
        if (isApproved) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _navigateToDashboard(type);
          });
          // Return an empty container or loading indicator while navigating
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (isRejected) {
          return Scaffold(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            body: ErrorCard(
              title: 'تم رفض طلب الانضمام',
              message:
                  'عذراً، لقد تمت مراجعة طلبك وتم رفضه من قِبل الإدارة. يمكنك حذف بياناتك والمحاولة لاحقاً أو التواصل مع المدير.',
              icon: Icons.person_remove_rounded,
              baseColor: AppTheme.errorColor,
              actions: [
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isChecking
                        ? null
                        : () async {
                            try {
                              setState(() => _isChecking = true);
                              final uid = user.uid;
                              await _firestoreService.deleteRejectedAccount(
                                uid,
                              );
                              await _authService.deleteAccount();

                              if (mounted) {
                                Navigator.of(context).pushAndRemoveUntil(
                                  MaterialPageRoute(
                                    builder: (_) => const UserSelectionScreen(),
                                  ),
                                  (route) => false,
                                );
                              }
                            } catch (e) {
                              if (mounted) {
                                setState(() => _isChecking = false);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Error purging data: $e'),
                                  ),
                                );
                              }
                            }
                          },
                    icon: const Icon(Icons.delete_forever_rounded),
                    label: Text(
                      'فهمت، حذف بياناتي',
                      style: GoogleFonts.tajawal(fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.errorColor,
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
          body: ErrorCard(
            title: 'طلبك قيد المراجعة',
            message:
                'حسابك حالياً قيد المراجعة من قبل الإدارة. يرجى الانتظار حتى تتم الموافقة على طلبك لتتمكن من استخدام التطبيق.',
            icon: Icons.hourglass_empty_rounded,
            baseColor: Colors.orange,
            actions: [
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isChecking ? null : _checkStatus,
                  icon: _isChecking
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.refresh_rounded),
                  label: Text(
                    'تحديث الحالة',
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
              const SizedBox(height: 12),
              TextButton(
                onPressed: _handleLogout,
                child: Text(
                  'تسجيل الخروج',
                  style: GoogleFonts.tajawal(
                    color: AppTheme.errorColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
