import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:location/location.dart';
import 'package:provider/provider.dart';

import '../../core/constants/colors.dart';
import '../../core/constants/text_styles.dart';
import '../../core/utils/app_logger.dart';
import '../../viewmodels/auth/auth_viewmodel.dart';
import '../../viewmodels/charging_station_viewmodel.dart';
import 'book_a_charge_screen.dart';
import 'check_in_screen.dart';
import 'customer/ezcharge/filter_screen.dart';
import 'customer/ezcharge/reservation_screen.dart';
import 'customer/ezcharge/station_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  AuthViewModel get _authViewModel => context.read<AuthViewModel>();
  ChargingStationViewModel get _chargingStationVM =>
      context.read<ChargingStationViewModel>();

  final Completer<GoogleMapController> _controller = Completer();
  final Location _location = Location();
  LatLng _currentLocation = const LatLng(
    3.2197929237993033,
    101.6437936423279,
  ); // Default: KL
  List<Map<String, dynamic>> _stations = [];
  List<Map<String, dynamic>> _filteredStations = [];
  bool _isLoading = true;
  ValueNotifier<double> sheetSize = ValueNotifier(0.15);

  // Search Controller
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _getUserLocation();
    _fetchStations();
    _authViewModel.syncUserStatus();
    _chargingStationVM.fetchChargingStations();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  //Fetch all stations and their Charger subcollection
  Future<void> _fetchStations() async {
    try {
      //Get all stations
      QuerySnapshot stationSnapshot = await FirebaseFirestore.instance
          .collection("station")
          .get();

      //Temporary list to hold the final data
      List<Map<String, dynamic>> tempStations = [];

      //Loop through each station doc
      for (var stationDoc in stationSnapshot.docs) {
        final stationId = stationDoc.id; // or stationDoc["StationID"]
        final stationData = stationDoc.data() as Map<String, dynamic>;

        //Get the Charger subcollection for this station
        QuerySnapshot chargerSnapshot = await FirebaseFirestore.instance
            .collection("station")
            .doc(stationId)
            .collection("Charger")
            .get();

        // Gather all current types from the Charger docs
        List<String> currentTypes = [];
        for (var chargerDoc in chargerSnapshot.docs) {
          final chargerData = chargerDoc.data() as Map<String, dynamic>;
          final type = chargerData["CurrentType"] ?? "";
          // Only add if it's not empty and not already in the list
          if (type.isNotEmpty && !currentTypes.contains(type)) {
            currentTypes.add(type);
          }
        }

        // Build your station object
        tempStations.add({
          "StationID": stationData["StationID"] ?? stationId,
          "StationName": stationData["StationName"] ?? "",
          "Description": stationData["Description"] ?? "",
          "Capacity": stationData["Capacity"] ?? 0,
          "Location": stationData["Location"], // if you have a GeoPoint
          "Latitude": stationData["Latitude"],
          "Longitude": stationData["Longitude"],
          "Nearby": stationData["Nearby"], // might be string or list
          "ImageUrl":
              stationData["ImageUrl"] ?? "https://via.placeholder.com/80",

          // Store all the charger types found in the subcollection
          "CurrentType": currentTypes,
        });
      }

      // Update your state
      setState(() {
        _stations = tempStations; // Full station list
        _filteredStations = _stations; // Default: show all
        _isLoading = false;
      });
    } catch (e) {
      AppLogger.error("Error fetching stations: $e");
      // setState(() => _isLoading = false);
    }
  }

  //Filter stations based on search query.
  void _filterStations(String query) {
    setState(() {
      if (query.isEmpty) {
        // If user clears the search, show all stations again
        _filteredStations = _stations;
      } else {
        // Filter stations whose name contains the query (ignoring case)
        final matches = _stations.where((station) {
          return station["StationName"].toString().toLowerCase().contains(
            query.toLowerCase(),
          );
        }).toList();

        if (matches.isNotEmpty) {
          // Only display the first matching station
          _filteredStations = [matches.first];
        } else {
          _filteredStations = [];
        }
      }
    });
  }

  void _applyFilters(String power, List<String> nearby) {
    setState(() {
      if (power.isEmpty && nearby.isEmpty) {
        // If user didn't select anything, show all stations
        _filteredStations = _stations;
      } else {
        _filteredStations = _stations.where((station) {
          // Match Power if selected
          bool matchPower = true;
          if (power.isNotEmpty) {
            // Expecting a list of strings in station["CurrentTypes"]
            final currentTypes = station["CurrentType"];
            if (currentTypes is List) {
              // Check CurrentTypes list contains selected power? (e.g., "AC" or "DC")
              matchPower = currentTypes.contains(power);
            } else {
              // If CurrentTypes is missing or not a List, this station doesn't match
              matchPower = false;
            }
          }

          // Match Nearby if selected
          bool matchNearby = true;
          if (nearby.isNotEmpty) {
            // station["Nearby"] can be a String or a List in your DB
            final stationNearby = station["Nearby"];
            if (stationNearby is String) {
              // If it's a string, check if any of the filters is a substring
              matchNearby = nearby.any(
                (n) => stationNearby.toLowerCase().contains(n.toLowerCase()),
              );
            } else if (stationNearby is List) {
              // If it's a list, check if any filter value is in the list
              matchNearby = nearby.any((n) => stationNearby.contains(n));
            } else {
              // If there's no valid nearby data, no match if the user selected something
              matchNearby = false;
            }
          }
          return matchPower && matchNearby;
        }).toList();
      }
    });
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
    debugPrint("Current user ID: ${authVM.customerId}");

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
              markers: _buildMarkers(),
            ),
          ),

          // Top Navigation Buttons
          Container(width: double.infinity, height: 30, color: AppColors.black),
          Positioned(top: 0, left: 20, right: 20, child: TopNavBar()),

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
                  _applyFilters(selectedPower, selectedNearby);
                }
              },
            ),
          ),

          // Draggable Bottom Sheet (Search Bar + Station List)
          DraggableScrollableSheet(
            initialChildSize: 0.15,
            minChildSize: 0.15,
            maxChildSize: 0.6,
            builder: (context, scrollController) {
              return Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                  boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10)],
                ),
                child: Column(
                  children: [
                    const SizedBox(height: 10),
                    Container(
                      width: 40,
                      height: 5,
                      color: Colors.grey[400],
                    ), // Drag Handle
                    const SizedBox(height: 6),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: TextField(
                        controller: _searchController,
                        onChanged: (value) {
                          _filterStations(value);
                        },
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.search),
                          hintText: "SEARCH",
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: _isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : _filteredStations.isEmpty
                          ? const Center(child: Text("No station found"))
                          : ListView.builder(
                              controller: scrollController,
                              itemCount: _filteredStations.length,
                              itemBuilder: (context, index) {
                                final station = _filteredStations[index];
                                return _buildStationCard(station, authVM);
                              },
                            ),
                    ),
                  ],
                ),
              );
            },
          ),
          //Floating Location Button (omitted for brevity)
        ],
      ),
    );
  }

  //Build Station Card (Displays Station Name + Button)
  Widget _buildStationCard(Map<String, dynamic> station, AuthViewModel authVM) {
    final message = ScaffoldMessenger.of(context);

    return StatefulBuilder(
      builder: (context, setState) {
        bool isBookmarked = false; // Track bookmark state
        String bookmarkId = ""; // Store Firestore document ID

        //Check if the station is already bookmarked
        Future<void> checkBookmark() async {
          if (authVM.customerId.isEmpty) return;
          try {
            QuerySnapshot bookmarkSnapshot = await FirebaseFirestore.instance
                .collection("customers")
                .doc(authVM.customerId)
                .collection("bookmark")
                .where("StationID", isEqualTo: station["StationID"])
                .limit(1)
                .get();

            if (!context.mounted) return;

            if (bookmarkSnapshot.docs.isNotEmpty) {
              setState(() {
                isBookmarked = true;
                bookmarkId = bookmarkSnapshot.docs.first.id;
              });
            }
          } catch (e) {
            AppLogger.error("Error checking bookmark: $e");
          }
        }

        /// Toggle Bookmark
        Future<void> toggleBookmark(Function setState) async {
          if (authVM.customerId.isEmpty) return;

          try {
            if (isBookmarked) {
              //Remove bookmark from Firestore
              await FirebaseFirestore.instance
                  .collection("customers")
                  .doc(authVM.customerId)
                  .collection("bookmark")
                  .doc(bookmarkId)
                  .delete();

              setState(() {
                isBookmarked = false;
                bookmarkId = "";
              });
            } else {
              // Format date as YYYYMMDD
              String formattedDate = DateFormat(
                'yyyyMMdd',
              ).format(DateTime.now());
              String newBookmarkId = "BKK$formattedDate"; //BookmarkID format

              // Add bookmark to Firestore
              await FirebaseFirestore.instance
                  .collection("customers")
                  .doc(authVM.customerId)
                  .collection("bookmark")
                  .doc(newBookmarkId) // Use the formatted ID
                  .set({
                    "BookmarkID": newBookmarkId,
                    "StationID": station["StationID"],
                    "CustomerID": authVM.customerId,
                  });

              setState(() {
                isBookmarked = true;
                bookmarkId = newBookmarkId;
              });
              // Display SnackBar message after successful addition
              message.showSnackBar(
                const SnackBar(
                  content: Text("Successful add the station to bookmark"),
                ),
              );
            }
          } catch (e) {
            AppLogger.error("Error toggling bookmark: $e");
          }
        }

        //Check bookmark status when card is built
        checkBookmark();

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(
              color: Colors.black,
              width: 1,
            ), //Black Border
          ),
          color: Colors.white, // White Background
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              children: [
                // Row for Image, Station Name & Bookmark
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Station Image
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        station["ImageUrl"] ?? "https://via.placeholder.com/80",
                        width: 150,
                        height: 100,
                        fit: BoxFit.cover,
                      ),
                    ),

                    //Station Name (Centered)
                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.end, // Aligns text to the right
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.grey[200], //Grey background
                              border: Border.all(
                                color: Colors.black,
                                width: 1.5,
                              ), //Black border
                              borderRadius: BorderRadius.circular(
                                8,
                              ), //Rounded corners
                            ),
                            child: Text(
                              station["Nearby"],
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: Colors.black,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          Text(
                            station["StationName"],
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                            ),
                            textAlign: TextAlign.right,
                          ),
                          const SizedBox(
                            height: 4,
                          ), // Small spacing between name and description
                          Text(
                            station["Description"] ??
                                "", // Display description if available
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey,
                            ),
                            textAlign: TextAlign.right,
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              const Text(
                                "Capacity: ",
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                station["Capacity"]
                                    .toString(), // Convert to String for display
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue, // Highlight in blue
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    //Bookmark Button
                    IconButton(
                      icon: Icon(
                        Icons.bookmark,
                        color: isBookmarked
                            ? Colors.black
                            : Colors.grey, //Fix color toggle
                      ),
                      onPressed: () => toggleBookmark(setState), //Pass setState
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                // Button Row
                Align(
                  alignment: Alignment.centerRight,
                  child: Row(
                    mainAxisSize: MainAxisSize
                        .min, // Ensures row only takes required space
                    children: [
                      /// Reserve Button
                      ElevatedButton(
                        onPressed: () {
                          // Check if user is authenticated
                          AppLogger.info(
                            "User ID: ${authVM.customerId}, Auth: ${authVM.isAuthenticated}, Res: ${authVM.hasActiveReservation}",
                          );
                          if (!authVM.isAuthenticated) {
                            _showAuthReminder(context);
                            return;
                          }

                          // 2. 检查是不是已经有预约在手了
                          if (authVM.hasActiveReservation) {
                            _showReservationReminder(context);
                            return;
                          }

                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ReservationScreen(
                                stationId: station["StationID"],
                              ),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              (authVM.isAuthenticated &&
                                  !authVM.hasActiveReservation)
                              ? Colors.blue
                              : Colors.grey, // Grey if disabled
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(5),
                          ),
                        ),
                        child: const Text(
                          "RESERVE",
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                      const SizedBox(width: 10),

                      /// View Chargers Button
                      ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => StationScreen(
                                stationId: station["StationID"],
                              ),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(5),
                          ),
                        ),
                        child: const Text(
                          "VIEW CHARGERS",
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  //Build Markers for Stations
  Set<Marker> _buildMarkers() {
    final Set<Marker> markers = <Marker>{};

    for (final station in _stations) {
      final dynamic rawLocation = station["Location"];
      LatLng? markerPosition;

      if (rawLocation is GeoPoint) {
        markerPosition = LatLng(rawLocation.latitude, rawLocation.longitude);
      } else if (rawLocation is LatLng) {
        markerPosition = rawLocation;
      } else {
        final double? latitude = double.tryParse(
          station["Latitude"]?.toString() ?? '',
        );
        final double? longitude = double.tryParse(
          station["Longitude"]?.toString() ?? '',
        );

        if (latitude != null && longitude != null) {
          markerPosition = LatLng(latitude, longitude);
        }
      }

      if (markerPosition == null) {
        continue;
      }

      markers.add(
        Marker(
          markerId: MarkerId(station["StationID"].toString()),
          position: markerPosition,
          infoWindow: InfoWindow(title: station["StationName"]?.toString()),
        ),
      );
    }

    return markers;
  }
}

class TopNavBar extends StatelessWidget {
  TopNavBar({super.key});

  final selectedTab = 1;
  final tabs = [CheckInScreen(), HomeScreen(), BookAChargeScreen()];

  @override
  Widget build(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width * 0.85,
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconContainer(iconData: Icons.qr_code),
          IconContainer(iconData: Icons.electric_bolt, isSelected: true),
          IconContainer(iconData: Icons.local_gas_station),
        ],
      ),
    );
  }
}

class IconContainer extends StatelessWidget {
  const IconContainer({
    super.key,
    this.bgColor = AppColors.white,
    required this.iconData,
    this.iconColor = AppColors.black,
    this.isSelected = false,
    this.iconSize = 30,
  });
  final Color bgColor;
  final IconData iconData;
  final Color iconColor;
  final bool isSelected;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isSelected ? AppColors.primary : bgColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(
        iconData,
        color: isSelected ? AppColors.white : iconColor,
        size: iconSize,
      ),
    );
  }
}
