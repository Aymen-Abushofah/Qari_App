import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';

/// FirebaseErrorScreen: A fatal-error fallback screen shown when Firebase fails to initialize.
///
/// Used mainly during the app's startup phase (`main.dart`) to catch:
/// 1. Missing `firebase_options.dart` configs.
/// 2. Lack of internet during the very first boot.
/// 3. Project configuration mismatches.
import '../../widgets/common/error_card.dart';

class FirebaseErrorScreen extends StatelessWidget {
  final Object error;

  const FirebaseErrorScreen({super.key, required this.error});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ErrorCard(
              title: 'خطأ في إعداد قاعدة البيانات',
              message:
                  'يرجى نسخ "Config" من إعدادات Firebase في المتصفح وإرسالها لي. يمكنك العثور عليها في Project Settings -> General.',
              icon: Icons.error_outline_rounded,
              technicalDetails: error.toString(),
              actions: [
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.refresh),
                    label: Text(
                      'إعادة المحاولة',
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
          ),
        ),
      ),
    );
  }
}
