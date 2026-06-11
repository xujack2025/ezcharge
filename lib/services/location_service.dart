import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';

abstract class LocationServiceContract {
  Future<LatLng?> getCurrentLocation();
}

class LocationService implements LocationServiceContract {
  LocationService({Location? location}) : _location = location ?? Location();

  final Location _location;

  @override
  Future<LatLng?> getCurrentLocation() async {
    var serviceEnabled = await _location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await _location.requestService();
      if (!serviceEnabled) {
        return null;
      }
    }

    var permissionGranted = await _location.hasPermission();
    if (permissionGranted == PermissionStatus.denied) {
      permissionGranted = await _location.requestPermission();
      if (permissionGranted != PermissionStatus.granted) {
        return null;
      }
    }

    final locationData = await _location.getLocation();
    final latitude = locationData.latitude;
    final longitude = locationData.longitude;

    if (latitude == null || longitude == null) {
      return null;
    }

    return LatLng(latitude, longitude);
  }
}
