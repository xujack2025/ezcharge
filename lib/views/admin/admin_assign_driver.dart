import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

class AdminAssignDriverPage extends StatefulWidget {
  final String requestID;

  const AdminAssignDriverPage({required this.requestID, super.key});

  @override
  AdminAssignDriverPageState createState() => AdminAssignDriverPageState();
}

class AdminAssignDriverPageState extends State<AdminAssignDriverPage> {
  String? selectedDriverID;
  bool isLoading = true;
  bool isDriverAssigned = false;
  bool isCharging = false;
  DateTime? chargingStartTime;
  double baseFee = 8.0;
  double perMinuteRate = 0.50; // RM0.50 per minute
  List<Map<String, dynamic>> availableDrivers = [];
  bool isDriverArrived = false;
  StreamSubscription<Position>? positionStream;
  StreamSubscription<DocumentSnapshot>? driverLocationListener;

  @override
  void initState() {
    super.initState();
    _fetchAvailableDrivers();
    _listenToRequestStatus();
  }

  @override
  void dispose() {
    _stopTrackingDriverLocation(); // Ensure tracking is stopped when page is disposed
    super.dispose();
  }

  /// Convert seconds to HH:MM:SS format
  String _formatDuration(int seconds) {
    int hours = seconds ~/ 3600; // Get hours
    int minutes = (seconds % 3600) ~/ 60; // Get minutes
    int secs = seconds % 60; // Get remaining seconds

    return "${hours.toString().padLeft(2, '0')}:"
        "${minutes.toString().padLeft(2, '0')}:"
        "${secs.toString().padLeft(2, '0')}";
  }

  /// Start tracking driver location
  void _startTrackingDriverLocation(String driverID) {
    // Ensure any previous tracking is stopped
    _stopTrackingDriverLocation();

    positionStream =
        Geolocator.getPositionStream(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            distanceFilter: 10, // Update only when driver moves 10 meters
          ),
        ).listen((Position position) {
          _updateDriverLocation(driverID, position);
        });
  }

  /// Stop tracking driver location
  void _stopTrackingDriverLocation() {
    positionStream?.cancel();
    positionStream = null;
    debugPrint("📍 Driver location tracking stopped.");
  }

  /// Update driver location in Firestore
  Future<void> _updateDriverLocation(String driverID, Position position) async {
    try {
      await FirebaseFirestore.instance
          .collection('Drivers')
          .doc(driverID)
          .update({
            'Location': GeoPoint(position.latitude, position.longitude),
            'lastUpdated': FieldValue.serverTimestamp(),
          });
      debugPrint(
        "Driver location updated: ${position.latitude}, ${position.longitude}",
      );
    } catch (e) {
      debugPrint("❌ Error updating driver location: $e");
    }
  }

  void _listenToRequestStatus() {
    FirebaseFirestore.instance
        .collection('EmergencyRequests')
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
              ? requestData['Status']
              : "Unknown";
          String? driverID = requestData['DriverID'];

          debugPrint("🔄 Firestore Update Detected: Status = $status");

          setState(() {
            isDriverAssigned =
                requestData.containsKey('driverID') &&
                requestData['DriverID'] != null;
            isDriverArrived = (status == "Arrived" || status == "Charging");
            isCharging = status == "Charging";
          });

          if (status == "Arrived") {
            debugPrint("Driver has arrived! Stopping location tracking.");
            _stopTrackingDriverLocation(); // Stop tracking when driver arrives
          }

          // Debugging: Confirm if this block is running
          if (status == "Payment" && driverID != null) {
            debugPrint(
              "Status is 'Completed', calling _updateDriverStatus($driverID)",
            );
            _updateDriverStatus(driverID);
          } else {
            debugPrint(
              "⚠️ Status is NOT 'Completed' yet, skipping driver update.",
            );
          }
        });
  }

  /// Fetch Available Drivers from Firestore
  Future<void> _fetchAvailableDrivers() async {
    try {
      QuerySnapshot driverSnapshot = await FirebaseFirestore.instance
          .collection('Drivers')
          .where('Status', isEqualTo: 'Available')
          .get();

      setState(() {
        availableDrivers = driverSnapshot.docs.map((doc) {
          return {
            "DriverID": doc.id,
            "name": "${doc["FirstName"]} ${doc["LastName"]}",
            "phone": doc["PhoneNumber"],
          };
        }).toList();
        isLoading = false;
      });
    } catch (e) {
      debugPrint("❌ Error fetching drivers: $e");
    }
  }

  /// Assign Driver & Update Firestore
  Future<void> _assignDriver() async {
    if (selectedDriverID == null) return;

    await FirebaseFirestore.instance
        .collection('EmergencyRequests')
        .doc(widget.requestID)
        .update({'DriverID': selectedDriverID, 'Status': 'Upcoming'});

    // Update driver status to "Busy"
    await FirebaseFirestore.instance
        .collection('Drivers')
        .doc(selectedDriverID)
        .update({'Status': 'Busy', 'RequestID': widget.requestID});

    if (!mounted) return;
    setState(() {
      isDriverAssigned = true;
    });

    // Start tracking location
    _startTrackingDriverLocation(selectedDriverID!);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Driver assigned successfully!")),
    );
  }

  /// Admin starts charging
  Future<void> _startCharging() async {
    DateTime startTime = DateTime.now();
    DateTime clientNow = DateTime.now();

    await FirebaseFirestore.instance
        .collection('EmergencyRequests')
        .doc(widget.requestID)
        .update({
          'Status': 'Charging',
          'chargingStartTime': FieldValue.serverTimestamp(), // For accuracy
          'chargingClientStartTime': clientNow, // For immediate local use
          // Ensure Firestore stores this timestamp
        });

    debugPrint("Firestore Updated: Status changed to Charging at $startTime");

    setState(() {
      isCharging = true;
      chargingStartTime = startTime;
    });
  }

  /// Admin stops charging & calculates fee
  Future<void> _stopCharging() async {
    debugPrint("🔴 Stop Charging button clicked!");

    // Fetch latest Firestore data to get the chargingStartTime
    DocumentSnapshot requestSnapshot = await FirebaseFirestore.instance
        .collection('EmergencyRequests')
        .doc(widget.requestID)
        .get();

    if (!requestSnapshot.exists) {
      debugPrint("❌ Error: Request document does not exist.");
      return;
    }

    Map<String, dynamic>? requestData =
        requestSnapshot.data() as Map<String, dynamic>?;

    if (requestData == null || !requestData.containsKey('chargingStartTime')) {
      debugPrint("❌ Error: Charging start time not found in Firestore.");
      return;
    }

    Timestamp startTimestamp =
        requestData['chargingClientStartTime'] ??
        requestData['chargingStartTime'];
    DateTime chargingStartTime = startTimestamp.toDate();

    debugPrint(
      "Retrieved charging start time from Firestore: $chargingStartTime",
    );

    DateTime endTime = DateTime.now();
    Duration duration = endTime.difference(chargingStartTime);
    int chargingTime = duration.inSeconds; // 🔹 Track in seconds

    debugPrint("⏳ Charging time: $chargingTime seconds");

    // Limit to 30 minutes max (1800 seconds)
    chargingTime = chargingTime > 1800 ? 1800 : chargingTime;

    // Convert to HH:MM:SS format
    String formattedChargingTime = _formatDuration(chargingTime);

    // Convert seconds to minutes for cost calculation
    double chargingMinutes = chargingTime / 60.0;
    double totalCost = baseFee + (chargingMinutes * perMinuteRate);

    try {
      await FirebaseFirestore.instance
          .collection('EmergencyRequests')
          .doc(widget.requestID)
          .update({
            'Status': 'Payment',
            'chargingEndTime': endTime,
            'chargingTime': chargingTime,
            // 🔹 Store exact seconds
            'chargingFormattedTime': formattedChargingTime,
            // 🔹 Store formatted HH:MM:SS
            'totalCost': totalCost,
          });

      debugPrint(
        "Firestore updated: Charging stopped & status changed to Payment. Formatted time: $formattedChargingTime",
      );

      if (!mounted) return;

      setState(() {
        isCharging = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Charging stopped. Total Cost: RM${totalCost.toStringAsFixed(2)}\nTime: $formattedChargingTime",
          ),
        ),
      );
    } catch (e) {
      debugPrint("❌ Firestore Update Failed: $e");
    }
  }

  /// Confirm Driver Arrival Only if Close to Customer
  Future<void> _confirmDriverArrival() async {
    try {
      DocumentSnapshot requestSnapshot = await FirebaseFirestore.instance
          .collection('EmergencyRequests')
          .doc(widget.requestID)
          .get();

      if (!mounted) return;
      if (!requestSnapshot.exists) {
        debugPrint("❌ Request not found.");
        return;
      }

      // Get Firestore document data
      Map<String, dynamic>? requestData =
          requestSnapshot.data() as Map<String, dynamic>?;

      if (requestData == null) {
        debugPrint("❌ Error: requestData is null.");
        return;
      }

      String? driverID = requestData['DriverID'] as String?;

      if (driverID == null || driverID.isEmpty) {
        debugPrint("❌ No driver assigned yet.");
        return;
      }

      if (!requestData.containsKey('location') ||
          requestData['Location'] == null) {
        debugPrint("❌ Customer location not available in emergency request.");
        return;
      }

      // Fetch Customer GeoPoint Directly (No Need for Address Conversion)
      GeoPoint customerGeoPoint = requestData['Location'] as GeoPoint;

      // Fetch driver location from Firestore
      DocumentSnapshot driverSnapshot = await FirebaseFirestore.instance
          .collection('Drivers')
          .doc(driverID)
          .get();

      if (!mounted) return;
      Map<String, dynamic>? driverData =
          driverSnapshot.data() as Map<String, dynamic>?;

      if (driverData == null || !driverData.containsKey('location')) {
        debugPrint("❌ Driver location not available.");
        return;
      }

      GeoPoint driverLocation =
          driverData['Location'] as GeoPoint; // Driver is stored as GeoPoint

      // Calculate distance (meters)
      double distance = Geolocator.distanceBetween(
        driverLocation.latitude,
        driverLocation.longitude,
        customerGeoPoint.latitude,
        customerGeoPoint.longitude,
      );

      debugPrint(
        "📍 Distance between driver and customer: ${distance.toStringAsFixed(2)} meters",
      );

      // Only allow confirmation if within 100 meters
      if (distance <= 100) {
        await FirebaseFirestore.instance
            .collection('EmergencyRequests')
            .doc(widget.requestID)
            .update({'Status': 'Arrived'});

        if (!mounted) return;
        setState(() {
          isDriverArrived = true;
        });

        // Stop tracking when driver arrives
        _stopTrackingDriverLocation();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Driver marked as arrived!")),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "❌ Driver is too far away (${distance.toStringAsFixed(2)}m). Move closer!",
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint("❌ Error checking driver arrival: $e");
    }
  }

  /// Update the driver's status and remove requestID in the drivers collection
  Future<void> _updateDriverStatus(String driverID) async {
    try {
      debugPrint("🔄 Updating driver $driverID status to 'Available'...");

      await FirebaseFirestore.instance
          .collection('Drivers')
          .doc(driverID)
          .update({
            'Status': 'Available', // Set driver as Available
            'RequestID': FieldValue.delete(), // Remove requestID field
          });

      debugPrint("Driver $driverID status updated successfully!");
    } catch (error) {
      debugPrint("❌ Error updating driver status: $error");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Assign Driver & Manage Charging")),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!isDriverAssigned) ...[
                    const Text(
                      "Select a Driver:",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    RadioGroup<String>(
                      groupValue: selectedDriverID,
                      onChanged: (value) {
                        setState(() {
                          selectedDriverID = value;
                        });
                      },
                      child: ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: availableDrivers.length,
                        itemBuilder: (context, index) {
                          final driver = availableDrivers[index];
                          return RadioListTile<String>(
                            title: Text(
                              "${driver["name"]} (${driver["phone"]})",
                            ),
                            value: driver["DriverID"],
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 10),
                    Center(
                      child: ElevatedButton(
                        onPressed: selectedDriverID == null
                            ? null
                            : _assignDriver,
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 48),
                        ),
                        child: const Text("Confirm Assignment"),
                      ),
                    ),
                  ],
                  if (isDriverAssigned && !isDriverArrived) ...[
                    const SizedBox(height: 20),
                    Center(
                      child: ElevatedButton.icon(
                        onPressed: _confirmDriverArrival,
                        icon: const Icon(Icons.check_circle_outline),
                        label: const Text("Confirm Driver Arrived"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          minimumSize: const Size(double.infinity, 48),
                        ),
                      ),
                    ),
                  ],
                  if (isDriverArrived) ...[
                    const SizedBox(height: 20),
                    Center(
                      child: Text(
                        isCharging
                            ? "Charging in progress..."
                            : "Ready to start charging",
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Center(
                      child: ElevatedButton.icon(
                        onPressed: isCharging ? _stopCharging : _startCharging,
                        icon: Icon(isCharging ? Icons.stop : Icons.flash_on),
                        label: Text(
                          isCharging ? "Stop Charging" : "Start Charging",
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isCharging
                              ? Colors.red
                              : Colors.green,
                          minimumSize: const Size(double.infinity, 48),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }
}
