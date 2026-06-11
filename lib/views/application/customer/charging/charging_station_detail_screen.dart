import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/utils/app_logger.dart';
import '../../../../core/utils/map_utils.dart';
import '../../../../models/charging_reservation_charger_model.dart';
import '../../../../models/charging_station_detail_model.dart';
import '../../../../viewmodels/charging/charging_station_detail_viewmodel.dart';
import '../rating/customer_complaint.dart';
import '../rating/customer_review.dart';
import 'charging_reservation_screen.dart';

class ChargingStationDetailScreen extends StatelessWidget {
  const ChargingStationDetailScreen({super.key, required this.stationId});

  final String stationId;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ChargingStationDetailViewModel()..load(stationId),
      child: _ChargingStationDetailContent(stationId: stationId),
    );
  }
}

class _ChargingStationDetailContent extends StatelessWidget {
  const _ChargingStationDetailContent({required this.stationId});

  final String stationId;

  String _formatReviewDate(DateTime? reviewDate) {
    if (reviewDate == null) {
      return "Unknown Date";
    }

    final difference = DateTime.now().difference(reviewDate);
    if (difference.inDays < 60) {
      return "${(difference.inDays / 30).floor()} months ago";
    }

    return DateFormat("dd/MM/yyyy").format(reviewDate);
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<ChargingStationDetailViewModel>();
    final station = viewModel.station;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: Container(
            decoration: const BoxDecoration(
              color: Colors.blue,
              shape: BoxShape.circle,
            ),
            padding: const EdgeInsets.all(8),
            child: const Icon(Icons.arrow_back, color: Colors.white),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Stations Details",
          style: TextStyle(
            color: Colors.black,
            fontSize: 25,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          if (station != null)
            Padding(
              padding: const EdgeInsets.only(right: 15),
              child: GestureDetector(
                onTap: () => _showMoreOptions(context, station),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.blue,
                  ),
                  child: const Icon(Icons.more_vert, color: Colors.white),
                ),
              ),
            ),
        ],
        backgroundColor: Colors.white,
        elevation: 1,
      ),
      body: viewModel.isLoading
          ? const Center(child: CircularProgressIndicator())
          : station == null
          ? Center(child: Text(viewModel.errorMessage ?? "Station not found."))
          : _buildStationDetails(context, station, viewModel),
      bottomNavigationBar: station == null
          ? null
          : _buildBottomButtons(context, station, viewModel),
    );
  }

  void _showMoreOptions(BuildContext context, ChargingStationDetail station) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 15),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildBottomSheetButton(
                icon: Icons.reviews,
                text: "Review",
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ReviewPage(
                        stationId: stationId,
                        stationName: station.stationName,
                        stationDescription: station.description,
                        stationImage: station.imageUrl,
                      ),
                    ),
                  );
                },
              ),
              _buildBottomSheetButton(
                icon: Icons.report,
                text: "Report",
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CustomerComplaintPage(
                        stationId: stationId,
                        stationName: station.stationName,
                        stationDescription: station.description,
                        stationImage: station.imageUrl,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBottomSheetButton({
    required IconData icon,
    required String text,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 15),
          decoration: BoxDecoration(
            color: Colors.blue,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white),
              const SizedBox(width: 10),
              Text(
                text,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStationDetails(
    BuildContext context,
    ChargingStationDetail station,
    ChargingStationDetailViewModel viewModel,
  ) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Image.network(
            station.imageUrl,
            width: double.infinity,
            height: 250,
            fit: BoxFit.cover,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: const Text(
                        "Coffee Shop",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Text(
                  station.stationName,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  station.description,
                  style: const TextStyle(fontSize: 16, color: Colors.grey),
                ),
                const SizedBox(height: 5),
                Row(
                  children: [
                    const Text(
                      "Available",
                      style: TextStyle(color: Colors.green, fontSize: 16),
                    ),
                    const SizedBox(width: 5),
                    const Icon(Icons.bolt, color: Colors.green, size: 18),
                    Text(
                      " ${station.capacity} ",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const Icon(Icons.ev_station, color: Colors.black, size: 18),
                  ],
                ),
              ],
            ),
          ),
          _buildChargerList(viewModel.chargers),
          const SizedBox(height: 10),
          _buildBusyTimesChart(viewModel),
          const SizedBox(height: 10),
          _buildReviewsSection(viewModel.reviews),
          const SizedBox(height: 10),
          _buildLocationInfo(station),
          const SizedBox(height: 20),
          _buildOperationInfo(),
        ],
      ),
    );
  }

  Widget _buildReviewsSection(List<ChargingStationReview> reviews) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Recent Reviews",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              GestureDetector(
                onTap: () {},
                child: const Text(
                  "ALL REVIEWS",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.purple,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (reviews.isEmpty)
            const Text("No reviews yet.", style: TextStyle(color: Colors.grey)),
          ...reviews.map((review) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: List.generate(5, (index) {
                          return Icon(
                            index < review.rating
                                ? Icons.star
                                : Icons.star_border,
                            color: Colors.amber,
                            size: 18,
                          );
                        }),
                      ),
                      Text(
                        _formatReviewDate(review.reviewDate),
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(review.reviewText, style: const TextStyle(fontSize: 14)),
                  const SizedBox(height: 5),
                  Text(
                    review.reviewerLabel,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Divider(thickness: 0.5, color: Colors.grey),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildChargerList(List<ChargingReservationCharger> chargers) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Provided Charger",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          ...chargers.map(_buildChargerCard),
        ],
      ),
    );
  }

  Widget _buildChargerCard(ChargingReservationCharger charger) {
    final isAvailable = charger.isAvailable;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isAvailable ? Colors.white : Colors.grey[300],
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: isAvailable ? Colors.green : Colors.orange),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  charger.name,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(charger.type),
                Text(
                  charger.status,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isAvailable ? Colors.green : Colors.orange,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 5),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  charger.power,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            Text(
              charger.price,
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBusyTimesChart(ChargingStationDetailViewModel viewModel) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Text(
                  "Busy Times",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Text(
                  "${DateFormat.jm().format(DateTime.now())}: ",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.purple,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  viewModel.trafficStatus,
                  style: const TextStyle(color: Colors.grey, fontSize: 14),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 150,
              child: BarChart(
                BarChartData(
                  maxY: 15,
                  barGroups: _getBarChartData(viewModel),
                  titlesData: FlTitlesData(
                    leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 32,
                        getTitlesWidget: _buildHourTitle,
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    drawHorizontalLine: true,
                    horizontalInterval: 2,
                    getDrawingHorizontalLine: (value) {
                      return FlLine(
                        color: Colors.grey.withValues(alpha: 0.2),
                        strokeWidth: 1,
                      );
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHourTitle(double value, TitleMeta meta) {
    final hour24 = value.toInt();
    final hourLabel = hour24 == 0
        ? "12 AM"
        : hour24 == 12
        ? "12 PM"
        : hour24 < 12
        ? "$hour24 AM"
        : "${hour24 - 12} PM";

    if (hour24 % 4 == 0 || hour24 == 23) {
      return Column(
        children: [
          const SizedBox(height: 2),
          Container(width: 2, height: 6, color: Colors.black54),
          const SizedBox(height: 2),
          Text(
            hourLabel,
            style: const TextStyle(
              color: Colors.black87,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      );
    }

    return const SizedBox.shrink();
  }

  List<BarChartGroupData> _getBarChartData(
    ChargingStationDetailViewModel viewModel,
  ) {
    return List.generate(viewModel.busyTimes.length, (index) {
      final barHeight = viewModel.busyTimes[index] > 0
          ? viewModel.busyTimes[index]
          : 0.2;

      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: barHeight,
            width: 13,
            borderRadius: BorderRadius.circular(3),
            color: index == viewModel.currentHour
                ? Colors.purple.shade300
                : Colors.lightBlue,
          ),
        ],
        barsSpace: 0,
      );
    });
  }

  Widget _buildLocationInfo(ChargingStationDetail station) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Location Info",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            textAlign: TextAlign.left,
          ),
          const SizedBox(height: 10),
          Text(
            station.location,
            style: const TextStyle(fontSize: 12),
            textAlign: TextAlign.left,
          ),
        ],
      ),
    );
  }

  Widget _buildOperationInfo() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Operation",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildInfoBox("Operation Hour", "24 Hours"),
              GestureDetector(
                onTap: () => _callHotline(),
                child: _buildInfoBox("24-hours Hotline", "03-123456789"),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _callHotline() async {
    final uri = Uri(scheme: "tel", path: "+03-123456789");
    if (!await launchUrl(uri)) {
      AppLogger.error("Could not launch hotline: $uri");
    }
  }

  Widget _buildInfoBox(String title, String value) {
    return Container(
      width: 170,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 5),
          Text(
            value,
            style: const TextStyle(fontSize: 14, color: Colors.black54),
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
          "You already have an upcoming or active reservation.\n"
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
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomButtons(
    BuildContext context,
    ChargingStationDetail station,
    ChargingStationDetailViewModel viewModel,
  ) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            ElevatedButton(
              onPressed: () {
                final lat = station.parsedLatitude;
                final lng = station.parsedLongitude;

                if (lat != null && lng != null) {
                  MapUtils.openMap(lat, lng);
                } else {
                  AppLogger.error("Could not parse latitude/longitude");
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
              child: const Text(
                "BRING ME THERE",
                style: TextStyle(color: Colors.white),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                switch (viewModel.getReserveIntent()) {
                  case ChargingStationReserveIntent.authenticationRequired:
                    _showAuthReminder(context);
                  case ChargingStationReserveIntent.existingReservation:
                    _showReservationReminder(context);
                  case ChargingStationReserveIntent.allowed:
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            ChargingReservationScreen(stationId: stationId),
                      ),
                    );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: viewModel.canReserve
                    ? Colors.blue
                    : Colors.grey,
              ),
              child: const Text(
                "RESERVE",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
