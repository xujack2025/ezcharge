import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../models/home_station_model.dart';

class HomeStationMarkers {
  const HomeStationMarkers._();

  static Set<Marker> fromStations(List<HomeStation> stations) {
    final markers = <Marker>{};

    for (final station in stations) {
      if (station.latitude == null || station.longitude == null) {
        continue;
      }

      markers.add(
        Marker(
          markerId: MarkerId(station.stationId),
          position: LatLng(station.latitude!, station.longitude!),
          infoWindow: InfoWindow(title: station.stationName),
        ),
      );
    }

    return markers;
  }
}
