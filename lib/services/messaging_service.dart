import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

enum MessageType { text, file, document }
enum UserRole { student, admin }

class Message {
  final String id;
  final String conversationId;
  final String senderId;
  final String senderName;
  final UserRole senderRole;
  final String recipientId;
  final String content;
  final MessageType type;
  final DateTime sentAt;
  final bool isRead;
  final String? fileUrl;
  final String? fileName;

  Message({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.senderName,
    required this.senderRole,
    required this.recipientId,
    required this.content,
    required this.type,
    required this.sentAt,
    this.isRead = false,
    this.fileUrl,
    this.fileName,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'],
      conversationId: json['conversation_id'],
      senderId: json['sender_id'],
      senderName: json['sender_name'],
      senderRole: UserRole.values.firstWhere(
        (e) => e.toString().split('.').last == json['sender_role'],
      ),
      recipientId: json['recipient_id'],
      content: json['content'],
      type: MessageType.values.firstWhere(
        (e) => e.toString().split('.').last == json['type'],
      ),
      sentAt: DateTime.parse(json['sent_at']),
      isRead: json['is_read'] ?? false,
      fileUrl: json['file_url'],
      fileName: json['file_name'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'conversation_id': conversationId,
      'sender_id': senderId,
      'sender_name': senderName,
      'sender_role': senderRole.toString().split('.').last,
      'recipient_id': recipientId,
      'content': content,
      'type': type.toString().split('.').last,
      'sent_at': sentAt.toIso8601String(),
      'is_read': isRead,
      'file_url': fileUrl,
      'file_name': fileName,
    };
  }
}

class Conversation {
  final String id;
  final String participantId;
  final String participantName;
  final UserRole participantRole;
  final List<Message> messages;
  final DateTime lastMessageAt;
  final int unreadCount;

  Conversation({
    required this.id,
    required this.participantId,
    required this.participantName,
    required this.participantRole,
    required this.messages,
    required this.lastMessageAt,
    required this.unreadCount,
  });

  factory Conversation.fromJson(Map<String, dynamic> json) {
    return Conversation(
      id: json['id'],
      participantId: json['participant_id'],
      participantName: json['participant_name'],
      participantRole: UserRole.values.firstWhere(
        (e) => e.toString().split('.').last == json['participant_role'],
      ),
      messages: (json['messages'] as List?)
              ?.map((m) => Message.fromJson(m))
              .toList() ??
          [],
      lastMessageAt: DateTime.parse(json['last_message_at']),
      unreadCount: json['unread_count'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'participant_id': participantId,
      'participant_name': participantName,
      'participant_role': participantRole.toString().split('.').last,
      'messages': messages.map((m) => m.toJson()).toList(),
      'last_message_at': lastMessageAt.toIso8601String(),
      'unread_count': unreadCount,
    };
  }
}

class MessagingService {
  static const String _baseUrl = 'https://your-api.com';
  static final MessagingService _instance = MessagingService._internal();

  final Map<String, Conversation> _conversations = {};
  final Map<String, StreamController<Message>> _messageStreamControllers = {};
  final StreamController<Conversation> _conversationUpdates =
      StreamController<Conversation>.broadcast();

  MessagingService._internal();

  factory MessagingService() {
    return _instance;
  }

  Future<void> initialize() async {
    // initialization placeholder
  }

  /// Send a text message
  Future<bool> sendMessage({
    required String conversationId,
    required String senderId,
    required String senderName,
    required UserRole senderRole,
    required String recipientId,
    required String content,
  }) async {
    try {
      final message = Message(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        conversationId: conversationId,
        senderId: senderId,
        senderName: senderName,
        senderRole: senderRole,
        recipientId: recipientId,
        content: content,
        type: MessageType.text,
        sentAt: DateTime.now(),
      );

      final response = await http.post(
        Uri.parse('$_baseUrl/api/messages/send'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(message.toJson()),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        _addMessageToConversation(conversationId, message);
        _broadcastMessage(conversationId, message);
        return true;
      }
    } catch (e) {
      debugPrint('Error sending message: $e');
    }
    return false;
  }

  /// Send a file message
  Future<bool> sendFileMessage({
    required String conversationId,
    required String senderId,
    required String senderName,
    required UserRole senderRole,
    required String recipientId,
    required String filePath,
    required String fileName,
  }) async {
    try {
      final fileUrl = await _uploadFile(filePath, fileName);
      if (fileUrl != null) {
        final message = Message(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          conversationId: conversationId,
          senderId: senderId,
          senderName: senderName,
          senderRole: senderRole,
          recipientId: recipientId,
          content: 'Sent a file: $fileName',
          type: MessageType.file,
          sentAt: DateTime.now(),
          fileUrl: fileUrl,
          fileName: fileName,
        );

        final response = await http.post(
          Uri.parse('$_baseUrl/api/messages/send'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(message.toJson()),
        ).timeout(const Duration(seconds: 10));

        if (response.statusCode == 200) {
          _addMessageToConversation(conversationId, message);
          _broadcastMessage(conversationId, message);
          return true;
        }
      }
    } catch (e) {
      debugPrint('Error sending file message: $e');
    }
    return false;
  }

  /// Upload file to server
  Future<String?> _uploadFile(String filePath, String fileName) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$_baseUrl/api/files/upload'),
      );
      request.files.add(await http.MultipartFile.fromPath('file', filePath));
      request.fields['file_name'] = fileName;

      final response = await request.send().timeout(const Duration(seconds: 30));
      if (response.statusCode == 200) {
        final responseData =
            jsonDecode(await response.stream.bytesToString());
        return responseData['file_url'];
      }
    } catch (e) {
      debugPrint('Error uploading file: $e');
    }
    return null;
  }

  /// Get conversation with participant
  Future<Conversation?> getConversation(String participantId) async {
    try {
      final response = await http.get(
        Uri.parse(
            '$_baseUrl/api/conversations?participant_id=$participantId'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = Conversation.fromJson(jsonDecode(response.body));
        _conversations[data.id] = data;
        return data;
      }
    } catch (e) {
      debugPrint('Error fetching conversation: $e');
    }
    return null;
  }

  /// Get all conversations
  Future<List<Conversation>> getAllConversations() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/conversations'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final conversations =
            data.map((c) => Conversation.fromJson(c)).toList();
        for (var conv in conversations) {
          _conversations[conv.id] = conv;
        }
        return conversations;
      }
    } catch (e) {
      debugPrint('Error fetching conversations: $e');
    }
    return [];
  }

  /// Get message stream for conversation
  Stream<Message> getMessageStream(String conversationId) {
    if (!_messageStreamControllers.containsKey(conversationId)) {
      _messageStreamControllers[conversationId] =
          StreamController<Message>.broadcast();
    }
    return _messageStreamControllers[conversationId]!.stream;
  }

  /// Get conversation updates stream
  Stream<Conversation> get conversationUpdates => _conversationUpdates.stream;

  /// Add message to conversation cache
  void _addMessageToConversation(String conversationId, Message message) {
    if (_conversations.containsKey(conversationId)) {
      final conv = _conversations[conversationId]!;
      final updatedMessages = [...conv.messages, message];
      _conversations[conversationId] = Conversation(
        id: conv.id,
        participantId: conv.participantId,
        participantName: conv.participantName,
        participantRole: conv.participantRole,
        messages: updatedMessages,
        lastMessageAt: message.sentAt,
        unreadCount: conv.unreadCount,
      );
      _conversationUpdates.add(_conversations[conversationId]!);
    }
  }

  /// Broadcast message to stream
  void _broadcastMessage(String conversationId, Message message) {
    if (_messageStreamControllers.containsKey(conversationId)) {
      if (!_messageStreamControllers[conversationId]!.isClosed) {
        _messageStreamControllers[conversationId]?.add(message);
      }
    }
  }

  /// Mark message as read
  Future<bool> markMessageAsRead(String messageId) async {
    try {
      final response = await http.put(
        Uri.parse('$_baseUrl/api/messages/$messageId/read'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Error marking message as read: $e');
    }
    return false;
  }

  /// Mark all conversation messages as read
  Future<bool> markConversationAsRead(String conversationId) async {
    try {
      final response = await http.put(
        Uri.parse('$_baseUrl/api/conversations/$conversationId/mark-read'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Error marking conversation as read: $e');
    }
    return false;
  }

  /// Get unread message count
  int getUnreadMessageCount() {
    return _conversations.values.fold(0, (sum, conv) => sum + conv.unreadCount);
  }

  /// Dispose streams
  void dispose() {
    for (var controller in _messageStreamControllers.values) {
      if (!controller.isClosed) {
        controller.close();
      }
    }
    _messageStreamControllers.clear();
    if (!_conversationUpdates.isClosed) {
      _conversationUpdates.close();
    }
  }
}
