import 'package:ezcharge/services/chatbot_service.dart';
import 'package:ezcharge/viewmodels/application/chatbot_viewmodel.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeChatbotService implements ChatbotServiceContract {
  String customerName = 'Jane Doe';
  String response = 'Please check your connector.';
  Object? error;
  String? sentMessage;

  @override
  Future<String> fetchCurrentCustomerName() async {
    final error = this.error;
    if (error != null) throw error;
    return customerName;
  }

  @override
  Future<String> sendMessage(String message) async {
    final error = this.error;
    if (error != null) throw error;
    sentMessage = message;
    return response;
  }
}

void main() {
  group('ChatbotViewModel', () {
    test('loads customer name and sends message through service', () async {
      final service = _FakeChatbotService();
      final viewModel = ChatbotViewModel(chatbotService: service);

      await viewModel.loadCustomerName();
      final result = await viewModel.sendMessage('Connector issue');

      expect(viewModel.customerName, 'Jane Doe');
      expect(result, ChatbotSendResult.success);
      expect(service.sentMessage, 'Connector issue');
      expect(viewModel.messages, hasLength(2));
      expect(viewModel.messages.first.text, 'Please check your connector.');
      expect(viewModel.messages.last.text, 'Connector issue');
    });

    test('blocks empty messages', () async {
      final service = _FakeChatbotService();
      final viewModel = ChatbotViewModel(chatbotService: service);

      final result = await viewModel.sendMessage('   ');

      expect(result, ChatbotSendResult.emptyMessage);
      expect(service.sentMessage, isNull);
      expect(viewModel.messages, isEmpty);
    });

    test('adds fallback response when service fails', () async {
      final service = _FakeChatbotService()..error = Exception('network');
      final viewModel = ChatbotViewModel(chatbotService: service);

      final result = await viewModel.sendMessage('Help');

      expect(result, ChatbotSendResult.failed);
      expect(
        viewModel.errorMessage,
        'Unable to reach customer service. Please try again.',
      );
      expect(viewModel.messages.first.text, "I can't understand your question");
    });
  });
}
