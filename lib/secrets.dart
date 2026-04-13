import 'package:flutter_dotenv/flutter_dotenv.dart';

class Secrets {
  static String get googleMapsApiKey => dotenv.env['GOOGLE_MAPS_API_KEY'] ?? '';

  static String get openAiApiKey => dotenv.env['OPENAI_API_KEY'] ?? '';
}
