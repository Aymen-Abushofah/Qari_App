import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/app_strings.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import 'package:firebase_core/firebase_core.dart';
import '../user_selection/user_selection_screen.dart';
import '../sheikh/sheikh_dashboard_screen.dart';
import '../common/waiting_approval_screen.dart';
import '../parent/parent_dashboard_screen.dart';
import '../student/student_dashboard_screen.dart';
import '../../services/firebase_auth_service.dart';
import '../../services/firestore_service.dart';

/// AuthScreen: A unified screen for Login and Signup.
///
/// Key Features:
/// 1. Persona-based UI: Adjusts colors and text based on [UserType].
/// 2. Automated Admin Grant: The FIRST sheikh to sign up automatically becomes an Admin and is pre-approved.
/// 3. Join Requests: New students/parents are added to a 'requests' collection for Admin review.
/// 4. Recovery Logic: If a user signs up with an existing email but correct credentials,
///    the app attempts to recover their profile rather than erroring.
class AuthScreen extends StatefulWidget {
  final UserType userType;

  const AuthScreen({super.key, required this.userType});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _loginFormKey = GlobalKey<FormState>();
  final _signupFormKey = GlobalKey<FormState>();
  final _authService = FirebaseAuthService();
  final _firestoreService = FirestoreService();

  // --- Controllers ---
  final _loginEmailController = TextEditingController();
  final _loginPasswordController = TextEditingController();
  final _signupNameController = TextEditingController();
  final _signupEmailController = TextEditingController();
  final _signupPhoneController = TextEditingController();
  final _signupAgeController = TextEditingController();
  final _signupPasswordController = TextEditingController();
  final _signupConfirmPasswordController = TextEditingController();

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _loginEmailController.dispose();
    _loginPasswordController.dispose();
    _signupNameController.dispose();
    _signupEmailController.dispose();
    _signupPhoneController.dispose();
    _signupAgeController.dispose();
    _signupPasswordController.dispose();
    _signupConfirmPasswordController.dispose();
    super.dispose();
  }

  // --- UI Helpers ---
  String get _userTypeTitle {
    switch (widget.userType) {
      case UserType.sheikh:
        return AppStrings.sheikh;
      case UserType.student:
        return AppStrings.student;
      case UserType.parent:
        return AppStrings.parent;
    }
  }

  IconData get _userTypeIcon {
    switch (widget.userType) {
      case UserType.sheikh:
        return Icons.mosque_rounded;
      case UserType.student:
        return Icons.person_rounded;
      case UserType.parent:
        return Icons.family_restroom_rounded;
    }
  }

  Color get _primaryColorForUser {
    switch (widget.userType) {
      case UserType.sheikh:
        return AppTheme.primaryColor;
      case UserType.student:
        return Colors.teal;
      case UserType.parent:
        return AppTheme.secondaryColor;
    }
  }

  // --- Navigation Logic ---

  /// Directs the user to their respective dashboard.
  /// If not approved, redirects to the under-review state.
  void _navigateToDashboard([bool isApproved = true]) {
    final userType = widget.userType;

    // Students and Parents MUST be approved before accessing the dashboard.
    if (!isApproved && userType != UserType.sheikh) {
      _showUnderReviewDialog();
      return;
    }

    if (userType == UserType.sheikh) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const SheikhDashboardScreen()),
        (route) => false,
      );
    } else if (userType == UserType.student) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const StudentDashboardScreen()),
        (route) => false,
      );
    } else {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const ParentDashboardScreen()),
        (route) => false,
      );
    }
  }

  /// Displays an informative dialog for users whose accounts are pending admin approval.
  void _showUnderReviewDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'قيد المراجعة',
          style: GoogleFonts.tajawal(fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.hourglass_empty_rounded,
              size: 64,
              color: Colors.orange,
            ),
            const SizedBox(height: 16),
            Text(
              'حسابك قيد المراجعة حالياً من قبل الإدارة. ستتمكن من تسجيل الدخول بمجرد الموافقة على طلبك.',
              style: GoogleFonts.tajawal(),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'حسناً',
              style: GoogleFonts.tajawal(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  /// Entry point for Login submission.
  void _handleLogin() async {
    if (_loginFormKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        final error = await _authService.login(
          _loginEmailController.text,
          _loginPasswordController.text,
        );

        if (mounted) {
          if (error != null) {
            setState(() => _isLoading = false);
            _showError(error);
          } else {
            // After successful auth, verify persona and approval status in Firestore.
            final userDataDoc = await _firestoreService.getUserData(
              _authService.currentUser!.uid,
            );

            if (!userDataDoc.exists) {
              setState(() => _isLoading = false);
              _showError('بيانات المستخدم غير موجودة');
              return;
            }

            final userData = userDataDoc.data() as Map<String, dynamic>;
            final String? typeStr = userData['type'];
            final bool isApproved = userData['isApproved'] ?? false;
            final bool isRejected = userData['isRejected'] ?? false;

            // Verify the user is logging into the correct portal (e.g., Parent portal vs Student account).
            String expectedType = widget.userType.name;
            if (typeStr != expectedType) {
              setState(() => _isLoading = false);
              _showError('نوع المستخدم لا يتطابق مع الحساب المسجل');
              return;
            }

            setState(() => _isLoading = false);

            if (isApproved) {
              _navigateToDashboard(isApproved);
            } else if (isRejected) {
              // Send to WaitingApprovalScreen which handles the rejection message
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(
                  builder: (_) => const WaitingApprovalScreen(),
                ),
                (route) => false,
              );
            } else {
              // Still pending approval
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(
                  builder: (_) => const WaitingApprovalScreen(),
                ),
                (route) => false,
              );
            }
          }
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isLoading = false);
          _showError('حدث خطأ أثناء تسجيل الدخول: $e');
        }
      }
    }
  }

  /// Entry point for Signup submission.
  /// Handles Auth creation -> Profile creation -> Join Request creation.
  void _handleSignup() async {
    if (!_signupFormKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // --- 1. Create the Auth Account ---
      final signupError = await _authService.signup(
        email: _signupEmailController.text.trim(),
        password: _signupPasswordController.text,
      );

      String? error = signupError;
      bool isRecovery = false;

      // Handle "Email already in use" by trying to sign in (Profile recovery flow).
      if (error != null &&
          (error.contains('already in use') ||
              error.contains('email-already-in-use'))) {
        error = await _authService.login(
          _signupEmailController.text.trim(),
          _signupPasswordController.text,
        );
        if (error == null) isRecovery = true;
      }

      if (!mounted) return;

      if (error != null) {
        setState(() => _isLoading = false);
        _showError(error);
        return;
      }

      // --- 2. Create/Update Profile in Firestore ---
      final user = _authService.currentUser;
      if (user == null) throw 'فشل الربط مع نظام التحقق';
      final uid = user.uid;

      try {
        // Step A: Recovery check
        final existingDoc = await _firestoreService
            .getUserData(uid)
            .timeout(
              const Duration(seconds: 8),
              onTimeout: () => throw 'انتهت مهلة الاتصال بقاعدة البيانات',
            );

        if (existingDoc.exists && isRecovery) {
          final data = existingDoc.data() as Map<String, dynamic>?;
          _handleNavigationAfterSignup(uid, data?['isAdmin'] ?? false);
          return;
        }

        // Step B: Bootstrapping check
        // If this is the very first Sheikh, they get Admin + instant Approval.
        bool isFirstSheikh = false;
        if (widget.userType == UserType.sheikh) {
          try {
            isFirstSheikh = !(await _firestoreService.hasAnySheikhs());
          } catch (e) {
            debugPrint('Security Warning: $e');
            isFirstSheikh = false;
          }
        }

        // Step C: Persistence
        await _firestoreService.createUserDocument(uid, {
          'uid': uid,
          'name': _signupNameController.text.trim(),
          'email': _signupEmailController.text.trim(),
          'phone': _signupPhoneController.text.trim(),
          'type': widget.userType.name,
          'isApproved': isFirstSheikh,
          'isAdmin': isFirstSheikh,
          'createdAt': DateTime.now().toIso8601String(),
        });

        // Step D: Join Request (only for non-bootstrapped users)
        if (!isFirstSheikh) {
          final Map<String, dynamic> requestData = {
            'uid': uid,
            'name': _signupNameController.text.trim(),
            'phone': _signupPhoneController.text.trim(),
            'email': _signupEmailController.text.trim(),
          };

          if (widget.userType == UserType.student) {
            requestData['age'] = int.tryParse(_signupAgeController.text) ?? 0;
          }

          await _firestoreService
              .addJoinRequest(widget.userType.name, requestData)
              .catchError((e) => debugPrint('Non-fatal join error: $e'));
        }

        _handleNavigationAfterSignup(uid, isFirstSheikh);
      } catch (dbError) {
        debugPrint('DB CRASH: $dbError');
        // Critical: Logout on DB failure so user isn't stuck with valid auth but no profile.
        await _authService.logout();
        throw _cleanFirebaseError(dbError);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showError(e.toString());
      }
    }
  }

  /// Displays normalized errors to the user.
  void _showError(String message) {
    if (!mounted) return;

    final cleanedMessage = _cleanFirebaseError(message);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(cleanedMessage, style: GoogleFonts.tajawal()),
        backgroundColor: AppTheme.errorColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  /// Strips technical jargon from Firebase/Firestore exceptions to produce human-readable Arabic.
  String _cleanFirebaseError(dynamic e) {
    String msg = e.toString();
    if (e is FirebaseException) {
      msg = '[${e.code}] ${e.message ?? ''}';
    }

    return msg
        .replaceAll(RegExp(r'Firestore \(\d+\.\d+\.\d+\):?'), '')
        .replaceAll('Exception: ', '')
        .replaceAll('[cloud_firestore/', '[')
        .replaceAll('خطأ: ', '')
        .trim();
  }

  /// Handles redirects after a successful profile creation or recovery.
  void _handleNavigationAfterSignup(String uid, bool isFirstSheikh) {
    if (mounted) {
      setState(() => _isLoading = false);
      if (isFirstSheikh) {
        _navigateToDashboard(true);
      } else {
        // Standard users go to the "Please Wait" screen.
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const WaitingApprovalScreen()),
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).scaffoldBackgroundColor,
              Theme.of(context).cardColor,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // --- Header with Back Button ---
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(
                        Icons.arrow_forward_ios_rounded,
                        color: Theme.of(context).iconTheme.color,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      width: 45,
                      height: 45,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            _primaryColorForUser,
                            _primaryColorForUser.withValues(alpha: 0.7),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(_userTypeIcon, color: Colors.white, size: 24),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // User type title
              Text(
                _userTypeTitle,
                style: GoogleFonts.amiri(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: _primaryColorForUser,
                ),
              ),
              const SizedBox(height: 24),
              // --- Mode Switcher (Tab Bar) ---
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 40),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicator: BoxDecoration(
                    color: _primaryColorForUser,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  dividerColor: Colors.transparent,
                  indicatorSize: TabBarIndicatorSize.tab,
                  labelColor: Colors.white,
                  unselectedLabelColor: Theme.of(context).unselectedWidgetColor,
                  labelStyle: GoogleFonts.tajawal(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  unselectedLabelStyle: GoogleFonts.tajawal(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  tabs: [
                    Tab(text: AppStrings.login),
                    Tab(text: AppStrings.signup),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // --- Form Content ---
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [_buildLoginForm(), _buildSignupForm()],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Builds the login interface.
  Widget _buildLoginForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Form(
        key: _loginFormKey,
        child: Column(
          children: [
            const SizedBox(height: 20),
            CustomTextField(
              hintText: AppStrings.email,
              labelText: AppStrings.email,
              controller: _loginEmailController,
              keyboardType: TextInputType.emailAddress,
              prefixIcon: Icons.email_rounded,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return AppStrings.requiredField;
                }
                if (!value.contains('@')) {
                  return AppStrings.invalidEmail;
                }
                return null;
              },
            ),
            const SizedBox(height: 20),
            CustomTextField(
              hintText: AppStrings.password,
              labelText: AppStrings.password,
              controller: _loginPasswordController,
              obscureText: true,
              prefixIcon: Icons.lock_rounded,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return AppStrings.requiredField;
                }
                if (value.length < 6) {
                  return AppStrings.passwordTooShort;
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {},
                child: Text(
                  AppStrings.forgotPassword,
                  style: GoogleFonts.tajawal(
                    color: _primaryColorForUser,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            CustomButton(
              text: AppStrings.loginButton,
              onPressed: _handleLogin,
              isLoading: _isLoading,
              icon: Icons.login_rounded,
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  AppStrings.dontHaveAccount,
                  style: GoogleFonts.tajawal(color: AppTheme.textSecondary),
                ),
                TextButton(
                  onPressed: () {
                    _tabController.animateTo(1);
                  },
                  child: Text(
                    AppStrings.signup,
                    style: GoogleFonts.tajawal(
                      color: _primaryColorForUser,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  /// Builds the registration interface.
  Widget _buildSignupForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Form(
        key: _signupFormKey,
        child: Column(
          children: [
            const SizedBox(height: 20),
            CustomTextField(
              hintText: AppStrings.fullName,
              labelText: AppStrings.fullName,
              controller: _signupNameController,
              prefixIcon: Icons.person_rounded,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return AppStrings.requiredField;
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            CustomTextField(
              hintText: AppStrings.email,
              labelText: AppStrings.email,
              controller: _signupEmailController,
              keyboardType: TextInputType.emailAddress,
              prefixIcon: Icons.email_rounded,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return AppStrings.requiredField;
                }
                if (!value.contains('@')) {
                  return AppStrings.invalidEmail;
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            CustomTextField(
              hintText: AppStrings.phone,
              labelText: AppStrings.phone,
              controller: _signupPhoneController,
              keyboardType: TextInputType.phone,
              prefixIcon: Icons.phone_rounded,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return AppStrings.requiredField;
                }
                return null;
              },
            ),
            if (widget.userType == UserType.student) ...[
              const SizedBox(height: 16),
              CustomTextField(
                hintText: AppStrings.studentAge,
                labelText: AppStrings.studentAge,
                controller: _signupAgeController,
                keyboardType: TextInputType.number,
                prefixIcon: Icons.cake,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return AppStrings.requiredField;
                  }
                  if (int.tryParse(value) == null) {
                    return 'يرجى إدخال رقم صحيح';
                  }
                  return null;
                },
              ),
            ],
            const SizedBox(height: 16),
            CustomTextField(
              hintText: AppStrings.password,
              labelText: AppStrings.password,
              controller: _signupPasswordController,
              obscureText: true,
              prefixIcon: Icons.lock_rounded,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return AppStrings.requiredField;
                }
                if (value.length < 6) {
                  return AppStrings.passwordTooShort;
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            CustomTextField(
              hintText: AppStrings.confirmPassword,
              labelText: AppStrings.confirmPassword,
              controller: _signupConfirmPasswordController,
              obscureText: true,
              prefixIcon: Icons.lock_rounded,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return AppStrings.requiredField;
                }
                if (value != _signupPasswordController.text) {
                  return AppStrings.passwordsNotMatch;
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            CustomButton(
              text: AppStrings.signupButton,
              onPressed: _handleSignup,
              isLoading: _isLoading,
              icon: Icons.person_add_rounded,
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  AppStrings.alreadyHaveAccount,
                  style: GoogleFonts.tajawal(color: AppTheme.textSecondary),
                ),
                TextButton(
                  onPressed: () {
                    _tabController.animateTo(0);
                  },
                  child: Text(
                    AppStrings.login,
                    style: GoogleFonts.tajawal(
                      color: _primaryColorForUser,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
