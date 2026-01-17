/// Student: The primary entity representing a student in the Quran center.
///
/// This model tracks:
/// 1. Identity: Name, Age, Photo.
/// 2. Relationships: Which Sheikh they study with ([sheikhId]) and which Parent follows them ([parentId]).
/// 3. Current Level: Their latest progress (Juz, Surah, Ayah) across the entire Quran.
/// 4. Meta: Enrollment date and teacher notes.
class Student {
  final String id;
  final String name;
  final String? parentId;
  final String? sheikhId;
  final int age;

  // Progress tracking fields
  final int currentJuz;
  final String currentSurah;
  final int currentAyah;

  final DateTime enrollmentDate;
  final String? photoUrl;
  final String? notes;

  const Student({
    required this.id,
    required this.name,
    this.parentId,
    this.sheikhId,
    required this.age,
    this.currentJuz = 1,
    this.currentSurah = 'الفاتحة',
    this.currentAyah = 1,
    required this.enrollmentDate,
    this.photoUrl,
    this.notes,
  });

  /// standard copyWith for status updates (like updating current progress)
  Student copyWith({
    String? id,
    String? name,
    String? parentId,
    String? sheikhId,
    int? age,
    int? currentJuz,
    String? currentSurah,
    int? currentAyah,
    DateTime? enrollmentDate,
    String? photoUrl,
    String? notes,
  }) {
    return Student(
      id: id ?? this.id,
      name: name ?? this.name,
      parentId: parentId ?? this.parentId,
      sheikhId: sheikhId ?? this.sheikhId,
      age: age ?? this.age,
      currentJuz: currentJuz ?? this.currentJuz,
      currentSurah: currentSurah ?? this.currentSurah,
      currentAyah: currentAyah ?? this.currentAyah,
      enrollmentDate: enrollmentDate ?? this.enrollmentDate,
      photoUrl: photoUrl ?? this.photoUrl,
      notes: notes ?? this.notes,
    );
  }

  /// Converts student entity to a Firestore-compatible Map.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'parentId': parentId,
      'sheikhId': sheikhId,
      'age': age,
      'currentJuz': currentJuz,
      'currentSurah': currentSurah,
      'currentAyah': currentAyah,
      'enrollmentDate': enrollmentDate.toIso8601String(),
      'photoUrl': photoUrl,
      'notes': notes,
    };
  }

  /// Reconstructs a student from a Firestore Map.
  /// Handles fallback values for missing or legacy data.
  factory Student.fromMap(Map<String, dynamic> map) {
    return Student(
      // Supports both 'id' and 'uid' for backwards compatibility
      id: (map['id'] ?? map['uid'] ?? '') as String,
      name: (map['name'] ?? 'بدون اسم') as String,
      parentId: map['parentId'] as String?,
      sheikhId: map['sheikhId'] as String?,
      age: (map['age'] ?? 0) as int,
      currentJuz: (map['currentJuz'] ?? 1) as int,
      currentSurah: (map['currentSurah'] ?? 'الفاتحة') as String,
      currentAyah: (map['currentAyah'] ?? 1) as int,
      enrollmentDate: map['enrollmentDate'] != null
          ? DateTime.tryParse(map['enrollmentDate'] as String) ?? DateTime.now()
          : DateTime.now(),
      photoUrl: map['photoUrl'] as String?,
      notes: map['notes'] as String?,
    );
  }
}
