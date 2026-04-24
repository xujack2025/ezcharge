import 'package:url_launcher/url_launcher.dart';

import 'package:ezcharge/core/utils/app_logger.dart';

class MapUtils {
  MapUtils._();

  static Future<void> openMap(double latitude, double longitude) async {
    final Uri googleMapUri = Uri.parse(
      "https://www.google.com/maps/search/?api=1&query=$latitude,$longitude",
    );

    if (await canLaunchUrl(googleMapUri)) {
      await launchUrl(googleMapUri, mode: LaunchMode.externalApplication);
    } else {
      AppLogger.error('Could not open the Map: $googleMapUri');
      throw Exception('Map launcher failed');
    }
  }
}
