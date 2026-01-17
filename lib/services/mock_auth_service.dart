import '../screens/user_selection/user_selection_screen.dart';

/// MockAuthService: A development bypass for Firebase Authentication.
///
/// Role:
/// 1. Allows developers to test screen transitions without a real Firebase project.
/// 2. Simulates network delays and account approval workflows.
/// 3. Standard Login/Signup/Logout methods matching the interface of [FirebaseAuthService].
///
/// WARNING: This should be disabled or removed before production release.
class MockAuthService {
  // --- Singleton Pattern ---
  static final MockAuthService _instance = MockAuthService._internal();
  factory MockAuthService() => _instance;
  MockAuthService._internal();

  /// Static hardcoded users for quick testing.
  static final Map<String, Map<String, dynamic>> _mockUsers = {
    'sheikh@qari.com': {
      'password': '123456',
      'name': 'الشيخ أحمد',
      'type': 'sheikh',
      'id': 'sheikh1',
      'isApproved': true,
    },
    'parent@qari.com': {
      'password': '123456',
      'name': 'محمد العلي',
      'type': 'parent',
      'id': 'p1',
      'isApproved': true,
    },
    'student@qari.com': {
      'password': '123456',
      'name': 'عمر محمد',
      'type': 'student',
      'id': 's1',
      'isApproved': true,
    },
  };

  // --- Ephemeral Session State ---
  String? _currentUserId;
  String? _currentUserName;
  UserType? _currentUserType;
  bool _isApproved = false;

  // --- Getters ---
  bool get isLoggedIn => _currentUserId != null;
  String? get currentUserId => _currentUserId;
  String? get currentUserName => _currentUserName;
  UserType? get currentUserType => _currentUserType;
  bool get isApproved => _isApproved;

  /// Simulates a login attempt with an artificial 800ms delay.
  Future<String?> login(
    String email,
    String password,
    UserType userType,
  ) async {
    await Future.delayed(const Duration(milliseconds: 800));

    final user = _mockUsers[email.toLowerCase().trim()];

    if (user == null) {
      return 'البريد الإلكتروني غير مسجل';
    }

    if (user['password'] != password) {
      return 'كلمة المرور غير صحيحة';
    }

    // Verify user type consistency
    String expectedType;
    switch (userType) {
      case UserType.sheikh:
        expectedType = 'sheikh';
        break;
      case UserType.student:
        expectedType = 'student';
        break;
      case UserType.parent:
        expectedType = 'parent';
        break;
    }

    if (user['type'] != expectedType) {
      return 'نوع المستخدم غير صحيح';
    }

    // Update session state
    _currentUserId = user['id'] as String?;
    _currentUserName = user['name'] as String?;
    _currentUserType = userType;
    _isApproved = user['isApproved'] == true;

    return null;
  }

  /// Simulates closing the session.
  Future<void> logout() async {
    await Future.delayed(const Duration(milliseconds: 300));
    _currentUserId = null;
    _currentUserName = null;
    _currentUserType = null;
  }

  /// Simulates user signup by adding them to the in-memory Map.
  Future<String?> signup({
    required String name,
    required String email,
    required String phone,
    required String password,
    required UserType userType,
  }) async {
    await Future.delayed(const Duration(milliseconds: 800));

    if (_mockUsers.containsKey(email.toLowerCase().trim())) {
      return 'البريد الإلكتروني مسجل بالفعل';
    }

    // Persist to temporary memory for the current session
    _mockUsers[email.toLowerCase().trim()] = {
      'password': password,
      'name': name,
      'type': switch (userType) {
        UserType.sheikh => 'sheikh',
        UserType.student => 'student',
        UserType.parent => 'parent',
      },
      'id': 'new_user_${DateTime.now().millisecondsSinceEpoch}',
      'isApproved': false,
    };

    return null;
  }

  /// Utility for testing Admin features: Approves a user in the local Map.
  void approveUserById(String id) {
    _mockUsers.forEach((email, data) {
      if (data['id'] == id) {
        data['isApproved'] = true;
      }
    });

    // Update session state if current user was approved
    if (_currentUserId == id) {
      _isApproved = true;
    }
  }
}
