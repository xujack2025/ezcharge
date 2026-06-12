import 'package:flutter/foundation.dart';

import '../../core/utils/app_logger.dart';
import '../../models/chatbot_model.dart';
import '../../services/chatbot_service.dart';

enum ChatbotSendResult { success, emptyMessage, failed }

class ChatbotViewModel extends ChangeNotifier {
  ChatbotViewModel({ChatbotServiceContract? chatbotService})
    : _chatbotService = chatbotService ?? ChatbotService();

  final ChatbotServiceContract _chatbotService;

  String _customerName = '';
  final List<ChatbotMessage> _messages = [];
  bool _isLoadingCustomer = false;
  bool _isSending = false;
  String? _errorMessage;

  String get customerName => _customerName;
  List<ChatbotMessage> get messages => List.unmodifiable(_messages);
  bool get isLoadingCustomer => _isLoadingCustomer;
  bool get isSending => _isSending;
  String? get errorMessage => _errorMessage;

  Future<void> loadCustomerName() async {
    _setLoadingCustomer(true);
    _errorMessage = null;

    try {
      _customerName = await _chatbotService.fetchCurrentCustomerName();
    } catch (e) {
      AppLogger.error('Error loading chatbot customer: $e');
      _customerName = '';
      _errorMessage = 'Unable to load customer details.';
    } finally {
      _setLoadingCustomer(false);
    }
  }

  Future<ChatbotSendResult> sendMessage(String message) async {
    final trimmedMessage = message.trim();
    if (trimmedMessage.isEmpty) {
      return ChatbotSendResult.emptyMessage;
    }

    _messages.insert(0, ChatbotMessage(text: trimmedMessage, isMe: true));
    _setSending(true);
    _errorMessage = null;

    try {
      final response = await _chatbotService.sendMessage(trimmedMessage);
      _messages.insert(
        0,
        ChatbotMessage(
          text: response.isEmpty
              ? "I can't understand your question"
              : response,
          isMe: false,
        ),
      );
      return ChatbotSendResult.success;
    } catch (e) {
      AppLogger.error('Error fetching chatbot response: $e');
      _errorMessage = 'Unable to reach customer service. Please try again.';
      _messages.insert(
        0,
        const ChatbotMessage(
          text: "I can't understand your question",
          isMe: false,
        ),
      );
      return ChatbotSendResult.failed;
    } finally {
      _setSending(false);
    }
  }

  void _setLoadingCustomer(bool value) {
    _isLoadingCustomer = value;
    notifyListeners();
  }

  void _setSending(bool value) {
    _isSending = value;
    notifyListeners();
  }
}
