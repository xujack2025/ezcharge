import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:provider/provider.dart';

import '../../core/constants/colors.dart';
import '../../core/constants/text_styles.dart';
import '../../core/utils/app_logger.dart';
import '../../models/home_station_model.dart';
import '../../viewmodels/application/application_viewmodel.dart';
import '../../viewmodels/application/home_viewmodel.dart';
import '../../viewmodels/auth/auth_viewmodel.dart';
import 'customer/ezcharge/filter_screen.dart';
import 'customer/ezcharge/reservation_screen.dart';
import 'customer/ezcharge/station_screen.dart';
import 'widgets/home_station_markers.dart';
import 'widgets/home_station_sheet.dart';
import 'widgets/home_top_nav_bar.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  AuthViewModel get _authViewModel => context.read<AuthViewModel>();
  HomeViewModel get _homeViewModel => context.read<HomeViewModel>();

  final Completer<GoogleMapController> _controller = Completer();
  final Location _location = Location();
  LatLng _currentLocation = const LatLng(
    3.2197929237993033,
    101.6437936423279,
  ); // Default: KL

  // Search Controller
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _getUserLocation();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadHomeData();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadHomeData() async {
    await _authViewModel.syncUserStatus();
    await _homeViewModel.loadStations(customerId: _authViewModel.customerId);
  }

  void _showAuthReminder(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Authentication Required"),
        content: const Text(
          "Please authenticate your account before making a reservation.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context), // Close dialog
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  void _showReservationReminder(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Existing Reservation"),
        content: const Text(
          "You already have an upcoming or active reservation. "
          "Please complete or cancel it before making a new one.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  Future<void> _getUserLocation() async {
    try {
      bool serviceEnabled;
      PermissionStatus permissionGranted;

      // Check if location services are enabled
      serviceEnabled = await _location.serviceEnabled();
      if (!serviceEnabled) {
        serviceEnabled = await _location.requestService();
        if (!serviceEnabled) {
          AppLogger.warning("Location services are disabled.");
          return;
        }
      }

      //Check location permissions
      permissionGranted = await _location.hasPermission();
      if (permissionGranted == PermissionStatus.denied) {
        permissionGranted = await _location.requestPermission();
        if (permissionGranted != PermissionStatus.granted) {
          AppLogger.warning("Location permission denied.");
          return;
        }
      }

      // Get the current user location
      LocationData locationData = await _location.getLocation();
      if (!mounted) return;
      LatLng userLocation = LatLng(
        locationData.latitude!,
        locationData.longitude!,
      );

      setState(() {
        _currentLocation = userLocation;
      });

      //Move camera to user's location
      final GoogleMapController controller = await _controller.future;
      controller.animateCamera(
        CameraUpdate.newLatLngZoom(_currentLocation, 14),
      );
    } catch (e) {
      AppLogger.error("Error getting location: $e");
    }
  }

  /*Future<void> _moveCamera(LatLng position) async {
    final GoogleMapController controller = await _controller.future;
    controller.animateCamera(CameraUpdate.newLatLngZoom(position, 14));
  }*/

  @override
  Widget build(BuildContext context) {
    final authVM = context.watch<AuthViewModel>();
    final appVM = context.watch<ApplicationViewmodel>();
    final homeVM = context.watch<HomeViewModel>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        elevation: 0,
        backgroundColor: AppColors.black,
        title: Text(
          "EZCHARGE",
          style: AppTextStyles.headlineMedium.copyWith(
            color: AppColors.white,
            letterSpacing: 2,
          ),
        ),
      ),
      body: Stack(
        children: [
          // Google Map
          Positioned(
            top: 30,
            left: 0,
            right: 0,
            bottom: 0,
            child: GoogleMap(
              onMapCreated: (GoogleMapController controller) {
                if (!_controller.isCompleted) {
                  _controller.complete(controller);
                }
              },
              initialCameraPosition: CameraPosition(
                target: _currentLocation,
                zoom: 14.0,
              ),
              myLocationEnabled: true,
              myLocationButtonEnabled: false,
              markers: HomeStationMarkers.fromStations(homeVM.stations),
            ),
          ),

          // Top Navigation Buttons
          Container(width: double.infinity, height: 30, color: AppColors.black),
          Positioned(
            top: 0,
            left: 20,
            right: 20,
            child: HomeTopNavBar(
              selectedSection: appVM.homeSection,
              onCheckInPressed: () {
                context.read<ApplicationViewmodel>().showCheckInSection();
              },
              onHomePressed: () {
                context.read<ApplicationViewmodel>().showHomeSection();
              },
              onBookAChargePressed: () {
                context.read<ApplicationViewmodel>().showBookAChargeSection();
              },
            ),
          ),

          /// Filter Button
          Positioned(
            bottom: 150,
            right: 20,
            child: FloatingActionButton(
              backgroundColor: Colors.blue,
              child: const Icon(Icons.filter_list, color: Colors.white),
              onPressed: () async {
                // Navigate to FilterScreen and wait for result
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const FilterScreen()),
                );

                // If user returns filter data, apply it
                if (result != null && result is Map<String, dynamic>) {
                  final selectedPower =
                      result['power'] as String; // "AC", "DC", or ""
                  final selectedNearby = result['nearby'] as List<String>;
                  homeVM.applyFilters(selectedPower, selectedNearby);
                }
              },
            ),
          ),

          HomeStationSheet(
            searchController: _searchController,
            isLoading: homeVM.isLoading,
            stations: homeVM.filteredStations,
            canReserve: authVM.isAuthenticated && !authVM.hasActiveReservation,
            isBookmarked: homeVM.isBookmarked,
            onSearchChanged: homeVM.filterStations,
            onBookmarkPressed: (station) => _toggleBookmark(station, authVM),
            onReservePressed: (station) => _openReservation(station, authVM),
            onViewChargersPressed: _openStation,
          ),
          //Floating Location Button (omitted for brevity)
        ],
      ),
    );
  }

  Future<void> _toggleBookmark(
    HomeStation station,
    AuthViewModel authVM,
  ) async {
    final message = ScaffoldMessenger.of(context);
    final added = await _homeViewModel.toggleBookmark(
      customerId: authVM.customerId,
      station: station,
    );
    if (!mounted || !added) return;
    message.showSnackBar(
      const SnackBar(content: Text("Successful add the station to bookmark")),
    );
  }

  void _openReservation(HomeStation station, AuthViewModel authVM) {
    AppLogger.info(
      "User ID: ${authVM.customerId}, Auth: ${authVM.isAuthenticated}, Res: ${authVM.hasActiveReservation}",
    );

    if (!authVM.isAuthenticated) {
      _showAuthReminder(context);
      return;
    }

    if (authVM.hasActiveReservation) {
      _showReservationReminder(context);
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReservationScreen(stationId: station.stationId),
      ),
    );
  }

  void _openStation(HomeStation station) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StationScreen(stationId: station.stationId),
      ),
    );
  }
}
