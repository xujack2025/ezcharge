import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';

import '../../../../models/tracking_model.dart';
import '../../../../viewmodels/tracking_viewmodel.dart';
import '../../book_a_charge_screen.dart';
import 'request_payment.dart';

class TrackingView extends StatefulWidget {
  const TrackingView({
    required this.driverID,
    required this.requestID,
    super.key,
  });

  final String driverID;
  final String requestID;

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
  Set<Polyline> polylines = {};
  bool isDriverArrived = false;
  bool isCharging = false;
  int chargingTime = 0;
  bool _hasNavigatedToPayment = false;
  bool _hasHandledCompletion = false;
  Timer? _timer;
  StreamSubscription<DriverTrackingInfo?>? _driverSubscription;
  StreamSubscription<RequestTrackingInfo?>? _requestSubscription;

  @override
  void initState() {
    super.initState();

    if (widget.driverID.isEmpty || widget.requestID.isEmpty) {
      errorMessage = "Driver or request details are missing.";
      isLoading = false;
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _setupTracking();
    });
  }

  @override
  void dispose() {
    _driverSubscription?.cancel();
    _requestSubscription?.cancel();
    _timer?.cancel();
    super.dispose();
  }

  void _setupTracking() {
    if (widget.driverID == "Unknown" || widget.driverID.isEmpty) {
      setState(() {
        errorMessage = "No driver assigned to this request.";
        isLoading = false;
      });
      return;
    }

    final trackingViewModel = context.read<TrackingViewModel>();
    _driverSubscription?.cancel();
    _driverSubscription = trackingViewModel
        .watchDriver(widget.driverID)
        .listen(_handleDriverUpdate);

    _requestSubscription?.cancel();
    _requestSubscription = trackingViewModel
        .watchRequest(widget.requestID)
        .listen(_handleRequestUpdate);
  }

  void _handleDriverUpdate(DriverTrackingInfo? driverInfo) {
    if (!mounted) return;

    if (driverInfo == null) {
      setState(() {
        errorMessage = "Driver location not available.";
        isLoading = false;
      });
      return;
    }

    setState(() {
      driverLocation = driverInfo.location;
      driverName = driverInfo.name;
      driverPhone = driverInfo.phoneNumber;
      isLoading = false;
    });

    _refreshRouteData();
  }

  void _handleRequestUpdate(RequestTrackingInfo? requestInfo) {
    if (!mounted) return;

    if (requestInfo == null) {
      setState(() {
        errorMessage = "Request tracking details not available.";
        isLoading = false;
      });
      return;
    }

    setState(() {
      customerLocation = requestInfo.customerLocation;
      isDriverArrived =
          requestInfo.status == "Arrived" ||
          requestInfo.status == "Charging" ||
          requestInfo.status == "Payment";
      isCharging = requestInfo.status == "Charging";
      isLoading = false;
    });

    if (requestInfo.status == "Charging") {
      final chargingStartTime = requestInfo.chargingStartTime;
      if (chargingStartTime != null) {
        _startTimer(chargingStartTime);
      }
    } else if (requestInfo.status == "Payment") {
      _navigateToPayment(requestInfo);
    } else if (requestInfo.status == "Completed") {
      _handleCompletedRequest();
    }

    _refreshRouteData();
  }

  void _handleCompletedRequest() {
    if (_hasHandledCompletion) return;
    _hasHandledCompletion = true;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Charging session completed! Returning to home..."),
      ),
    );

    Future.delayed(const Duration(seconds: 5), () {
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const BookAChargeScreen()),
      );
    });
  }

  void _startTimer(DateTime startTime) {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;

      setState(() {
        final elapsedSeconds = DateTime.now().difference(startTime).inSeconds;
        chargingTime = elapsedSeconds > 1800 ? 1800 : elapsedSeconds;
      });

      if (chargingTime >= 1800) {
        _timer?.cancel();
      }
    });
  }

  void _navigateToPayment(RequestTrackingInfo requestInfo) {
    if (_hasNavigatedToPayment) return;
    _hasNavigatedToPayment = true;
    _timer?.cancel();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Charging completed. Redirecting to payment..."),
      ),
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RequestPaymentScreen(
          requestID: widget.requestID,
          chargingCost: requestInfo.totalCost,
          duration: requestInfo.chargingFormattedTime,
        ),
      ),
    );
  }

  Future<void> _refreshRouteData() async {
    if (driverLocation == null || customerLocation == null) return;

    final trackingViewModel = context.read<TrackingViewModel>();
    final driver = driverLocation!;
    final customer = customerLocation!;

    final eta = await trackingViewModel.calculateEta(
      driverLocation: driver,
      customerLocation: customer,
    );
    if (!mounted) return;

    if (eta != null) {
      setState(() {
        estimatedTime = eta;
      });
    }

    final routePoints = await trackingViewModel.loadRoutePoints(
      driverLocation: driver,
      customerLocation: customer,
    );
    if (!mounted || routePoints.isEmpty) return;

    setState(() {
      polylines = {
        Polyline(
          polylineId: const PolylineId("route"),
          points: routePoints,
          width: 5,
          color: Colors.blue,
        ),
      };
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Driver Details")),
      body: Column(
        children: [
          Expanded(child: _buildTrackingBody()),
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
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: () {},
              child: const Text("Chat with your driver"),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrackingBody() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (errorMessage != null) {
      return Center(child: Text(errorMessage!));
    }

    if (isDriverArrived && !isCharging) {
      return const Center(
        child: Text(
          "Driver has arrived. Waiting for charging...",
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
      );
    }

    if (isCharging) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "Charging in progress...",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            Text(
              "Elapsed Time: ${chargingTime ~/ 60} min ${chargingTime % 60} sec",
              style: const TextStyle(fontSize: 18),
            ),
            if (chargingTime >= 1800)
              const Text(
                "Max charging time reached!",
                style: TextStyle(fontSize: 18, color: Colors.red),
              ),
          ],
        ),
      );
    }

    if (driverLocation == null || customerLocation == null) {
      return const Center(
        child: Text("Driver or customer location unavailable."),
      );
    }

    return GoogleMap(
      initialCameraPosition: CameraPosition(target: driverLocation!, zoom: 14),
      markers: {
        Marker(
          markerId: const MarkerId("driver"),
          position: driverLocation!,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        ),
        Marker(
          markerId: const MarkerId("customer"),
          position: customerLocation!,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        ),
      },
      polylines: polylines,
    );
  }
}
