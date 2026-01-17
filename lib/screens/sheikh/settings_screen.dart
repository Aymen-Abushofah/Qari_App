import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/theme_manager.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'الإعدادات',
          style: GoogleFonts.tajawal(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // General Settings Section
            _buildSectionHeader(
              'إعدادات التطبيق',
              Icons.settings,
              AppTheme.primaryColor,
            ),
            const SizedBox(height: 16),
            _buildSettingTile(
              icon: Icons.notifications_active_rounded,
              title: 'الإشعارات',
              subtitle: 'تفعيل إشعارات الحضور والغياب والرسائل',
              trailing: Switch(
                value: true,
                onChanged: (v) {},
                activeThumbColor: AppTheme.primaryColor,
              ),
            ),
            _buildSettingTile(
              icon: Icons.language_rounded,
              title: 'اللغة',
              subtitle: 'العربية',
              trailing: const Icon(
                Icons.chevron_left,
                color: AppTheme.textSecondary,
              ),
            ),
            _buildSettingTile(
              icon: Icons.dark_mode_rounded,
              title: 'الوضع الليلي',
              subtitle: 'التبديل بين المظهر الفاتح والداكن',
              trailing: ValueListenableBuilder<ThemeMode>(
                valueListenable: ThemeManager().themeModeNotifier,
                builder: (context, themeMode, _) {
                  return Switch(
                    value: themeMode == ThemeMode.dark,
                    onChanged: (v) => ThemeManager().toggleTheme(v),
                    activeThumbColor: AppTheme.primaryColor,
                  );
                },
              ),
            ),
            _buildSettingTile(
              icon: Icons.cloud_sync_rounded,
              title: 'النسخ الاحتياطي',
              subtitle: 'آخر نسخة: اليوم 10:30 ص',
              trailing: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'نسخ الآن',
                  style: GoogleFonts.tajawal(fontSize: 12, color: Colors.white),
                ),
              ),
            ),

            _buildSectionHeader(
              'معلومات التطبيق',
              Icons.info_outline_rounded,
              Theme.of(context).iconTheme.color ?? Colors.blueGrey,
            ),
            const SizedBox(height: 16),
            _buildSettingTile(
              icon: Icons.verified_user_rounded,
              title: 'الإصدار',
              subtitle: '1.0.0',
              trailing: const SizedBox(),
            ),
            _buildSettingTile(
              icon: Icons.privacy_tip_rounded,
              title: 'سياسة الخصوصية',
              subtitle: '',
              trailing: const Icon(Icons.chevron_left),
            ),

            const SizedBox(height: 24),
            _buildSectionHeader('المطورون', Icons.code_rounded, Colors.blue),
            const SizedBox(height: 16),
            _buildDeveloperTile('أيمن أحمد أبوشوفة'),
            _buildDeveloperTile('مصعب سالم بشارة'),
            _buildDeveloperTile('منذر عبد الله خليفة'),
          ],
        ),
      ),
    );
  }

  Widget _buildDeveloperTile(String name) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.person_outline_rounded,
              color: AppTheme.primaryColor,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            name,
            style: GoogleFonts.tajawal(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: GoogleFonts.tajawal(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).textTheme.bodyLarge?.color,
          ),
        ),
      ],
    );
  }

  Widget _buildSettingTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Widget trailing,
    VoidCallback? onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Theme.of(context).disabledColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppTheme.textSecondary, size: 20),
        ),
        title: Text(
          title,
          style: GoogleFonts.tajawal(fontWeight: FontWeight.w500),
        ),
        subtitle: Text(
          subtitle,
          style: GoogleFonts.tajawal(
            fontSize: 12,
            color: AppTheme.textSecondary,
          ),
        ),
        trailing: trailing,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
