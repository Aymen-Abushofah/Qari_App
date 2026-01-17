/// AttendanceStatus: Defines the different states a student can have
/// regarding their presence in a session.
enum AttendanceStatus {
  present, // حاضر - Present in the session
  absentExcused, // غياب بإذن - Absent with a valid reason
  absentUnexcused, // غياب بدون إذن - Absent without notice
}

/// ListenerType: Identifies who listened to the student's
/// memorization or review.
enum ListenerType {
  sheikh, // الشيخ - Official teacher
  anotherSheikh, // شيخ آخر - Guest or sub-teacher
}

/// PerformanceLevel: Qualitative rating of the student's
/// daily performance.
enum PerformanceLevel {
  excellent, // ممتاز - No mistakes
  veryGood, // جيد جداً - 1-2 minor mistakes
  good, // جيد - 3-5 mistakes
  acceptable, // مقبول - Significant mistakes
  weak, // ضعيف - Needs re-memorization
}

/// StudentRecord: Represents a single daily entry for a student's activity.
///
/// This is the core data model for reporting and includes:
/// - [date]: The day this activity occurred.
/// - Hifz Progression: Starting/Ending points and mistake count.
/// - Review Progression: Parallel tracking for revision cycles.
/// - Attendance & Performance: Categorical status updates.
class StudentRecord {
  final String id;
  final String studentId;
  final DateTime date;

  // --- Hifz (memorization) data ---
  // Tracks new verses learned today.
  final String? hifzFromSurah;
  final int? hifzFromAyah;
  final String? hifzToSurah;
  final int? hifzToAyah;
  final int hifzMistakes;

  // --- Review data ---
  // Tracks previous verses being revised today.
  final String? reviewFromSurah;
  final int? reviewFromAyah;
  final String? reviewToSurah;
  final int? reviewToAyah;
  final int reviewMistakes;

  // --- Session Status ---
  final AttendanceStatus attendanceStatus;
  final PerformanceLevel? performance;
  final ListenerType? listenerType;
  final String? listenerId;

  final String? notes;
  final DateTime createdAt;

  const StudentRecord({
    required this.id,
    required this.studentId,
    required this.date,
    this.hifzFromSurah,
    this.hifzFromAyah,
    this.hifzToSurah,
    this.hifzToAyah,
    this.hifzMistakes = 0,
    this.reviewFromSurah,
    this.reviewFromAyah,
    this.reviewToSurah,
    this.reviewToAyah,
    this.reviewMistakes = 0,
    this.attendanceStatus = AttendanceStatus.present,
    this.performance,
    this.listenerType,
    this.listenerId,
    this.notes,
    required this.createdAt,
  });

  /// Helper to check if any hifz progress was recorded in this session.
  bool get hasHifz => hifzFromSurah != null && hifzToSurah != null;

  /// Helper to check if any review progress was recorded in this session.
  bool get hasReview => reviewFromSurah != null && reviewToSurah != null;

  /// Helper to check if the student was marked present.
  bool get isPresent => attendanceStatus == AttendanceStatus.present;

  /// standard copyWith
  StudentRecord copyWith({
    String? id,
    String? studentId,
    DateTime? date,
    String? hifzFromSurah,
    int? hifzFromAyah,
    String? hifzToSurah,
    int? hifzToAyah,
    int? hifzMistakes,
    String? reviewFromSurah,
    int? reviewFromAyah,
    String? reviewToSurah,
    int? reviewToAyah,
    int? reviewMistakes,
    AttendanceStatus? attendanceStatus,
    PerformanceLevel? performance,
    ListenerType? listenerType,
    String? listenerId,
    String? notes,
    DateTime? createdAt,
  }) {
    return StudentRecord(
      id: id ?? this.id,
      studentId: studentId ?? this.studentId,
      date: date ?? this.date,
      hifzFromSurah: hifzFromSurah ?? this.hifzFromSurah,
      hifzFromAyah: hifzFromAyah ?? this.hifzFromAyah,
      hifzToSurah: hifzToSurah ?? this.hifzToSurah,
      hifzToAyah: hifzToAyah ?? this.hifzToAyah,
      hifzMistakes: hifzMistakes ?? this.hifzMistakes,
      reviewFromSurah: reviewFromSurah ?? this.reviewFromSurah,
      reviewFromAyah: reviewFromAyah ?? this.reviewFromAyah,
      reviewToSurah: reviewToSurah ?? this.reviewToSurah,
      reviewToAyah: reviewToAyah ?? this.reviewToAyah,
      reviewMistakes: reviewMistakes ?? this.reviewMistakes,
      attendanceStatus: attendanceStatus ?? this.attendanceStatus,
      performance: performance ?? this.performance,
      listenerType: listenerType ?? this.listenerType,
      listenerId: listenerId ?? this.listenerId,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Map conversion for Firestore.
  /// Enums are stored as integers (index) for efficiency.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'studentId': studentId,
      'date': date.toIso8601String(),
      'hifzFromSurah': hifzFromSurah,
      'hifzFromAyah': hifzFromAyah,
      'hifzToSurah': hifzToSurah,
      'hifzToAyah': hifzToAyah,
      'hifzMistakes': hifzMistakes,
      'reviewFromSurah': reviewFromSurah,
      'reviewFromAyah': reviewFromAyah,
      'reviewToSurah': reviewToSurah,
      'reviewToAyah': reviewToAyah,
      'reviewMistakes': reviewMistakes,
      'attendanceStatus': attendanceStatus.index,
      'performance': performance?.index,
      'listenerType': listenerType?.index,
      'listenerId': listenerId,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  /// Map reconstruction from Firestore.
  /// Includes safe enum parsing with fallback to handle legacy or malformed data.
  factory StudentRecord.fromMap(Map<String, dynamic> map) {
    T? safeGetEnum<T>(List<T> values, dynamic index) {
      if (index == null || index is! int) return null;
      if (index < 0 || index >= values.length) return values[0];
      return values[index];
    }

    return StudentRecord(
      id: (map['id'] ?? '') as String,
      studentId: (map['studentId'] ?? '') as String,
      date: map['date'] != null
          ? DateTime.tryParse(map['date'] as String) ?? DateTime.now()
          : DateTime.now(),
      hifzFromSurah: map['hifzFromSurah'] as String?,
      hifzFromAyah: map['hifzFromAyah'] as int?,
      hifzToSurah: map['hifzToSurah'] as String?,
      hifzToAyah: map['hifzToAyah'] as int?,
      hifzMistakes: (map['hifzMistakes'] ?? 0) as int,
      reviewFromSurah: map['reviewFromSurah'] as String?,
      reviewFromAyah: map['reviewFromAyah'] as int?,
      reviewToSurah: map['reviewToSurah'] as String?,
      reviewToAyah: map['reviewToAyah'] as int?,
      reviewMistakes: (map['reviewMistakes'] ?? 0) as int,
      attendanceStatus:
          safeGetEnum(AttendanceStatus.values, map['attendanceStatus']) ??
          AttendanceStatus.present,
      performance: safeGetEnum(PerformanceLevel.values, map['performance']),
      listenerType: safeGetEnum(ListenerType.values, map['listenerType']),
      listenerId: map['listenerId'] as String?,
      notes: map['notes'] as String?,
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
