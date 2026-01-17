import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/app_strings.dart';
import '../../services/firestore_service.dart';
import '../../services/firebase_auth_service.dart';
import '../../models/message.dart';
import 'package:rxdart/rxdart.dart';

/// MessagesScreen: A real-time chat interface for Sheikhs to communicate with parents.
///
/// Features:
/// 1. Conversation List: Automatic grouping of messages by parent.
/// 2. Real-time Messaging: Stream-based message updates using Firestore.
/// 3. Message Threading: Dynamic message bubbling with sender identification.
/// 4. New Conversations: Built-in dialog to start chats with any registered parent.
class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  final _firestoreService = FirestoreService();
  final _authService = FirebaseAuthService();
  String? _selectedConversationId;

  @override
  Widget build(BuildContext context) {
    final currentUserId = _authService.currentUser?.uid ?? '';

    return StreamBuilder<List<dynamic>>(
      stream: CombineLatestStream.list([
        _firestoreService.getConversations(currentUserId),
        _firestoreService.getParents(),
      ]),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final allMessagesData =
            snapshot.data?[0] as List<Map<String, dynamic>>? ?? [];
        final parentsData =
            snapshot.data?[1] as List<Map<String, dynamic>>? ?? [];

        // Derive conversations from messages
        final conversations = _deriveConversations(
          allMessagesData,
          parentsData,
          currentUserId,
        );

        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          appBar: AppBar(
            title: Text(
              AppStrings.messages,
              style: GoogleFonts.tajawal(fontWeight: FontWeight.bold),
            ),
            automaticallyImplyLeading: false,
            elevation: 0,
            actions: [
              IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.search, size: 20),
                ),
                onPressed: () {},
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: conversations.isEmpty && _selectedConversationId == null
              ? _buildEmptyState()
              : _selectedConversationId != null
              ? _buildChatView(_selectedConversationId!, parentsData)
              : _buildConversationsList(conversations),
          floatingActionButton: _selectedConversationId == null
              ? FloatingActionButton(
                  onPressed: () => _showNewMessageDialog(parentsData),
                  backgroundColor: AppTheme.primaryColor,
                  child: const Icon(Icons.edit_rounded),
                )
              : null,
        );
      },
    );
  }

  /// Process raw messages and parent data into a list of [Conversation] summaries.
  /// Groups messages by the parent's UID and finds the latest entry for the preview.
  List<Conversation> _deriveConversations(
    List<Map<String, dynamic>> messages,
    List<Map<String, dynamic>> parents,
    String currentUserId,
  ) {
    final Map<String, List<Message>> groupedMessages = {};

    for (var msgMap in messages) {
      final msg = Message.fromMap(msgMap);
      final otherId = msg.senderId == currentUserId
          ? msg.receiverId
          : msg.senderId;
      groupedMessages.putIfAbsent(otherId, () => []).add(msg);
    }

    final List<Conversation> convs = [];

    groupedMessages.forEach((otherId, msgs) {
      final parent = parents.where((p) => p['uid'] == otherId).firstOrNull;
      if (parent != null) {
        final lastMsg = msgs.reduce(
          (a, b) => a.timestamp.isAfter(b.timestamp) ? a : b,
        );
        final unreadCount = msgs
            .where((m) => m.receiverId == currentUserId && !m.isRead)
            .length;

        convs.add(
          Conversation(
            id: otherId,
            parentId: otherId,
            parentName: parent['name'] ?? 'ولي أمر',
            lastMessage: lastMsg.content,
            lastMessageTime: lastMsg.timestamp,
            unreadCount: unreadCount,
          ),
        );
      }
    });

    convs.sort((a, b) => b.lastMessageTime.compareTo(a.lastMessageTime));
    return convs;
  }

  /// UI shown when there are no active conversations.
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.message_rounded,
              size: 48,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'لا توجد محادثات',
            style: GoogleFonts.tajawal(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'ابدأ محادثة جديدة مع أولياء الأمور',
            style: GoogleFonts.tajawal(color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildConversationsList(List<Conversation> conversations) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: conversations.length,
      itemBuilder: (context, index) {
        final conv = conversations[index];
        return _buildConversationTile(conv);
      },
    );
  }

  /// Builds a clickable list tile for a conversation preview.
  Widget _buildConversationTile(Conversation conv) {
    final hasUnread = conv.unreadCount > 0;
    final timeText = _formatTime(conv.lastMessageTime);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => setState(() => _selectedConversationId = conv.parentId),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Avatar with online indicator
                Stack(
                  children: [
                    Container(
                      width: 55,
                      height: 55,
                      decoration: BoxDecoration(
                        gradient: AppTheme.primaryGradient,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          conv.parentName.substring(0, 1),
                          style: GoogleFonts.amiri(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 2,
                      right: 2,
                      child: Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          color: AppTheme.successColor,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 14),
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            conv.parentName,
                            style: GoogleFonts.tajawal(
                              fontWeight: hasUnread
                                  ? FontWeight.bold
                                  : FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                          Text(
                            timeText,
                            style: GoogleFonts.tajawal(
                              fontSize: 11,
                              color: hasUnread
                                  ? AppTheme.primaryColor
                                  : AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              conv.lastMessage,
                              style: GoogleFonts.tajawal(
                                fontSize: 13,
                                color: hasUnread
                                    ? AppTheme.textPrimary
                                    : AppTheme.textSecondary,
                                fontWeight: hasUnread
                                    ? FontWeight.w500
                                    : FontWeight.normal,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (hasUnread) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryColor,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${conv.unreadCount}',
                                style: GoogleFonts.tajawal(
                                  fontSize: 11,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// The main chat interface shown once a conversation is selected.
  Widget _buildChatView(String parentId, List<Map<String, dynamic>> parents) {
    final currentUserId = _authService.currentUser?.uid ?? '';
    final parentData = parents.where((p) => p['uid'] == parentId).firstOrNull;
    final messageController = TextEditingController();

    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _firestoreService.getMessages(currentUserId, parentId),
      builder: (context, snapshot) {
        final messages =
            snapshot.data?.map((m) => Message.fromMap(m)).toList() ?? [];

        return Column(
          children: [
            // Chat header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => setState(() => _selectedConversationId = null),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Theme.of(context).scaffoldBackgroundColor,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.arrow_forward_ios,
                        size: 18,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    width: 45,
                    height: 45,
                    decoration: BoxDecoration(
                      gradient: AppTheme.primaryGradient,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        parentData?['name']?.substring(0, 1) ?? '?',
                        style: GoogleFonts.amiri(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontSize: 18,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          parentData?['name'] ?? 'غير معروف',
                          style: GoogleFonts.tajawal(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: AppTheme.successColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'متصل الآن',
                              style: GoogleFonts.tajawal(
                                fontSize: 11,
                                color: AppTheme.successColor,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.phone_rounded,
                      color: AppTheme.primaryColor,
                    ),
                    onPressed: () {},
                  ),
                  IconButton(
                    icon: Icon(Icons.more_vert, color: AppTheme.textSecondary),
                    onPressed: () {},
                  ),
                ],
              ),
            ),
            // Messages
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  image: DecorationImage(
                    image: const AssetImage('assets/chat_bg.png'),
                    fit: BoxFit.cover,
                    opacity: 0.05,
                    onError: (_, __) {},
                  ),
                ),
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    final isMe = msg.senderId == currentUserId;
                    return _buildMessageBubble(msg, isMe);
                  },
                ),
              ),
            ),
            // Input field
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SafeArea(
                child: Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).scaffoldBackgroundColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: IconButton(
                        icon: Icon(
                          Icons.attach_file_rounded,
                          color: AppTheme.textSecondary,
                        ),
                        onPressed: () {},
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Theme.of(context).scaffoldBackgroundColor,
                          borderRadius: BorderRadius.circular(25),
                        ),
                        child: TextField(
                          controller: messageController,
                          textDirection: TextDirection.rtl,
                          style: GoogleFonts.tajawal(),
                          decoration: InputDecoration(
                            hintText: 'اكتب رسالتك...',
                            hintStyle: GoogleFonts.tajawal(
                              color: AppTheme.textSecondary,
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      decoration: BoxDecoration(
                        gradient: AppTheme.primaryGradient,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primaryColor.withValues(alpha: 0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: IconButton(
                        icon: const Icon(
                          Icons.send_rounded,
                          color: Colors.white,
                        ),
                        onPressed: () async {
                          if (messageController.text.isNotEmpty) {
                            final text = messageController.text;
                            messageController.clear();
                            final msg = Message(
                              id: '',
                              senderId: currentUserId,
                              receiverId: parentId,
                              content: text,
                              timestamp: DateTime.now(),
                              isRead: false,
                            );
                            await _firestoreService.sendMessage(msg.toMap());
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  /// Renders an individual message bubble with directional styling based on the sender.
  Widget _buildMessageBubble(Message msg, bool isMe) {
    return Align(
      alignment: isMe ? Alignment.centerLeft : Alignment.centerRight,
      child: Container(
        margin: EdgeInsets.only(
          bottom: 8,
          left: isMe ? 0 : 50,
          right: isMe ? 50 : 0,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          gradient: isMe ? AppTheme.primaryGradient : null,
          color: isMe ? null : Theme.of(context).cardColor,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: Radius.circular(isMe ? 5 : 20),
            bottomRight: Radius.circular(isMe ? 20 : 5),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: isMe
              ? CrossAxisAlignment.start
              : CrossAxisAlignment.end,
          children: [
            Text(
              msg.content,
              style: GoogleFonts.tajawal(
                color: isMe ? Colors.white : AppTheme.textPrimary,
                fontSize: 14,
              ),
              textDirection: TextDirection.rtl,
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _formatTime(msg.timestamp),
                  style: GoogleFonts.tajawal(
                    fontSize: 10,
                    color: isMe ? Colors.white70 : AppTheme.textSecondary,
                  ),
                ),
                if (isMe) ...[
                  const SizedBox(width: 4),
                  Icon(
                    msg.isRead ? Icons.done_all : Icons.done,
                    size: 14,
                    color: msg.isRead ? Colors.lightBlueAccent : Colors.white70,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Modal dialog to select a parent and start a new chat session.
  void _showNewMessageDialog(List<Map<String, dynamic>> parents) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.edit, color: AppTheme.primaryColor),
                ),
                const SizedBox(width: 12),
                Text(
                  'رسالة جديدة',
                  style: GoogleFonts.tajawal(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              'اختر ولي الأمر',
              style: GoogleFonts.tajawal(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 200,
              child: ListView.builder(
                itemCount: parents.length,
                itemBuilder: (context, index) {
                  final parent = parents[index];
                  return ListTile(
                    leading: Container(
                      width: 45,
                      height: 45,
                      decoration: BoxDecoration(
                        gradient: AppTheme.primaryGradient,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          (parent['name'] as String? ?? '?').substring(0, 1),
                          style: GoogleFonts.tajawal(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    title: Text(
                      parent['name'] ?? '',
                      style: GoogleFonts.tajawal(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      parent['phone'] ?? '',
                      style: GoogleFonts.tajawal(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    trailing: Icon(
                      Icons.chevron_left,
                      color: AppTheme.textSecondary,
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      setState(() => _selectedConversationId = parent['uid']);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Utility to format the message timestamp into a relative "friendly" Arabic string.
  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inMinutes < 1) return 'الآن';
    if (diff.inMinutes < 60) return 'منذ ${diff.inMinutes} دقيقة';
    if (diff.inHours < 24) return 'منذ ${diff.inHours} ساعة';
    if (diff.inDays < 7) return 'منذ ${diff.inDays} يوم';
    return '${time.day}/${time.month}';
  }
}
