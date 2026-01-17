/// ParentModel: Represents a parent or guardian user in the Qari app.
///
/// Key features:
/// - Stores basic contact info (Name, Phone, Email).
/// - [studentIds]: A list of UIDs for students linked to this parent.
///   This allows one parent to monitor multiple children.
class ParentModel {
  final String id;
  final String name;
  final String phone;
  final String? email;
  final List<String> studentIds;

  const ParentModel({
    required this.id,
    required this.name,
    required this.phone,
    this.email,
    this.studentIds = const [],
  });

  /// standard copyWith for state management
  ParentModel copyWith({
    String? id,
    String? name,
    String? phone,
    String? email,
    List<String>? studentIds,
  }) {
    return ParentModel(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      studentIds: studentIds ?? this.studentIds,
    );
  }

  /// Converts model to Map for Firestore storage.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'email': email,
      'studentIds': studentIds,
    };
  }

  /// Reconstructs the model from a Firestore Map.
  factory ParentModel.fromMap(Map<String, dynamic> map) {
    return ParentModel(
      id: map['id'] as String,
      name: map['name'] as String,
      phone: map['phone'] as String,
      email: map['email'] as String?,
      studentIds: List<String>.from(map['studentIds'] as List? ?? []),
    );
  }
}
