import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/app_strings.dart';
import '../user_selection/user_selection_screen.dart';
import '../sheikh/sheikh_dashboard_screen.dart';
import '../parent/parent_dashboard_screen.dart';
import '../student/student_dashboard_screen.dart';
import '../common/waiting_approval_screen.dart';
import '../../services/firebase_auth_service.dart';
import '../../services/firestore_service.dart';
import '../common/user_access_guard.dart';

/// SplashScreen: The application entry point.
///
/// Responsibilities:
/// 1. Branding: Displays the app logo and slogan with high-end animations (Fade, Scale).
/// 2. Session Recovery: Automatically audits the existing Firebase session.
/// 3. Intelligent Routing:
///    - If logged in & approved -> Dashboard (wrapped in UserAccessGuard).
///    - If logged in & NOT approved -> WaitingApprovalScreen.
///    - If NOT logged in -> UserSelectionScreen.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _scaleController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _sloganFadeAnimation;

  @override
  void initState() {
    super.initState();

    // --- Animation Setup ---
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeOut));

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
    );

    _sloganFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _fadeController,
        curve: const Interval(0.5, 1.0, curve: Curves.easeOut),
      ),
    );

    _fadeController.forward();
    _scaleController.forward();

    // --- Session Persistence Check ---
    // We delay navigation to ensure the brand logo is visible for at least 3.5s.
    Future.delayed(const Duration(milliseconds: 3500), () async {
      if (!mounted) return;

      final authService = FirebaseAuthService();
      final firestoreService = FirestoreService();

      if (authService.currentUser != null) {
        try {
          // Verify profile exists and check approval status.
          final userDataDoc = await firestoreService.getUserData(
            authService.currentUser!.uid,
          );
          if (userDataDoc.exists) {
            final userData = userDataDoc.data() as Map<String, dynamic>;
            final bool isApproved = userData['isApproved'] ?? false;
            final String type = userData['type'] ?? '';

            if (isApproved) {
              _navigateToDashboard(type);
              return;
            } else {
              _navigateToWaitingApproval();
              return;
            }
          }
        } catch (e) {
          debugPrint('Session recovery error: $e');
        }
      }

      // Default path if no valid session found.
      _navigateToUserSelection();
    });
  }

  /// Redirects to the appropriate portal dashboard based on user type.
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

    // dashboards are wrapped in UserAccessGuard for real-time security (deactivation checks).
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => UserAccessGuard(child: dashboard)),
    );
  }

  void _navigateToWaitingApproval() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const WaitingApprovalScreen()),
    );
  }

  void _navigateToUserSelection() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const UserSelectionScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _scaleController.dispose();
    super.dispose();
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
              AppTheme.primaryColor.withValues(alpha: 0.05),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const Spacer(flex: 2),
              // --- Animated Brand Section ---
              AnimatedBuilder(
                animation: _fadeAnimation,
                builder: (context, child) {
                  return Opacity(
                    opacity: _fadeAnimation.value,
                    child: Transform.scale(
                      scale: _scaleAnimation.value,
                      child: child,
                    ),
                  );
                },
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        gradient: AppTheme.primaryGradient,
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primaryColor.withValues(alpha: 0.3),
                            blurRadius: 30,
                            offset: const Offset(0, 15),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.menu_book_rounded,
                        size: 60,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 32),
                    Text(
                      AppStrings.appName,
                      style: GoogleFonts.amiri(
                        fontSize: 52,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryColor,
                        letterSpacing: 2,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // --- Slogan Section ---
              AnimatedBuilder(
                animation: _sloganFadeAnimation,
                builder: (context, child) {
                  return Opacity(
                    opacity: _sloganFadeAnimation.value,
                    child: Transform.translate(
                      offset: Offset(0, 20 * (1 - _sloganFadeAnimation.value)),
                      child: child,
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                      color: AppTheme.secondaryColor.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    AppStrings.appSlogan,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.tajawal(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ),
              ),
              const Spacer(flex: 3),
              // --- Footer ---
              AnimatedBuilder(
                animation: _fadeAnimation,
                builder: (context, child) {
                  return Opacity(
                    opacity: _fadeAnimation.value * 0.7,
                    child: child,
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: Text(
                    AppStrings.copyright,
                    style: GoogleFonts.tajawal(
                      fontSize: 12,
                      color: AppTheme.textSecondary.withValues(alpha: 0.6),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Helper widget for building animated content
class AnimatedBuilder extends AnimatedWidget {
  final Widget Function(BuildContext, Widget?) builder;
  final Widget? child;

  const AnimatedBuilder({
    super.key,
    required Animation<double> animation,
    required this.builder,
    this.child,
  }) : super(listenable: animation);

  @override
  Widget build(BuildContext context) {
    return builder(context, child);
  }
}
