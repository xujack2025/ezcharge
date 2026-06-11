import 'dart:convert';

import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

import '../models/location_search_model.dart';
import '../secrets.dart';

abstract class LocationSearchServiceContract {
  Future<List<LocationSuggestion>> fetchAddressSuggestions(String query);

  Future<LocationSelection?> fetchPlaceDetails({
    required String placeId,
    required String description,
  });

  Future<String?> reverseGeocode(LatLng location);
}

class LocationSearchService implements LocationSearchServiceContract {
  LocationSearchService({http.Client? httpClient})
    : _httpClient = httpClient ?? http.Client();

  final http.Client _httpClient;

  @override
  Future<List<LocationSuggestion>> fetchAddressSuggestions(String query) async {
    if (query.isEmpty) return [];

    final url = Uri.parse(
      'https://maps.googleapis.com/maps/api/place/autocomplete/json'
      '?input=${Uri.encodeComponent(query)}'
      '&key=${Secrets.googleMapsApiKey}'
      '&components=country:MY',
    );

    final response = await _httpClient.get(url);
    if (response.statusCode != 200) return [];

    final data = json.decode(response.body) as Map<String, dynamic>;
    final predictions = data['predictions'];
    if (predictions is! List) return [];

    return predictions
        .whereType<Map<String, dynamic>>()
        .map(
          (prediction) => LocationSuggestion(
            placeId: prediction['place_id']?.toString() ?? '',
            description: prediction['description']?.toString() ?? '',
          ),
        )
        .where(
          (suggestion) =>
              suggestion.placeId.isNotEmpty &&
              suggestion.description.isNotEmpty,
        )
        .toList();
  }

  @override
  Future<LocationSelection?> fetchPlaceDetails({
    required String placeId,
    required String description,
  }) async {
    final url = Uri.parse(
      'https://maps.googleapis.com/maps/api/place/details/json'
      '?place_id=${Uri.encodeComponent(placeId)}'
      '&key=${Secrets.googleMapsApiKey}',
    );

    final response = await _httpClient.get(url);
    if (response.statusCode != 200) return null;

    final data = json.decode(response.body) as Map<String, dynamic>;
    final result = data['result'];
    if (result is! Map<String, dynamic>) return null;

    final geometry = result['geometry'];
    if (geometry is! Map<String, dynamic>) return null;

    final location = geometry['Location'] ?? geometry['location'];
    if (location is! Map<String, dynamic>) return null;

    final lat = location['lat'];
    final lng = location['lng'];
    if (lat is! num || lng is! num) return null;

    return LocationSelection(
      location: LatLng(lat.toDouble(), lng.toDouble()),
      address: description,
    );
  }

  @override
  Future<String?> reverseGeocode(LatLng location) async {
    final url = Uri.parse(
      'https://maps.googleapis.com/maps/api/geocode/json'
      '?latlng=${location.latitude},${location.longitude}'
      '&key=${Secrets.googleMapsApiKey}',
    );

    final response = await _httpClient.get(url);
    if (response.statusCode != 200) return null;

    final data = json.decode(response.body) as Map<String, dynamic>;
    final results = data['results'];
    if (results is! List || results.isEmpty) return null;

    final firstResult = results.first;
    if (firstResult is! Map<String, dynamic>) return null;

    return firstResult['formatted_address']?.toString();
  }
}
