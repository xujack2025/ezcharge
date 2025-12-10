import 'package:flutter_dotenv/flutter_dotenv.dart';

class APIKey {
  static String get apiKey =>
      dotenv.env['OPENAI_API_KEY_ALT'] ??
      dotenv.env['OPENAI_API_KEY'] ??
      'YOUR_OPENAI_API_KEY_HERE';
}
