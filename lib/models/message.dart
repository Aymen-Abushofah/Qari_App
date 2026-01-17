import 'package:cloud_firestore/cloud_firestore.dart';

/// Message: Represents a single chat message in the p2p communication system (Sheikh <-> Parent).
///
/// Data fields include:
/// - [senderId] / [receiverId]: UIDs of the users involved.
/// - [content]: The text content of the message.
/// - [timestamp]: When the message was sent (handled as Firestore Timestamp).
/// - [studentId]: Optional link if the message is specifically about one student.
class Message {
  final String id;
  final String senderId;
  final String receiverId;
  final String content;
  final DateTime timestamp;
  final bool isRead;
  final String? studentId;

  const Message({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.content,
    required this.timestamp,
    this.isRead = false,
    this.studentId,
  });

  /// Creates a copy of this message with some fields replaced.
  Message copyWith({
    String? id,
    String? senderId,
    String? receiverId,
    String? content,
    DateTime? timestamp,
    bool? isRead,
    String? studentId,
  }) {
    return Message(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      receiverId: receiverId ?? this.receiverId,
      content: content ?? this.content,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      studentId: studentId ?? this.studentId,
    );
  }

  /// Converts this object into a Map for storage in Firestore.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'senderId': senderId,
      'receiverId': receiverId,
      'content': content,
      'timestamp': timestamp,
      'isRead': isRead,
      'studentId': studentId,
    };
  }

  /// Creates a Message object from a Firestore document Map.
  /// Handles different timestamp formats (Firestore Timestamp vs ISO String).
  factory Message.fromMap(Map<String, dynamic> map, {String? docId}) {
    DateTime parseTimestamp(dynamic ts) {
      if (ts is Timestamp) return ts.toDate();
      if (ts is String) return DateTime.parse(ts);
      return DateTime.now();
    }

    return Message(
      id: docId ?? map['id'] as String? ?? '',
      senderId: map['senderId'] as String? ?? '',
      receiverId: map['receiverId'] as String? ?? '',
      content: map['content'] as String? ?? '',
      timestamp: parseTimestamp(map['timestamp']),
      isRead: map['isRead'] as bool? ?? false,
      studentId: map['studentId'] as String?,
    );
  }
}

/// Conversation: A lightweight summary model used to display a list of
/// unique chat partners in the messaging inbox.
class Conversation {
  final String id;
  final String parentId;
  final String parentName;
  final String lastMessage;
  final DateTime lastMessageTime;
  final int unreadCount;

  const Conversation({
    required this.id,
    required this.parentId,
    required this.parentName,
    required this.lastMessage,
    required this.lastMessageTime,
    this.unreadCount = 0,
  });
}
