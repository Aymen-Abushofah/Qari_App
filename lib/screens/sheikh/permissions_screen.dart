import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';
import '../../services/firestore_service.dart';
import '../../services/firebase_auth_service.dart';
import '../../widgets/common/error_card.dart';

class PermissionsScreen extends StatefulWidget {
  const PermissionsScreen({super.key});

  @override
  State<PermissionsScreen> createState() => _PermissionsScreenState();
}

class _PermissionsScreenState extends State<PermissionsScreen> {
  final _firestoreService = FirestoreService();
  final _authService = FirebaseAuthService();
  bool _isAdmin = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
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
              'لا تملك صلاحيات كافية لعرض صفحة تعديل الأذونات. يرجى التواصل مع المدير إذا كنت تعتقد أن هذا خطأ.',
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

    final currentUid = _authService.currentUser?.uid;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'الصلاحيات',
          style: GoogleFonts.tajawal(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: AppTheme.primaryColor,
        elevation: 0,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _firestoreService.getSheikhs(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final sheikhs = snapshot.data ?? [];

          return RefreshIndicator(
            onRefresh: () async {
              setState(() {});
              await Future.delayed(const Duration(milliseconds: 500));
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: sheikhs.length,
              itemBuilder: (context, index) {
                final sheikh = sheikhs[index];
                final uid = sheikh['uid'] ?? '';
                final isAdmin = sheikh['isAdmin'] == true;
                final name = sheikh['name'] ?? 'بدون اسم';

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: SwitchListTile(
                    value: isAdmin,
                    activeThumbColor: AppTheme.primaryColor,
                    onChanged: uid == currentUid
                        ? null // Prevent self-demotion
                        : (bool value) async {
                            try {
                              await _firestoreService.updateUserAdminStatus(
                                uid,
                                value,
                              );
                              if (!mounted) return;

                              ScaffoldMessenger.of(
                                context,
                              ).hideCurrentSnackBar();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'تم ${value ? "منح" : "سحب"} صلاحية المسؤول من $name',
                                    style: GoogleFonts.tajawal(),
                                  ),
                                  backgroundColor: value
                                      ? AppTheme.successColor
                                      : Colors.grey,
                                  behavior: SnackBarBehavior.floating,
                                  duration: const Duration(seconds: 2),
                                ),
                              );
                            } catch (e) {
                              if (!mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'حدث خطأ أثناء تحديث الصلاحيات',
                                    style: GoogleFonts.tajawal(),
                                  ),
                                  backgroundColor: AppTheme.errorColor,
                                ),
                              );
                            }
                          },
                    title: Text(
                      name,
                      style: GoogleFonts.tajawal(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).textTheme.titleSmall?.color,
                      ),
                    ),
                    subtitle: Text(
                      isAdmin
                          ? 'مسؤول (كامل الصلاحيات)'
                          : 'شيخ (صلاحيات محدودة)',
                      style: GoogleFonts.tajawal(
                        fontSize: 12,
                        color: isAdmin
                            ? AppTheme.primaryColor
                            : Theme.of(context).disabledColor,
                      ),
                    ),
                    secondary: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: (isAdmin ? AppTheme.primaryColor : Colors.grey)
                            .withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.admin_panel_settings_rounded,
                        color: isAdmin
                            ? AppTheme.primaryColor
                            : Theme.of(context).disabledColor,
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
