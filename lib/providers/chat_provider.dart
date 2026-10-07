import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/user_model.dart';
import '../models/message_model.dart';

class ChatConversation {
  final UserModel otherUser;
  final String lastMessage;
  final DateTime lastMessageTime;
  final int unreadCount;

  ChatConversation({
    required this.otherUser,
    required this.lastMessage,
    required this.lastMessageTime,
    required this.unreadCount,
  });

  factory ChatConversation.fromJson(Map<String, dynamic> json) {
    return ChatConversation(
      otherUser: UserModel.fromJson(json['user']),
      lastMessage: json['last_message'] ?? '',
      lastMessageTime: json['last_message_time'] != null
          ? DateTime.parse(json['last_message_time'])
          : DateTime.now(),
      unreadCount: json['unread_count'] ?? 0,
    );
  }
}

class ChatProvider with ChangeNotifier {
  List<UserModel> _users = [];
  List<ChatConversation> _conversations = [];
  List<MessageModel> _messages = [];
  bool _isLoading = false;
  String? _error;

  List<UserModel> get users => _users;
  List<ChatConversation> get conversations => _conversations;
  List<MessageModel> get messages => _messages;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Load active chats
  Future<bool> loadConversations() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await ApiServices.getConversations();

      if (response['success'] == true) {
        final dynamic rawData = response['data'];
        List<dynamic> dataList = [];

        if (rawData is List) {
          dataList = rawData;
        } else if (rawData is Map && rawData['data'] is List) {
          dataList = rawData['data'] as List;
        }

        _conversations = dataList.map((item) => ChatConversation.fromJson(item)).toList();
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = response['message'] ?? 'Failed to load conversations';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Load message history with a specific user
  Future<bool> loadMessagesWith(int otherUserId) async {
    _error = null;
    try {
      final response = await ApiServices.getMessagesWith(otherUserId);

      if (response['success'] == true) {
        final dynamic rawData = response['data'];
        List<dynamic> dataList = [];

        if (rawData is List) {
          dataList = rawData;
        } else if (rawData is Map && rawData['data'] is List) {
          dataList = rawData['data'] as List;
        }

        _messages = dataList.map((item) => MessageModel.fromJson(item)).toList();
        notifyListeners();
        return true;
      } else {
        _error = response['message'] ?? 'Failed to load messages';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Send message
  Future<bool> sendMessage(int receiverId, String content) async {
    try {
      final response = await ApiServices.sendMessage(receiverId, content);
      debugPrint("CHAT_PROVIDER sendMessage response success: ${response['success']}");

      if (response['success'] == true) {
        // Append sent message to local list immediately for seamless feel
        final dynamic rawMsg = response['data'];
        if (rawMsg != null) {
          final Map<String, dynamic> msgData = (rawMsg is Map && rawMsg['data'] is Map)
              ? Map<String, dynamic>.from(rawMsg['data'])
              : (rawMsg is Map ? Map<String, dynamic>.from(rawMsg) : {});
          
          if (msgData.isNotEmpty) {
            final newMsg = MessageModel.fromJson(msgData);
            _messages.add(newMsg);
          }
        }
        notifyListeners();
        // Background reload conversations
        loadConversations();
        return true;
      } else {
        _error = response['message'] ?? 'Failed to send message';
        debugPrint("CHAT_PROVIDER sendMessage failed message: $_error");
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = e.toString();
      debugPrint("CHAT_PROVIDER sendMessage exception: $_error");
      notifyListeners();
      return false;
    }
  }

  // Load users for starting a new chat
  Future<bool> loadAllUsers() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await ApiServices.getAdminUsers();
      debugPrint("CHAT_PROVIDER loadAllUsers success: ${response['success']}");
      debugPrint("CHAT_PROVIDER loadAllUsers message: ${response['message']}");
      debugPrint("CHAT_PROVIDER loadAllUsers rawData type: ${response['data']?.runtimeType}");

      if (response['success'] == true) {
        final dynamic rawData = response['data'];
        List<dynamic> dataList = [];

        if (rawData is List) {
          dataList = rawData;
        } else if (rawData is Map && rawData['data'] is List) {
          dataList = rawData['data'] as List;
        }

        _users = dataList.map((item) => UserModel.fromJson(item)).toList();
        debugPrint("CHAT_PROVIDER successfully parsed ${_users.length} users");
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = response['message'] ?? 'Failed to load contact directory';
        debugPrint("CHAT_PROVIDER loadAllUsers failed: $_error");
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = e.toString();
      debugPrint("CHAT_PROVIDER loadAllUsers exception: $_error");
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}
