import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../../../models/profile_account_model.dart';
import '../../../../../../viewmodels/application/profile_activity_viewmodel.dart';
import '../../../check_in_screen.dart';
import '../../charging/charging_session_timer_screen.dart';

class ActivityScreen extends StatelessWidget {
  const ActivityScreen({super.key, this.initialTabIndex = 0});

  final int initialTabIndex;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ProfileActivityViewModel()..loadActivity(),
      child: _ActivityContent(initialTabIndex: initialTabIndex),
    );
  }
}

class _ActivityContent extends StatefulWidget {
  const _ActivityContent({required this.initialTabIndex});

  final int initialTabIndex;

  @override
  State<_ActivityContent> createState() => _ActivityContentState();
}

class _ActivityContentState extends State<_ActivityContent>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 3,
      vsync: this,
      initialIndex: widget.initialTabIndex,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _cancelReservation() async {
    final viewModel = context.read<ProfileActivityViewModel>();
    final result = await viewModel.cancelReservation();
    if (!mounted) return;

    switch (result) {
      case ProfileCancelReservationResult.success:
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Reservation Cancelled!')));
      case ProfileCancelReservationResult.customerNotFound:
      case ProfileCancelReservationResult.failed:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              viewModel.errorMessage ??
                  'Unable to cancel reservation. Please try again.',
            ),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<ProfileActivityViewModel>();

    return Scaffold(
      backgroundColor: Colors.grey[200],
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
          'Charging',
          style: TextStyle(
            color: Colors.black,
            fontSize: 23,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.blue,
          labelColor: Colors.black,
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(text: 'Upcoming'),
            Tab(text: 'Active'),
            Tab(text: 'Ended'),
          ],
        ),
      ),
      body: viewModel.isLoading
          ? const Center(child: CircularProgressIndicator())
          : viewModel.errorMessage != null
          ? Center(child: Text(viewModel.errorMessage!))
          : TabBarView(
              controller: _tabController,
              children: [
                _UpcomingTab(
                  reservation: viewModel.hasUpcomingReservation
                      ? viewModel.reservation
                      : null,
                  onCancelReservation: _confirmCancelReservation,
                ),
                _ActiveTab(
                  reservation: viewModel.hasActiveReservation
                      ? viewModel.reservation
                      : null,
                ),
                _EndedTab(attendances: viewModel.endedAttendances),
              ],
            ),
    );
  }

  void _confirmCancelReservation() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Confirm Cancellation'),
          content: const Text(
            'Are you sure you want to cancel the reservation?',
          ),
          actions: [
            TextButton(
              child: const Text('No'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text('Yes'),
              onPressed: () {
                Navigator.of(context).pop();
                _cancelReservation();
              },
            ),
          ],
        );
      },
    );
  }
}

class _UpcomingTab extends StatelessWidget {
  const _UpcomingTab({
    required this.reservation,
    required this.onCancelReservation,
  });

  final ProfileReservationActivity? reservation;
  final VoidCallback onCancelReservation;

  @override
  Widget build(BuildContext context) {
    final reservation = this.reservation;
    if (reservation == null) {
      return const Center(child: Text('No upcoming reservations.'));
    }

    return SingleChildScrollView(
      child: Align(
        alignment: Alignment.topCenter,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: _ReservationCard(
            reservation: reservation,
            showPriceRow: true,
            footer: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const CheckInScreen(),
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
                      'CHECK IN',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: onCancelReservation,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                    child: const Text(
                      'CANCEL RESERVE',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ActiveTab extends StatelessWidget {
  const _ActiveTab({required this.reservation});

  final ProfileReservationActivity? reservation;

  @override
  Widget build(BuildContext context) {
    final reservation = this.reservation;
    if (reservation == null) {
      return const Center(child: Text('No active reservations.'));
    }

    return SingleChildScrollView(
      child: Align(
        alignment: Alignment.topCenter,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ChargingSessionTimerScreen(),
                ),
              );
            },
            child: _ReservationCard(
              reservation: reservation,
              showPriceRow: false,
              footer: Row(
                children: [
                  Text(
                    '${reservation.chargerVoltage} ${reservation.currentType}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${ChargingSessionTimerService.hoursStr}:'
                    '${ChargingSessionTimerService.minutesStr}:'
                    '${ChargingSessionTimerService.secondsStr}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ReservationCard extends StatelessWidget {
  const _ReservationCard({
    required this.reservation,
    required this.footer,
    required this.showPriceRow,
  });

  final ProfileReservationActivity reservation;
  final Widget footer;
  final bool showPriceRow;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 4, spreadRadius: 1),
        ],
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            reservation.stationName,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Text(
                reservation.chargerName,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                reservation.chargerType,
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ],
          ),
          const SizedBox(height: 6),
          if (showPriceRow)
            Row(
              children: [
                Text(
                  '${reservation.chargerVoltage} ${reservation.currentType}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Text(
                  'RM ${reservation.pricePerVoltage}/kW',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          const SizedBox(height: 10),
          footer,
        ],
      ),
    );
  }
}

class _EndedTab extends StatelessWidget {
  const _EndedTab({required this.attendances});

  final List<ProfileEndedAttendance> attendances;

  @override
  Widget build(BuildContext context) {
    if (attendances.isEmpty) {
      return const Center(child: Text('No ended reservations.'));
    }

    return ListView.builder(
      itemCount: attendances.length,
      itemBuilder: (context, index) {
        final attendance = attendances[index];
        return Padding(
          padding: const EdgeInsets.all(12),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 4,
                  spreadRadius: 1,
                ),
              ],
            ),
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Station: ${attendance.stationName}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      'Charger: ${attendance.chargerName}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      'Duration: ${attendance.duration}',
                      style: const TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Text(
                      attendance.checkInTime != null
                          ? 'CheckIn: ${_dateText(attendance.checkInTime!)}'
                          : 'CheckIn: -',
                      style: const TextStyle(fontSize: 14),
                    ),
                    const Spacer(),
                    Text(
                      attendance.checkOutTime != null
                          ? 'CheckOut: ${_dateText(attendance.checkOutTime!)}'
                          : 'CheckOut: -',
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'TotalCost: RM${attendance.totalCost}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _dateText(DateTime dateTime) {
    return dateTime.toString().substring(0, 16);
  }
}
