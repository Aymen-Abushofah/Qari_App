import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';
import '../../models/student.dart';
import '../../models/student_record.dart';

/// MonthlyReportDetailScreen: A comprehensive statistical overview of a student's progress over a month.
///
/// Component breakdown:
/// 1. Metric Cards: High-level stats for attendance, Hifz, and average performance.
/// 2. Performance Distribution: Visual representation of daily ratings.
/// 3. Attendance Heatmap: (Simplified list) showing days present vs absent.
/// 4. Daily Logs: Detailed list of all record entries for the selected month.
class MonthlyReportDetailScreen extends StatelessWidget {
  final Student student;
  final DateTime month;
  final List<StudentRecord> records;

  const MonthlyReportDetailScreen({
    super.key,
    required this.student,
    required this.month,
    required this.records,
  });

  @override
  Widget build(BuildContext context) {
    final totalDays = _getDaysInMonth(month);
    final presentDays = records.where((r) => r.isPresent).length;
    final absentDays = records.where((r) => !r.isPresent).length;
    final hifzDays = records.where((r) => r.hasHifz).length;
    final reviewDays = records.where((r) => r.hasReview).length;
    final attendanceRate = records.isEmpty ? 0.0 : presentDays / totalDays;

    // Calculate total pages memorized
    final totalAyahs = records.fold<int>(0, (sum, r) {
      if (r.hasHifz && r.hifzFromAyah != null && r.hifzToAyah != null) {
        return sum + (r.hifzToAyah! - r.hifzFromAyah! + 1);
      }
      return sum;
    });

    // Calculate average mistakes
    final avgMistakes = records.isEmpty
        ? 0.0
        : records
                  .where((r) => r.hasHifz)
                  .fold<int>(0, (sum, r) => sum + r.hifzMistakes) /
              records.where((r) => r.hasHifz).length.clamp(1, double.infinity);

    // Performance distribution
    final perfCounts = <PerformanceLevel, int>{};
    for (final r in records) {
      if (r.performance != null) {
        perfCounts[r.performance!] = (perfCounts[r.performance!] ?? 0) + 1;
      }
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 180,
            pinned: true,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppTheme.primaryColor, AppTheme.primaryLight],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 50, 20, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  student.name.substring(0, 1),
                                  style: GoogleFonts.amiri(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    student.name,
                                    style: GoogleFonts.tajawal(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  Text(
                                    '${_getArabicMonth(month.month)} ${month.year}',
                                    style: GoogleFonts.tajawal(
                                      fontSize: 14,
                                      color: Colors.white70,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Attendance Summary Card
                  _buildSummaryCard(
                    context,
                    title: 'ملخص الحضور',
                    icon: Icons.event_available,
                    color: AppTheme.successColor,
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _buildCircularProgress(
                                value: attendanceRate,
                                label: 'نسبة الحضور',
                                color: attendanceRate > 0.7
                                    ? AppTheme.successColor
                                    : attendanceRate > 0.4
                                    ? Colors.orange
                                    : AppTheme.errorColor,
                              ),
                            ),
                            const SizedBox(width: 20),
                            Expanded(
                              child: Column(
                                children: [
                                  _buildStatRow(
                                    Icons.check_circle,
                                    'حضور',
                                    '$presentDays يوم',
                                    AppTheme.successColor,
                                  ),
                                  const SizedBox(height: 8),
                                  _buildStatRow(
                                    Icons.cancel,
                                    'غياب',
                                    '$absentDays يوم',
                                    AppTheme.errorColor,
                                  ),
                                  const SizedBox(height: 8),
                                  _buildStatRow(
                                    Icons.calendar_today,
                                    'إجمالي',
                                    '$totalDays يوم',
                                    Colors.grey,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Hifz Summary Card
                  _buildSummaryCard(
                    context,
                    title: 'ملخص الحفظ',
                    icon: Icons.auto_stories,
                    color: AppTheme.primaryColor,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatColumn(
                          'أيام الحفظ',
                          '$hifzDays',
                          AppTheme.primaryColor,
                        ),
                        Container(
                          height: 50,
                          width: 1,
                          color: Colors.grey.shade200,
                        ),
                        _buildStatColumn(
                          'آيات محفوظة',
                          '$totalAyahs',
                          Colors.green,
                        ),
                        Container(
                          height: 50,
                          width: 1,
                          color: Colors.grey.shade200,
                        ),
                        _buildStatColumn(
                          'متوسط الأخطاء',
                          avgMistakes.toStringAsFixed(1),
                          Colors.orange,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Review Summary
                  _buildSummaryCard(
                    context,
                    title: 'ملخص المراجعة',
                    icon: Icons.refresh,
                    color: AppTheme.secondaryColor,
                    child: _buildProgressBar(
                      'أيام المراجعة',
                      reviewDays,
                      presentDays.clamp(1, totalDays),
                      AppTheme.secondaryColor,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Performance Distribution
                  if (perfCounts.isNotEmpty) ...[
                    _buildSummaryCard(
                      context,
                      title: 'توزيع الأداء',
                      icon: Icons.analytics,
                      color: Colors.purple,
                      child: Column(
                        children: PerformanceLevel.values.map((level) {
                          final count = perfCounts[level] ?? 0;
                          final total = perfCounts.values.fold<int>(
                            0,
                            (a, b) => a + b,
                          );
                          return _buildProgressBar(
                            _getPerformanceLabel(level),
                            count,
                            total == 0 ? 1 : total,
                            _getPerformanceColor(level),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Daily Records
                  Text(
                    'السجلات اليومية',
                    style: GoogleFonts.tajawal(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (records.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Center(
                        child: Text(
                          'لا توجد سجلات لهذا الشهر',
                          style: GoogleFonts.tajawal(
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ),
                    )
                  else
                    ...records.reversed.map((r) => _buildDayCard(context, r)),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Builds a styled summary card with a title, icon, and custom content.
  Widget _buildSummaryCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color color,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
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
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: GoogleFonts.tajawal(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
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

  /// Builds a circular progress indicator for displaying percentage-based metrics (like attendance).
  Widget _buildCircularProgress({
    required double value,
    required String label,
    required Color color,
  }) {
    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 80,
              height: 80,
              child: CircularProgressIndicator(
                value: value,
                strokeWidth: 8,
                backgroundColor: color.withValues(alpha: 0.2),
                valueColor: AlwaysStoppedAnimation(color),
              ),
            ),
            Text(
              '${(value * 100).round()}%',
              style: GoogleFonts.tajawal(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: GoogleFonts.tajawal(
            fontSize: 12,
            color: AppTheme.textSecondary,
          ),
        ),
      ],
    );
  }

  /// Builds a single row of statistical information with an icon and label.
  Widget _buildStatRow(IconData icon, String label, String value, Color color) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 8),
        Text(
          label,
          style: GoogleFonts.tajawal(
            fontSize: 12,
            color: AppTheme.textSecondary,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: GoogleFonts.tajawal(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  /// Builds a vertical column for showing a statistic label and its value.
  Widget _buildStatColumn(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.tajawal(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.tajawal(
            fontSize: 11,
            color: AppTheme.textSecondary,
          ),
        ),
      ],
    );
  }

  /// Builds a horizontal progress bar, typically used for performance distribution.
  Widget _buildProgressBar(String label, int value, int total, Color color) {
    final percentage = total == 0 ? 0.0 : value / total;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: GoogleFonts.tajawal(
                fontSize: 12,
                color: AppTheme.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: percentage,
                backgroundColor: color.withValues(alpha: 0.1),
                valueColor: AlwaysStoppedAnimation(color),
                minHeight: 8,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '$value',
            style: GoogleFonts.tajawal(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  /// Builds a card representing a single day's record.
  Widget _buildDayCard(BuildContext context, StudentRecord record) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border(
          right: BorderSide(
            color: record.isPresent
                ? AppTheme.successColor
                : AppTheme.errorColor,
            width: 4,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Date
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${record.date.day}',
                  style: GoogleFonts.tajawal(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  ),
                ),
                Text(
                  _getWeekDay(record.date.weekday),
                  style: GoogleFonts.tajawal(
                    fontSize: 10,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color:
                            (record.isPresent
                                    ? AppTheme.successColor
                                    : AppTheme.errorColor)
                                .withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        record.isPresent ? 'حاضر' : 'غائب',
                        style: GoogleFonts.tajawal(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: record.isPresent
                              ? AppTheme.successColor
                              : AppTheme.errorColor,
                        ),
                      ),
                    ),
                    if (record.performance != null) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: _getPerformanceColor(
                            record.performance!,
                          ).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _getPerformanceLabel(record.performance!),
                          style: GoogleFonts.tajawal(
                            fontSize: 10,
                            color: _getPerformanceColor(record.performance!),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                if (record.hasHifz) ...[
                  const SizedBox(height: 4),
                  Text(
                    '${record.hifzFromSurah} (${record.hifzFromAyah}) → ${record.hifzToSurah} (${record.hifzToAyah})',
                    style: GoogleFonts.tajawal(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (record.hasHifz)
            Text(
              '${record.hifzMistakes} خطأ',
              style: GoogleFonts.tajawal(
                fontSize: 11,
                color: record.hifzMistakes == 0
                    ? AppTheme.successColor
                    : Colors.orange,
              ),
            ),
        ],
      ),
    );
  }

  /// Returns the Arabic name for a given month index (1-12).
  String _getArabicMonth(int month) {
    const months = [
      'يناير',
      'فبراير',
      'مارس',
      'أبريل',
      'مايو',
      'يونيو',
      'يوليو',
      'أغسطس',
      'سبتمبر',
      'أكتوبر',
      'نوفمبر',
      'ديسمبر',
    ];
    return months[month - 1];
  }

  /// Returns the Arabic name for a given weekday index (1-7).
  String _getWeekDay(int weekday) {
    const days = [
      'الإثنين',
      'الثلاثاء',
      'الأربعاء',
      'الخميس',
      'الجمعة',
      'السبت',
      'الأحد',
    ];
    return days[weekday - 1];
  }

  /// Returns a user-friendly Arabic label for a performance level.
  String _getPerformanceLabel(PerformanceLevel level) {
    switch (level) {
      case PerformanceLevel.excellent:
        return 'ممتاز';
      case PerformanceLevel.veryGood:
        return 'جيد جداً';
      case PerformanceLevel.good:
        return 'جيد';
      case PerformanceLevel.acceptable:
        return 'مقبول';
      case PerformanceLevel.weak:
        return 'ضعيف';
    }
  }

  /// Returns the appropriate theme color for a performance level.
  Color _getPerformanceColor(PerformanceLevel level) {
    switch (level) {
      case PerformanceLevel.excellent:
        return AppTheme.successColor;
      case PerformanceLevel.veryGood:
        return Colors.green.shade400;
      case PerformanceLevel.good:
        return Colors.orange;
      case PerformanceLevel.acceptable:
        return Colors.orange.shade700;
      case PerformanceLevel.weak:
        return AppTheme.errorColor;
    }
  }

  /// Utility to get the number of days in the month of the provided date.
  int _getDaysInMonth(DateTime date) =>
      DateTime(date.year, date.month + 1, 0).day;
}
