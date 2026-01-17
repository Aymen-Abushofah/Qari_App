import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/student.dart';
import '../models/student_record.dart';

/// FirestoreService: The primary data management layer for the Qari application.
///
/// Responsibility:
/// 1. CRUD operations for Users, Students, Records, Requests, and Messages.
/// 2. Business Logic: Cascade deletion, real-time unapproved user filtering.
/// 3. Performance Optimization: Handling sorting in-memory to avoid complex index requirements.
class FirestoreService {
  // Database instance getter
  FirebaseFirestore get _db => FirebaseFirestore.instance;

  // --- Singleton Pattern ---
  static final FirestoreService _instance = FirestoreService._internal();
  factory FirestoreService() => _instance;
  FirestoreService._internal();

  // --- Collection names ---
  static const String usersCollection = 'users';
  static const String studentsCollection = 'students';
  static const String recordsCollection = 'records';
  static const String requestsCollection = 'requests';
  static const String messagesCollection = 'messages';

  // ==========================================
  // --- USER MANAGEMENT METHODS ---
  // ==========================================

  /// Initializes a user profile document after a successful Auth signup.
  Future<void> createUserDocument(
    String uid,
    Map<String, dynamic> userData,
  ) async {
    await _db.collection(usersCollection).doc(uid).set(userData);
  }

  /// Deletes a user profile document (Admin only).
  Future<void> deleteUserDocument(String uid) async {
    await _db.collection(usersCollection).doc(uid).delete();
  }

  /// Complex Cascade Deletion:
  /// When a user (Parent/Sheikh) is removed, we must clean up references
  /// without breaking orphaning related students.
  Future<void> deleteUserWithData(String uid, String userType) async {
    final batch = _db.batch();

    // --- Unlink Students ---
    if (userType == 'parent') {
      final studentsSnapshot = await _db
          .collection(studentsCollection)
          .where('parentId', isEqualTo: uid)
          .get();

      for (final studentDoc in studentsSnapshot.docs) {
        batch.update(studentDoc.reference, {'parentId': null});
      }
    } else if (userType == 'sheikh') {
      final studentsSnapshot = await _db
          .collection(studentsCollection)
          .where('sheikhId', isEqualTo: uid)
          .get();

      for (final studentDoc in studentsSnapshot.docs) {
        batch.update(studentDoc.reference, {'sheikhId': null});
      }
    }

    // --- Delete Messages ---
    // Cleans up all chat history where this user was a participant.
    final sentMessages = await _db
        .collection(messagesCollection)
        .where('senderId', isEqualTo: uid)
        .get();
    for (final msg in sentMessages.docs) {
      batch.delete(msg.reference);
    }

    final receivedMessages = await _db
        .collection(messagesCollection)
        .where('receiverId', isEqualTo: uid)
        .get();
    for (final msg in receivedMessages.docs) {
      batch.delete(msg.reference);
    }

    // Finally, commit everything
    batch.delete(_db.collection(usersCollection).doc(uid));
    await batch.commit();
  }

  /// toggles Admin privileges for a specific user.
  Future<void> updateUserAdminStatus(String uid, bool isAdmin) async {
    await _db.collection(usersCollection).doc(uid).update({'isAdmin': isAdmin});
  }

  /// Fetches a single user document.
  Future<DocumentSnapshot> getUserData(String uid) async {
    return await _db.collection(usersCollection).doc(uid).get();
  }

  /// Streams a list of Parents who have been APPROVED by an Admin.
  /// Filters occur in two stages: Firestore query (type) + Client-side filter (approval).
  Stream<List<Map<String, dynamic>>> getParents() {
    return _db
        .collection(usersCollection)
        .where('type', isEqualTo: 'parent')
        .snapshots()
        .map((snapshot) {
          final allParents = snapshot.docs
              .map((doc) => {...doc.data(), 'uid': doc.id})
              .toList();
          return allParents.where((parent) {
            final approved = parent['isApproved'];
            return approved == true || approved == 'true';
          }).toList();
        });
  }

  /// Streams a list of Approved Sheikhs.
  Stream<List<Map<String, dynamic>>> getSheikhs() {
    return _db
        .collection(usersCollection)
        .where('type', isEqualTo: 'sheikh')
        .snapshots()
        .map((snapshot) {
          final allSheikhs = snapshot.docs
              .map((doc) => {...doc.data(), 'uid': doc.id})
              .toList();
          return allSheikhs.where((sheikh) {
            final approved = sheikh['isApproved'];
            return approved == true || approved == 'true';
          }).toList();
        });
  }

  /// Check if the system has any teachers (Initial setup check).
  Future<bool> hasAnySheikhs() async {
    final snapshot = await _db
        .collection(usersCollection)
        .where('type', isEqualTo: 'sheikh')
        .limit(1)
        .get();
    return snapshot.docs.isNotEmpty;
  }

  // ==========================================
  // --- STUDENT MANAGEMENT METHODS ---
  // ==========================================

  /// Streams students assigned specifically to a Sheikh.
  Stream<List<Student>> getStudentsForSheikh(String sheikhId) {
    return _db
        .collection(studentsCollection)
        .where('sheikhId', isEqualTo: sheikhId)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => Student.fromMap(doc.data())).toList(),
        );
  }

  /// Streams all students in the system (for shared Sheikh access).
  Stream<List<Student>> getAllStudents() {
    return _db
        .collection(studentsCollection)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => Student.fromMap(doc.data())).toList(),
        );
  }

  /// Streams students linked to a Parent.
  Stream<List<Student>> getStudentsByParent(String parentId) {
    return _db
        .collection(studentsCollection)
        .where('parentId', isEqualTo: parentId)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => Student.fromMap(doc.data())).toList(),
        );
  }

  /// Real-time stream for a single student profile.
  Stream<Student?> getStudentByUid(String uid) {
    return _db
        .collection(studentsCollection)
        .doc(uid)
        .snapshots()
        .map((doc) => doc.exists ? Student.fromMap(doc.data()!) : null);
  }

  /// Fetches historical records for a student.
  /// Note: Sorting is handled in-memory to avoid index overhead.
  Stream<List<StudentRecord>> getStudentRecords(String studentId) {
    return _db
        .collection(recordsCollection)
        .where('studentId', isEqualTo: studentId)
        .snapshots()
        .map((snapshot) {
          final records = snapshot.docs
              .map((doc) => StudentRecord.fromMap(doc.data()))
              .toList();
          records.sort((a, b) => b.date.compareTo(a.date));
          return records;
        });
  }

  /// Logic for creating a student document.
  Future<void> createStudent(Student student) async {
    await _db
        .collection(studentsCollection)
        .doc(student.id)
        .set(student.toMap());
  }

  /// Logic for updating a student profile.
  Future<void> updateStudent(Student student) async {
    await _db
        .collection(studentsCollection)
        .doc(student.id)
        .update(student.toMap());
  }

  /// Deletes a student and ALL their history (Records).
  Future<void> deleteStudent(String studentId) async {
    final batch = _db.batch();

    // 1. Delete all records link to this student
    final recordsSnapshot = await _db
        .collection(recordsCollection)
        .where('studentId', isEqualTo: studentId)
        .get();

    for (final doc in recordsSnapshot.docs) {
      batch.delete(doc.reference);
    }

    // 2. Delete the primary student document
    batch.delete(_db.collection(studentsCollection).doc(studentId));

    await batch.commit();
  }

  // ==========================================
  // --- PROGRESS RECORD METHODS ---
  // ==========================================

  /// Stores a new daily Hifz/Review record.
  Future<void> addStudentRecord(StudentRecord record) async {
    await _db.collection(recordsCollection).add(record.toMap());
  }

  /// Query records for a specific day.
  Stream<List<StudentRecord>> getRecordsForDate(DateTime date) {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    return _db
        .collection(recordsCollection)
        .where('date', isGreaterThanOrEqualTo: startOfDay.toIso8601String())
        .where('date', isLessThan: endOfDay.toIso8601String())
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => StudentRecord.fromMap(doc.data()))
              .toList(),
        );
  }

  /// Query records for an entire month.
  Stream<List<StudentRecord>> getRecordsForMonth(DateTime month) {
    final startOfMonth = DateTime(month.year, month.month, 1);
    final nextMonth = month.month == 12 ? 1 : month.month + 1;
    final nextYear = month.month == 12 ? month.year + 1 : month.year;
    final endOfMonth = DateTime(nextYear, nextMonth, 1);

    return _db
        .collection(recordsCollection)
        .where('date', isGreaterThanOrEqualTo: startOfMonth.toIso8601String())
        .where('date', isLessThan: endOfMonth.toIso8601String())
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => StudentRecord.fromMap(doc.data()))
              .toList(),
        );
  }

  /// Stats: Present today.
  Stream<int> getTodayPresentCount() {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    return _db
        .collection(recordsCollection)
        .where('date', isGreaterThanOrEqualTo: startOfDay.toIso8601String())
        .where('date', isLessThan: endOfDay.toIso8601String())
        .where('attendanceStatus', isEqualTo: AttendanceStatus.present.index)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  /// Stats: Absent today.
  Stream<int> getTodayAbsentCount() {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    return _db
        .collection(recordsCollection)
        .where('date', isGreaterThanOrEqualTo: startOfDay.toIso8601String())
        .where('date', isLessThan: endOfDay.toIso8601String())
        .where('attendanceStatus', isNotEqualTo: AttendanceStatus.present.index)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  /// Total volume of history.
  Stream<int> getTotalHifzRecordsCount() {
    return _db
        .collection(recordsCollection)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  // ==========================================
  // --- ADMIN APPROVAL METHODS ---
  // ==========================================

  /// Post a new join request (Parent/Sheikh).
  Future<void> addJoinRequest(String type, Map<String, dynamic> data) async {
    await _db.collection(requestsCollection).add({
      ...data,
      'type': type,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// Fetch pending requests for the Management screen.
  Stream<QuerySnapshot> getRequestsByType(String type) {
    return _db
        .collection(requestsCollection)
        .where('type', isEqualTo: type)
        .where('status', isEqualTo: 'pending')
        .snapshots();
  }

  /// Aggregate for Dashboard badge.
  Stream<int> getAllPendingRequestsCount() {
    return _db
        .collection(requestsCollection)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  /// Updates the lifecycle status of a join request.
  Future<void> updateRequestStatus(String requestId, String status) async {
    await _db.collection(requestsCollection).doc(requestId).update({
      'status': status,
    });
  }

  /// Marks a user as verified.
  Future<void> approveUser(String uid) async {
    await _db.collection(usersCollection).doc(uid).update({'isApproved': true});
  }

  /// Marks a user as rejected by an Admin.
  Future<void> rejectUser(String uid) async {
    await _db.collection(usersCollection).doc(uid).update({
      'isRejected': true,
      'isApproved': false,
    });
  }

  /// Removes all traces of a rejected account.
  Future<void> deleteRejectedAccount(String uid) async {
    final batch = _db.batch();

    // 1. Find and delete join requests from this UID
    final requests = await _db
        .collection(requestsCollection)
        .where('uid', isEqualTo: uid)
        .get();

    for (final doc in requests.docs) {
      batch.delete(doc.reference);
    }

    // 2. Delete the user profile
    batch.delete(_db.collection(usersCollection).doc(uid));

    await batch.commit();
  }

  // ==========================================
  // --- MESSAGING METHODS ---
  // ==========================================

  /// Sends a P2P message.
  Future<void> sendMessage(Map<String, dynamic> messageData) async {
    await _db.collection(messagesCollection).add({
      ...messageData,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  /// Streams the chat history between two specific users.
  Stream<List<Map<String, dynamic>>> getMessages(String user1, String user2) {
    return _db
        .collection(messagesCollection)
        .where(
          Filter.or(
            Filter.and(
              Filter('senderId', isEqualTo: user1),
              Filter('receiverId', isEqualTo: user2),
            ),
            Filter.and(
              Filter('senderId', isEqualTo: user2),
              Filter('receiverId', isEqualTo: user1),
            ),
          ),
        )
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }

  /// Fetches all unique conversational strings for a user dashboard.
  Stream<List<Map<String, dynamic>>> getConversations(String userId) {
    return _db
        .collection(messagesCollection)
        .where(
          Filter.or(
            Filter('senderId', isEqualTo: userId),
            Filter('receiverId', isEqualTo: userId),
          ),
        )
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }
}
