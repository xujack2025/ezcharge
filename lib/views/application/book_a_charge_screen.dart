import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/colors.dart';
import '../../core/constants/text_styles.dart';
import '../../viewmodels/application/application_viewmodel.dart';
import '../../viewmodels/emergency_request_viewmodel.dart';
import 'customer/emergency_request/emergency_request_view.dart';
import 'customer/emergency_request/request_history.dart';
import 'customer/emergency_request/tracking_view.dart';
import 'widgets/home_top_nav_bar.dart';

class BookAChargeScreen extends StatefulWidget {
  const BookAChargeScreen({super.key, this.showBottomNav = true});

  final bool showBottomNav;

  @override
  BookAChargeScreenState createState() => BookAChargeScreenState();
}

class BookAChargeScreenState extends State<BookAChargeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    )..repeat(reverse: true);
    _animation = Tween<double>(
      begin: 1.0,
      end: 1.3,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<EmergencyRequestViewModel>().loadBookAChargeHome();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> navigateToTrackingView(String requestID) async {
    final message = ScaffoldMessenger.of(context);
    final requestViewModel = context.read<EmergencyRequestViewModel>();
    final driverId = await requestViewModel.getAssignedDriverId(requestID);

    if (driverId != null) {
      _openTrackingView(driverId, requestID);
      return;
    }

    final driverAssignmentStream = requestViewModel.driverAssignmentStream;
    if (driverAssignmentStream == null) {
      message.showSnackBar(
        SnackBar(
          content: Text(
            requestViewModel.errorMessage ??
                "Request not found. Please try again.",
          ),
        ),
      );
      return;
    }

    message.showSnackBar(
      const SnackBar(content: Text("Waiting for driver assignment...")),
    );

    final assignedDriverId = await driverAssignmentStream.firstWhere(
      (driverId) =>
          driverId != null && driverId != "Unknown" && driverId.isNotEmpty,
    );

    if (!mounted || assignedDriverId == null) return;
    requestViewModel.clearDriverAssignmentStream();
    _openTrackingView(assignedDriverId, requestID);
  }

  void _openTrackingView(String driverID, String requestID) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            TrackingView(driverID: driverID, requestID: requestID),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final requestViewModel = context.watch<EmergencyRequestViewModel>();

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
          /// Background Image Instead of Google Maps
          Positioned.fill(
            child: CachedNetworkImage(
              imageUrl: requestViewModel.imageUrl ?? "",
              fit: BoxFit.contain,
              errorWidget: (context, url, error) =>
                  const Center(child: CircularProgressIndicator()),
            ),
          ),

          /// Dark Overlay for Better Contrast
          // Positioned.fill(
          //   child: Container(
          //     decoration: BoxDecoration(
          //       gradient: LinearGradient(
          //         begin: Alignment.topCenter,
          //         end: Alignment.bottomCenter,
          //         colors: [Colors.black.withValues(alpha: 0.1), Colors.transparent],
          //       ),
          //     ),
          //   ),
          // ),

          // Top Navigation Buttons
          // Container(width: double.infinity, height: 30, color: AppColors.black),
          Positioned(
            top: 0,
            left: 20,
            right: 20,
            child: HomeTopNavBar(
              selectedSection: ApplicationHomeSection.bookACharge,
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

          /// Track Request Icon Button (Top-Right)
          Positioned(
            top: 240,
            right: 20,
            child: ScaleTransition(
              scale: requestViewModel.activeRequestExists
                  ? _animation
                  : const AlwaysStoppedAnimation(1.0),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Material(
                    shape: const CircleBorder(),
                    elevation: 6,
                    color: Colors.white,
                    child: IconButton(
                      icon: const Icon(
                        Icons.electric_car,
                        size: 35,
                        color: Color(0xFF4A90E2),
                      ),
                      tooltip: "Track Request",
                      onPressed: () async {
                        if (!requestViewModel.activeRequestExists) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("You have no active request."),
                            ),
                          );
                          return;
                        }

                        final requestID = requestViewModel.requestID;
                        if (requestID == null || requestID.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Request ID is missing."),
                            ),
                          );
                          return;
                        }

                        await navigateToTrackingView(requestID);
                      },
                    ),
                  ),

                  if (requestViewModel.activeRequestExists)
                    Positioned(
                      top: -2,
                      right: -2,
                      child: Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 1.5),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          /// Request History Button (Below "Track Request")
          Positioned(
            top: 300,
            right: 20,
            child: ScaleTransition(
              scale: const AlwaysStoppedAnimation(1.0), // No animation needed
              child: Material(
                shape: const CircleBorder(),
                elevation: 6,
                color: Colors.white,
                child: IconButton(
                  icon: const Icon(
                    Icons.history,
                    size: 35, // Matches Track Request icon size
                    color: Color(0xFF4A90E2),
                  ),
                  tooltip: "Request History",
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const RequestHistoryScreen(),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),

          /// Informative Text for Users
          const Positioned(
            bottom: 180, // Position above the "BOOK A CHARGE" button
            left: 20,
            right: 20,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  "Need an EV charge? Book a mobile charging service now!",
                  // Main message
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: 10), // Space before the button
                Text(
                  "Our power bank trucks will come to your location and recharge your vehicle anytime, anywhere.",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Colors.black54),
                ),
              ],
            ),
          ),

          /// Book a Charge Button
          Positioned(
            bottom: 100,
            left: 20,
            right: 20,
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const EmergencyRequestView(),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                elevation: 6,
                backgroundColor: Colors.blue,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Center(
                child: Text(
                  "BOOK A CHARGE",
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
