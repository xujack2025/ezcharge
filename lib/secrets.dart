import 'package:flutter_dotenv/flutter_dotenv.dart';

class Secrets {
  static String googleMapsApiKey =
      dotenv.env['GOOGLE_MAPS_API_KEY'] ?? 'YOUR_GOOGLE_MAPS_API_KEY_HERE';
}

String get OPENAI_API_KEY =>
    dotenv.env['OPENAI_API_KEY'] ?? 'YOUR_OPENAI_API_KEY_HERE';
