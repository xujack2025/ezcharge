import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

import '../core/utils/app_logger.dart';
import '../secrets.dart';

abstract class ChatbotServiceContract {
  Future<String> fetchCurrentCustomerName();

  Future<String> sendMessage(String message);
}

class ChatbotService implements ChatbotServiceContract {
  ChatbotService({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    http.Client? httpClient,
  }) : _auth = auth ?? FirebaseAuth.instance,
       _firestore = firestore ?? FirebaseFirestore.instance,
       _httpClient = httpClient ?? http.Client();

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final http.Client _httpClient;

  @override
  Future<String> fetchCurrentCustomerName() async {
    final phoneNumber = _auth.currentUser?.phoneNumber;
    if (phoneNumber == null || phoneNumber.isEmpty) return '';

    final querySnapshot = await _firestore
        .collection('Customers')
        .where('PhoneNumber', isEqualTo: phoneNumber)
        .limit(1)
        .get();
    if (querySnapshot.docs.isEmpty) return '';

    final data = querySnapshot.docs.first.data();
    final firstName = data['FirstName']?.toString() ?? '';
    final lastName = data['LastName']?.toString() ?? '';
    return '$firstName $lastName'.trim();
  }

  @override
  Future<String> sendMessage(String message) async {
    final uri = Uri.parse('https://api.openai.com/v1/chat/completions');
    final response = await _httpClient.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${Secrets.openAiApiKey}',
      },
      body: json.encode({
        'model': 'gpt-3.5-turbo',
        'messages': [
          {
            'role': 'system',
            'content':
                'You are an EV Charging customer service chatbot for EZCHARGE. '
                'You help customers with EV charging issues like check-in failures, connector problems, payment issues, or slot availability. '
                "If the question is unrelated to EV charging, respond with: 'I can't understand your question'.",
          },
          {'role': 'user', 'content': message},
        ],
        'max_tokens': 500,
      }),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      AppLogger.warning(
        'Chatbot API failed with status ${response.statusCode}',
      );
      throw Exception('Chatbot API failed.');
    }

    final parsedResponse = json.decode(response.body) as Map<String, dynamic>;
    final choices = parsedResponse['choices'];
    if (choices is! List || choices.isEmpty) {
      throw Exception('Chatbot response was empty.');
    }

    final choice = choices.first;
    if (choice is! Map<String, dynamic>) {
      throw Exception('Chatbot response was invalid.');
    }

    final responseMessage = choice['message'];
    if (responseMessage is! Map<String, dynamic>) {
      throw Exception('Chatbot response message was invalid.');
    }

    return responseMessage['content']?.toString().trim() ?? '';
  }
}
