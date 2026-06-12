import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../models/chatbot_model.dart';
import '../../../../viewmodels/application/chatbot_viewmodel.dart';

class ChatbotScreen extends StatelessWidget {
  const ChatbotScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ChatbotViewModel()..loadCustomerName(),
      child: const _ChatbotContent(),
    );
  }
}

class _ChatbotContent extends StatefulWidget {
  const _ChatbotContent();

  @override
  State<_ChatbotContent> createState() => _ChatbotContentState();
}

class _ChatbotContentState extends State<_ChatbotContent> {
  final TextEditingController _textEditingController = TextEditingController();

  @override
  void dispose() {
    _textEditingController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final text = _textEditingController.text;
    _textEditingController.clear();
    final result = await context.read<ChatbotViewModel>().sendMessage(text);
    if (!mounted || result != ChatbotSendResult.emptyMessage) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Please enter a message.')));
  }

  Widget _buildMessage(ChatbotMessage message, String customerName) {
    final alignment = message.isMe
        ? MainAxisAlignment.end
        : MainAxisAlignment.start;
    final bgColor = message.isMe ? Colors.blue[50] : Colors.grey[200];
    const textColor = Colors.black87;
    final borderRadius = BorderRadius.only(
      topLeft: const Radius.circular(12),
      topRight: const Radius.circular(12),
      bottomLeft: message.isMe
          ? const Radius.circular(12)
          : const Radius.circular(0),
      bottomRight: message.isMe
          ? const Radius.circular(0)
          : const Radius.circular(12),
    );

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 8),
      child: Row(
        mainAxisAlignment: alignment,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!message.isMe) ...[
            const CircleAvatar(
              radius: 16,
              backgroundImage: AssetImage('assets/images/ezcharge_logo.png'),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: borderRadius,
              ),
              child: Column(
                crossAxisAlignment: message.isMe
                    ? CrossAxisAlignment.end
                    : CrossAxisAlignment.start,
                children: [
                  Text(
                    message.isMe
                        ? (customerName.isEmpty ? 'Guest' : customerName)
                        : 'EZCHARGE Customer Service',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: textColor.withValues(alpha: 0.8),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(message.text, style: const TextStyle(color: textColor)),
                ],
              ),
            ),
          ),
          if (message.isMe) ...[
            const SizedBox(width: 8),
            const CircleAvatar(
              radius: 16,
              backgroundColor: Colors.grey,
              child: Icon(Icons.person, color: Colors.white, size: 18),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<ChatbotViewModel>();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue[900],
        title: const Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundImage: AssetImage('assets/images/ezcharge_logo.png'),
            ),
            SizedBox(width: 8),
            Text(
              'EZCHARGE Help Center',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: <Widget>[
          if (viewModel.isSending || viewModel.isLoadingCustomer)
            const LinearProgressIndicator(),
          Expanded(
            child: ListView.builder(
              reverse: true,
              itemCount: viewModel.messages.length,
              itemBuilder: (context, index) {
                return _buildMessage(
                  viewModel.messages[index],
                  viewModel.customerName,
                );
              },
            ),
          ),
          const Divider(height: 1.0),
          Container(
            decoration: BoxDecoration(color: Theme.of(context).cardColor),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: TextField(
                    controller: _textEditingController,
                    decoration: const InputDecoration(
                      contentPadding: EdgeInsets.all(10.0),
                      hintText: 'Type a message...',
                      border: InputBorder.none,
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: viewModel.isSending ? null : _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
