import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/firebase_auth_service.dart';
import '../user_selection/user_selection_screen.dart';

/// UserAccessGuard: A wrapper widget that ensures real-time security enforcement.
///
/// Responsibility:
/// 1. Listens to the current user's document in Firestore.
/// 2. If the document is deleted (e.g., by an Admin), it immediately logs out the user.
/// 3. Prevents "ghost sessions" where a deleted/deactivated user still has a valid Auth token.
class UserAccessGuard extends StatefulWidget {
  final Widget child;

  const UserAccessGuard({super.key, required this.child});

  @override
  State<UserAccessGuard> createState() => _UserAccessGuardState();
}

class _UserAccessGuardState extends State<UserAccessGuard> {
  StreamSubscription<DocumentSnapshot>? _userDocSubscription;
  final _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    _startListening();
  }

  /// Establishes a Firestore listener on the user's specific profile document.
  void _startListening() {
    final user = _auth.currentUser;
    if (user != null) {
      _userDocSubscription = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .snapshots()
          .listen((snapshot) async {
            // --- Access Check ---
            // If the document no longer exists in Firestore, the account is considered disabled.
            if (!snapshot.exists && mounted) {
              await FirebaseAuthService().logout();

              if (mounted) {
                // Force navigation back to the start and inform the user.
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) => AlertDialog(
                    title: const Text('تم تعطيل الحساب'),
                    content: const Text(
                      'لقد تم تعطيل حسابك أو حذفه من قبل المسؤول.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop(); // Close dialog
                          Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(
                              builder: (_) => const UserSelectionScreen(),
                            ),
                            (route) => false,
                          );
                        },
                        child: const Text('حسناً'),
                      ),
                    ],
                  ),
                );
              }
            }
          });
    }
  }

  @override
  void dispose() {
    _userDocSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
