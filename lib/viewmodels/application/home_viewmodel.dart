import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../core/utils/app_logger.dart';
import '../../models/home_station_model.dart';
import '../../services/home_service.dart';
import '../../services/location_service.dart';

class HomeViewModel extends ChangeNotifier {
  HomeViewModel({
    HomeServiceContract? homeService,
    LocationServiceContract? locationService,
  }) : _homeService = homeService ?? HomeService(),
       _locationService = locationService ?? LocationService();

  final HomeServiceContract _homeService;
  final LocationServiceContract _locationService;

  static const LatLng defaultLocation = LatLng(
    3.2197929237993033,
    101.6437936423279,
  );

  final Map<String, BookmarkStatus> _bookmarkStatuses = {};
  List<HomeStation> _stations = [];
  List<HomeStation> _filteredStations = [];
  LatLng _currentLocation = defaultLocation;
  bool _isLoading = false;
  bool _isLocationLoading = false;
  String? _errorMessage;
  String? _locationErrorMessage;

  List<HomeStation> get stations => List.unmodifiable(_stations);
  List<HomeStation> get filteredStations =>
      List.unmodifiable(_filteredStations);
  LatLng get currentLocation => _currentLocation;
  bool get isLoading => _isLoading;
  bool get isLocationLoading => _isLocationLoading;
  String? get errorMessage => _errorMessage;
  String? get locationErrorMessage => _locationErrorMessage;

  Future<LatLng?> loadCurrentLocation() async {
    _setLocationLoading(true);
    _locationErrorMessage = null;

    try {
      final location = await _locationService.getCurrentLocation();
      if (location == null) {
        _locationErrorMessage = "Location permission is unavailable.";
        return null;
      }

      _currentLocation = location;
      notifyListeners();
      return location;
    } catch (e) {
      AppLogger.error("Error getting location: $e");
      _locationErrorMessage = "Failed to load your location.";
      return null;
    } finally {
      _setLocationLoading(false);
    }
  }

  Future<void> loadStations({String customerId = ""}) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      _stations = await _homeService.fetchStations();
      _filteredStations = _stations;

      if (customerId.isNotEmpty) {
        await _loadBookmarkStatuses(customerId);
      }
    } catch (e) {
      AppLogger.error("Error fetching home stations: $e");
      _errorMessage = "Failed to load stations.";
      _stations = [];
      _filteredStations = [];
    } finally {
      _setLoading(false);
    }
  }

  void filterStations(String query) {
    if (query.isEmpty) {
      _filteredStations = _stations;
    } else {
      final matches = _stations
          .where((station) => station.matchesSearch(query))
          .toList();
      _filteredStations = matches.isNotEmpty ? [matches.first] : [];
    }
    notifyListeners();
  }

  void applyFilters(String power, List<String> nearby) {
    if (power.isEmpty && nearby.isEmpty) {
      _filteredStations = _stations;
    } else {
      _filteredStations = _stations.where((station) {
        return station.matchesPower(power) && station.matchesNearby(nearby);
      }).toList();
    }
    notifyListeners();
  }

  bool isBookmarked(String stationId) {
    return _bookmarkStatuses[stationId]?.isBookmarked ?? false;
  }

  Future<bool> toggleBookmark({
    required String customerId,
    required HomeStation station,
  }) async {
    if (customerId.isEmpty) return false;

    try {
      final currentStatus =
          _bookmarkStatuses[station.stationId] ??
          await _homeService.getBookmarkStatus(
            customerId: customerId,
            stationId: station.stationId,
          );

      if (currentStatus.isBookmarked) {
        await _homeService.removeBookmark(
          customerId: customerId,
          bookmarkId: currentStatus.bookmarkId,
        );
        _bookmarkStatuses[station.stationId] = const BookmarkStatus(
          isBookmarked: false,
        );
        notifyListeners();
        return false;
      }

      final newStatus = await _homeService.addBookmark(
        customerId: customerId,
        stationId: station.stationId,
      );
      _bookmarkStatuses[station.stationId] = newStatus;
      notifyListeners();
      return true;
    } catch (e) {
      AppLogger.error("Error toggling bookmark: $e");
      _errorMessage = "Failed to update bookmark.";
      notifyListeners();
      return false;
    }
  }

  Future<void> _loadBookmarkStatuses(String customerId) async {
    _bookmarkStatuses.clear();
    for (final station in _stations) {
      _bookmarkStatuses[station.stationId] = await _homeService
          .getBookmarkStatus(
            customerId: customerId,
            stationId: station.stationId,
          );
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setLocationLoading(bool value) {
    _isLocationLoading = value;
    notifyListeners();
  }
}
