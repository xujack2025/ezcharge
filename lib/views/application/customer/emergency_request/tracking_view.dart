import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import '../../../../secrets.dart';
import '../../../../viewmodels/tracking_viewmodel.dart';
import '../../book_a_charge_screen.dart';
import 'request_payment.dart';

class TrackingView extends StatefulWidget {
  final String driverID;
  final String requestID;

  const TrackingView({
    required this.driverID,
    required this.requestID,
    super.key,
  });

  @override
  TrackingViewState createState() => TrackingViewState();
}

class TrackingViewState extends State<TrackingView> {
  LatLng? driverLocation;
  LatLng? customerLocation;
  int estimatedTime = 0;
  bool isLoading = true;
  String? errorMessage;
  String driverName = "Unknown";
  String driverPhone = "N/A";
  late TrackingViewModel trackingViewModel;
  Set<Polyline> polylines = {};
  bool isDriverArrived = false;
  bool isCharging = false;
  int chargingTime = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();

    if (widget.driverID.isEmpty || widget.requestID.isEmpty) {
      debugPrint("❌ Error: Driver ID or Request ID is null/empty.");
      return;
    }

    trackingViewModel = Provider.of<TrackingViewModel>(context, listen: false);
    _setupTracking();
    _listenToRequestStatus();
  }

  StreamSubscription<DocumentSnapshot>? _requestSubscription;

  /// Listen for request status changes in real-time
  void _listenToRequestStatus() {
    // Cancel previous listener if it exists to prevent duplicate listeners
    _requestSubscription?.cancel();

    _requestSubscription = FirebaseFirestore.instance
        .collection('emergency_requests')
        .doc(widget.requestID)
        .snapshots()
        .listen((snapshot) {
          if (!snapshot.exists) {
            debugPrint("❌ Error: Request not found in Firestore.");
            return;
          }

          Map<String, dynamic>? requestData = snapshot.data();
          if (requestData == null) {
            debugPrint("❌ Error: Firestore data is null.");
            return;
          }

          String status = requestData.containsKey('status')
              ? requestData['status']
              : "Unknown";

          debugPrint("🔄 Firestore Update Detected: Status = $status");

          // Update state only if status actually changed
          if (mounted) {
            setState(() {
              isDriverArrived =
                  status == "Arrived" ||
                  status == "Charging" ||
                  status == "Payment";
              isCharging = status == "Charging";
            });
          }

          if (status == "Charging") {
            if (requestData['chargingStartTime'] != null) {
              _startTimer(requestData['chargingStartTime']);
            } else {
              debugPrint("⏳ Waiting for chargingStartTime to sync...");
            }
          } else if (status == "Payment") {
            _navigateToPayment();
          } else if (status == "Completed") {
            _handleCompletedRequest();
          }
        });
  }

  @override
  void dispose() {
    _requestSubscription
        ?.cancel(); // Ensure listener is removed when widget is disposed
    _timer?.cancel(); // Cancel timer if active
    super.dispose();
  }

  /// Redirect when request is "Completed"
  void _handleCompletedRequest() {
    debugPrint(
      "Request marked as 'Completed'. Navigating back to home screen...",
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Charging session completed! Returning to home..."),
      ),
    );

    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => BookAChargeScreen(),
          ), // Replace with your target page
        );
      }
    });
  }

  /// Start a charging timer once status is "Charging"
  void _startTimer(Timestamp startTimestamp) {
    DateTime startTime = startTimestamp.toDate();
    _timer?.cancel(); // Reset any existing timer
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        int elapsedSeconds = DateTime.now().difference(startTime).inSeconds;
        chargingTime = elapsedSeconds > 1800
            ? 1800
            : elapsedSeconds; // 🔹 Max 30 minutes (1800 seconds)
      });

      if (chargingTime >= 1800) {
        _timer?.cancel(); // Stop timer when 30 minutes reached
      }
    });
  }

  /// Redirect to Payment Page when charging stops
  void _navigateToPayment() async {
    _timer?.cancel(); // Stop the timer

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("⚡ Charging completed. Redirecting to payment..."),
      ),
    );

    try {
      // Fetch emergency request details from Firestore
      DocumentSnapshot requestDoc = await FirebaseFirestore.instance
          .collection("emergency_requests")
          .doc(widget.requestID)
          .get();

      if (!requestDoc.exists) {
        debugPrint("❌ Error: Emergency request not found.");
        return;
      }

      // Extract relevant data
      double emergencyTotalCost = (requestDoc["totalCost"] ?? 0.0).toDouble();
      String emergencyDuration =
          requestDoc["chargingFormattedTime"] ?? "00:00:00";

      // Navigate directly to PaymentScreen
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => RequestPaymentScreen(
            requestID: widget.requestID,
            // Ensure you have this request ID
            chargingCost: emergencyTotalCost,
            // Use totalCost as charging cost
            duration: emergencyDuration, // Charging duration
          ),
        ),
      );
    } catch (e) {
      debugPrint("❌ Error fetching emergency payment details: $e");
    }
  }

  /// Setup Live Tracking from Firestore
  void _setupTracking() {
    debugPrint("🔍 Received driverID from widget: ${widget.driverID}");

    if (widget.driverID == "Unknown" || widget.driverID.isEmpty) {
      setState(() {
        errorMessage = "❌ No driver assigned to this request.";
        isLoading = false;
      });
      debugPrint("❌ Error: Driver ID is 'Unknown' or empty.");
      return;
    }

    // Fetch Driver Location
    trackingViewModel.trackDriverLocation(widget.driverID).listen((snapshot) {
      if (!mounted || !snapshot.exists || snapshot.data() == null) return;

      final driverData = snapshot.data() as Map<String, dynamic>?;

      if (driverData != null && driverData.containsKey('location')) {
        final GeoPoint location = driverData['location'];

        setState(() {
          driverLocation = LatLng(location.latitude, location.longitude);
          driverName = driverData['FirstName'] ?? "Unknown";
          driverPhone = driverData['PhoneNumber'] ?? "N/A";
          isLoading = false;
        });

        if (customerLocation != null) {
          _calculateETA();
          _drawRoute();
        }
      } else {
        setState(() {
          errorMessage = "Driver location not available.";
          isLoading = false;
        });
      }
    });

    // Fetch Customer Location
    trackingViewModel.getTrackingInfo(widget.requestID).listen((snapshot) {
      if (!mounted || !snapshot.exists || snapshot.data() == null) return;

      final requestData = snapshot.data() as Map<String, dynamic>?;

      if (requestData != null && requestData.containsKey('location')) {
        final GeoPoint location =
            requestData['location']; // Use GeoPoint directly

        setState(() {
          customerLocation = LatLng(location.latitude, location.longitude);
        });

        if (driverLocation != null) {
          _calculateETA();
          _drawRoute();
        }
      } else {
        debugPrint("❌ Error: No customer location found.");
      }
    });
  }

  /// Function to Calculate ETA Using Google Distance Matrix API
  Future<void> _calculateETA() async {
    if (driverLocation == null || customerLocation == null) return;

    final String url =
        "https://maps.googleapis.com/maps/api/distancematrix/json?units=metric"
        "&origins=${driverLocation!.latitude},${driverLocation!.longitude}"
        "&destinations=${customerLocation!.latitude},${customerLocation!.longitude}"
        "&key=${Secrets.googleMapsApiKey}";

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        int eta = (data["rows"][0]["elements"][0]["duration"]["value"] ~/ 60);

        setState(() {
          estimatedTime = eta;
        });

        debugPrint("ETA: $estimatedTime min");
      }
    } catch (e) {
      debugPrint("❌ Error fetching ETA: $e");
    }
  }

  /// Function to Draw Route Between Driver & Customer
  Future<void> _drawRoute() async {
    if (driverLocation == null || customerLocation == null) return;

    final String url =
        "https://maps.googleapis.com/maps/api/directions/json?origin=${driverLocation!.latitude},${driverLocation!.longitude}"
        "&destination=${customerLocation!.latitude},${customerLocation!.longitude}"
        "&key=${Secrets.googleMapsApiKey}";

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data["routes"].isNotEmpty) {
          List<LatLng> routePoints = [];

          // Extract encoded polyline from API response
          String encodedPolyline =
              data["routes"][0]["overview_polyline"]["points"];

          // Decode the polyline
          routePoints = _decodePolyline(encodedPolyline);

          setState(() {
            polylines.clear();
            polylines.add(
              Polyline(
                polylineId: const PolylineId("route"),
                points: routePoints,
                width: 5,
                color: Colors.blue,
              ),
            );
          });

          debugPrint("Route drawn on map.");
        } else {
          debugPrint("❌ No route found.");
        }
      }
    } catch (e) {
      debugPrint("❌ Error fetching route: $e");
    }
  }

  /// Function to Decode Google Maps Polyline
  List<LatLng> _decodePolyline(String encoded) {
    List<PointLatLng> result = PolylinePoints.decodePolyline(encoded);

    return result
        .map((point) => LatLng(point.latitude, point.longitude))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Driver Details")),
      body: Column(
        children: [
          /// 🔹 Show Different Views Based on Status
          Expanded(
            child: isLoading
                ? const Center(
                    child: CircularProgressIndicator(),
                  ) // Show loading only initially
                : isDriverArrived && !isCharging
                ? const Center(
                    child: Text(
                      "Driver has arrived. Waiting for charging...",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  )
                : isCharging
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          "⚡ Charging in progress...",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          "Elapsed Time: ${chargingTime ~/ 60} min ${chargingTime % 60} sec",
                          style: const TextStyle(fontSize: 18),
                        ),
                        if (chargingTime >=
                            1800) // 🔹 Show when charging time maxed out
                          const Text(
                            "⚠️ Max charging time reached!",
                            style: TextStyle(fontSize: 18, color: Colors.red),
                          ),
                      ],
                    ),
                  )
                : driverLocation == null || customerLocation == null
                ? const Center(
                    child: Text("Driver or customer location unavailable."),
                  )
                : GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: driverLocation!,
                      zoom: 14,
                    ),
                    markers: {
                      Marker(
                        markerId: const MarkerId("driver"),
                        position: driverLocation!,
                        icon: BitmapDescriptor.defaultMarkerWithHue(
                          BitmapDescriptor.hueBlue,
                        ),
                      ),
                      Marker(
                        markerId: const MarkerId("customer"),
                        position: customerLocation!,
                        icon: BitmapDescriptor.defaultMarkerWithHue(
                          BitmapDescriptor.hueRed,
                        ),
                      ),
                    },
                    polylines: polylines,
                  ),
          ),

          /// 🔹 Driver Information & ETA
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Text(
                  "Driver: $driverName",
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  "Phone: $driverPhone",
                  style: const TextStyle(fontSize: 16),
                ),
                Text(
                  estimatedTime > 0
                      ? "ETA: $estimatedTime min"
                      : "ETA not available",
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          /// 🔹 Chat Button (Future Implementation)
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: () {}, // TODO: Implement chat feature
              child: const Text("Chat with your driver"),
            ),
          ),
        ],
      ),
    );
  }
}
