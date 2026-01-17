import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';
import '../../models/student_record.dart';
import '../../models/student.dart';

/// DailyReportDetailScreen: A read-only view of a student's performance for a specific day.
///
/// Displays:
/// 1. Attendance status with status-specific icons/colors.
/// 2. Hifz (Memorization) details including surah ranges and mistakes count.
/// 3. Review details covering the student's daily revision.
/// 4. Performance rating and Sheikh's comments.
class DailyReportDetailScreen extends StatelessWidget {
  final Student student;
  final StudentRecord record;

  const DailyReportDetailScreen({
    super.key,
    required this.student,
    required this.record,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'تقرير اليوم - ${student.name}',
          style: GoogleFonts.tajawal(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDateHeader(context),
            const SizedBox(height: 24),
            _buildAttendanceSection(context),
            if (record.attendanceStatus == AttendanceStatus.present) ...[
              const SizedBox(height: 24),
              _buildSection(
                context,
                title: 'الحفظ الجديد',
                icon: Icons.menu_book_rounded,
                color: AppTheme.primaryColor,
                child: _buildMemorizationContent(
                  fromSurah: record.hifzFromSurah,
                  fromAyah: record.hifzFromAyah,
                  toSurah: record.hifzToSurah,
                  toAyah: record.hifzToAyah,
                  mistakes: record.hifzMistakes,
                ),
              ),
              const SizedBox(height: 16),
              _buildSection(
                context,
                title: 'المراجعة اليومية',
                icon: Icons.refresh_rounded,
                color: AppTheme.secondaryColor,
                child: _buildMemorizationContent(
                  fromSurah: record.reviewFromSurah,
                  fromAyah: record.reviewFromAyah,
                  toSurah: record.reviewToSurah,
                  toAyah: record.reviewToAyah,
                  mistakes: record.reviewMistakes,
                ),
              ),
              const SizedBox(height: 16),
              if (record.performance != null)
                _buildSection(
                  context,
                  title: 'التقييم العام',
                  icon: Icons.star_rounded,
                  color: Colors.purple,
                  child: _buildPerformanceBadge(record.performance!),
                ),
            ],
            if (record.notes != null && record.notes!.isNotEmpty) ...[
              const SizedBox(height: 24),
              _buildSection(
                context,
                title: 'ملاحظات المعلم',
                icon: Icons.note_rounded,
                color: Colors.blueGrey,
                child: Text(
                  record.notes!,
                  style: GoogleFonts.tajawal(fontSize: 15, height: 1.5),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDateHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          Icon(Icons.calendar_today_rounded, color: AppTheme.primaryColor),
          const SizedBox(width: 12),
          Text(
            'التاريخ: ${record.date.day}/${record.date.month}/${record.date.year}',
            style: GoogleFonts.tajawal(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  /// Builds a visual indicator of the student's attendance for the day.
  Widget _buildAttendanceSection(BuildContext context) {
    final status = record.attendanceStatus;
    Color color;
    String text;
    IconData icon;

    switch (status) {
      case AttendanceStatus.present:
        color = AppTheme.successColor;
        text = 'حاضر';
        icon = Icons.check_circle_rounded;
        break;
      case AttendanceStatus.absentExcused:
        color = Colors.orange;
        text = 'غائب (بعذر)';
        icon = Icons.event_busy_rounded;
        break;
      case AttendanceStatus.absentUnexcused:
        color = AppTheme.errorColor;
        text = 'غائب (بدون عذر)';
        icon = Icons.cancel_rounded;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 12),
          Text('حالة الحضور: ', style: GoogleFonts.tajawal(fontSize: 15)),
          Text(
            text,
            style: GoogleFonts.tajawal(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  /// A generic container for report sections (Hifz, Review, etc.) with a consistent header style.
  Widget _buildSection(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color color,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: GoogleFonts.tajawal(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  /// Formats and renders the memorization (Hifz) details, handling empty/null ranges.
  Widget _buildMemorizationContent({
    String? fromSurah,
    int? fromAyah,
    String? toSurah,
    int? toAyah,
    int mistakes = 0,
  }) {
    if (fromSurah == null && toSurah == null) {
      return Text(
        'لم يتم تسجيل بيانات',
        style: GoogleFonts.tajawal(
          color: Colors.grey,
          fontStyle: FontStyle.italic,
        ),
      );
    }

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildInfoChip('من', '$fromSurah ($fromAyah)'),
            const Icon(Icons.arrow_back_rounded, size: 16, color: Colors.grey),
            _buildInfoChip('إلى', '$toSurah ($toAyah)'),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 16,
              color: Colors.red,
            ),
            const SizedBox(width: 4),
            Text(
              'عدد الأخطاء: $mistakes',
              style: GoogleFonts.tajawal(
                color: Colors.red.shade700,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInfoChip(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.tajawal(fontSize: 11, color: Colors.grey),
        ),
        Text(
          value,
          style: GoogleFonts.tajawal(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  /// Builds a colored badge indicating the overall performance level for the day.
  Widget _buildPerformanceBadge(PerformanceLevel level) {
    String text;
    Color color;

    switch (level) {
      case PerformanceLevel.excellent:
        text = 'ممتاز';
        color = Colors.green;
        break;
      case PerformanceLevel.veryGood:
        text = 'جيد جداً';
        color = Colors.lightGreen;
        break;
      case PerformanceLevel.good:
        text = 'جيد';
        color = Colors.amber;
        break;
      case PerformanceLevel.acceptable:
        text = 'مقبول';
        color = Colors.orange;
        break;
      case PerformanceLevel.weak:
        text = 'ضعيف';
        color = Colors.red;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        text,
        style: GoogleFonts.tajawal(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
    );
  }
}
