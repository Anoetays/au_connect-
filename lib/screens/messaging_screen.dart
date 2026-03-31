import 'package:flutter/material.dart';
import 'package:au_connect/services/messaging_service.dart';
import 'package:intl/intl.dart';

class MessagingScreen extends StatefulWidget {
  final String currentUserId;
  final String currentUserName;
  final UserRole currentUserRole;

  const MessagingScreen({
    required this.currentUserId,
    required this.currentUserName,
    required this.currentUserRole,
    Key? key,
  }) : super(key: key);

  @override
  State<MessagingScreen> createState() => _MessagingScreenState();
}

class _MessagingScreenState extends State<MessagingScreen> {
  final MessagingService _messagingService = MessagingService();
  late Future<List<Conversation>> _conversationsFuture;

  @override
  void initState() {
    super.initState();
    _messagingService.initialize();
    _conversationsFuture = _messagingService.getAllConversations();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages'),
        elevation: 0,
      ),
      body: FutureBuilder<List<Conversation>>(
        future: _conversationsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.mail_outline, size: 64, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  Text(
                    'No conversations yet',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) {
              final conversation = snapshot.data![index];
              return _buildConversationTile(context, conversation);
            },
          );
        },
      ),
    );
  }

  Widget _buildConversationTile(
      BuildContext context, Conversation conversation) {
    final lastMessage = conversation.messages.isNotEmpty
        ? conversation.messages.last
        : null;

    return ListTile(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => ConversationDetailScreen(
              conversation: conversation,
              currentUserId: widget.currentUserId,
              currentUserName: widget.currentUserName,
              currentUserRole: widget.currentUserRole,
            ),
          ),
        );
      },
      leading: CircleAvatar(
        child: Text(conversation.participantName[0].toUpperCase()),
      ),
      title: Text(conversation.participantName),
      subtitle: Text(
        lastMessage?.content ?? 'No messages',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontWeight:
              conversation.unreadCount > 0 ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      trailing: conversation.unreadCount > 0
          ? Badge(label: Text(conversation.unreadCount.toString()))
          : null,
    );
  }

  @override
  void dispose() {
    _messagingService.dispose();
    super.dispose();
  }
}

class ConversationDetailScreen extends StatefulWidget {
  final Conversation conversation;
  final String currentUserId;
  final String currentUserName;
  final UserRole currentUserRole;

  const ConversationDetailScreen({
    required this.conversation,
    required this.currentUserId,
    required this.currentUserName,
    required this.currentUserRole,
    Key? key,
  }) : super(key: key);

  @override
  State<ConversationDetailScreen> createState() =>
      _ConversationDetailScreenState();
}

class _ConversationDetailScreenState extends State<ConversationDetailScreen> {
  final MessagingService _messagingService = MessagingService();
  final TextEditingController _messageController = TextEditingController();
  late Stream<Message> _messageStream;
  late List<Message> _messages;

  @override
  void initState() {
    super.initState();
    _messagingService.initialize();
    _messages = List.from(widget.conversation.messages);
    _messageStream = _messagingService.getMessageStream(widget.conversation.id);
    _messagingService.markConversationAsRead(widget.conversation.id);
  }

  void _sendMessage() {
    if (_messageController.text.trim().isEmpty) return;

    _messagingService.sendMessage(
      conversationId: widget.conversation.id,
      senderId: widget.currentUserId,
      senderName: widget.currentUserName,
      senderRole: widget.currentUserRole,
      recipientId: widget.conversation.participantId,
      content: _messageController.text,
    );

    _messageController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.conversation.participantName),
        subtitle: Text(
          widget.conversation.participantRole.toString().split('.').last,
          style: const TextStyle(fontSize: 12),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<Message>(
              stream: _messageStream,
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  _messages.add(snapshot.data!);
                }

                return ListView.builder(
                  reverse: true,
                  itemCount: _messages.length,
                  itemBuilder: (context, index) {
                    final message = _messages[_messages.length - 1 - index];
                    final isCurrentUser =
                        message.senderId == widget.currentUserId;
                    return _buildMessageBubble(message, isCurrentUser);
                  },
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    maxLines: null,
                  ),
                ),
                const SizedBox(width: 8),
                FloatingActionButton(
                  onPressed: _sendMessage,
                  mini: true,
                  child: const Icon(Icons.send),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(Message message, bool isCurrentUser) {
    return Align(
      alignment: isCurrentUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isCurrentUser ? Colors.blue : Colors.grey[300],
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment:
              isCurrentUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (!isCurrentUser)
              Text(
                message.senderName,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            const SizedBox(height: 4),
            Text(
              message.content,
              style: TextStyle(
                color: isCurrentUser ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _formatTime(message.sentAt),
              style: TextStyle(
                fontSize: 10,
                color: isCurrentUser ? Colors.white70 : Colors.black54,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    if (dateTime.day == now.day) {
      return DateFormat('HH:mm').format(dateTime);
    }
    return DateFormat('MM/dd').format(dateTime);
  }

  @override
  void dispose() {
    _messageController.dispose();
    _messagingService.dispose();
    super.dispose();
  }
}
