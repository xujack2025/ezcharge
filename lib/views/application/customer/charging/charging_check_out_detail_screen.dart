import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../../viewmodels/charging/charging_checkout_viewmodel.dart';
import '../service/chatbot_screen.dart';
import 'charging_check_out_success_screen.dart';

class ChargingCheckOutDetailScreen extends StatefulWidget {
  final Duration totalDuration;

  const ChargingCheckOutDetailScreen({super.key, required this.totalDuration});

  @override
  State<ChargingCheckOutDetailScreen> createState() =>
      _ChargingCheckOutDetailScreenState();
}

class _ChargingCheckOutDetailScreenState
    extends State<ChargingCheckOutDetailScreen> {
  Timer? _countdownTimer;
  int _remainingSeconds = 10;
  int _overTimeMinutes = 0;
  double _penalty = 0;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _startCountdown() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;

      setState(() {
        if (_remainingSeconds > 0) {
          _remainingSeconds--;
        } else {
          final totalOverSeconds = -_remainingSeconds;
          final newOverTimeMinutes = totalOverSeconds ~/ 60;

          if (newOverTimeMinutes > _overTimeMinutes) {
            _overTimeMinutes = newOverTimeMinutes;
            _penalty = _overTimeMinutes * 10;

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'You are $_overTimeMinutes minute(s) overdue.\n'
                  'Current penalty: RM$_penalty',
                ),
                duration: const Duration(seconds: 3),
              ),
            );
          }
          _remainingSeconds--;
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ChargingCheckoutViewModel()..load(),
      child: Consumer<ChargingCheckoutViewModel>(
        builder: (context, viewModel, _) {
          final durationString = _formatDuration(widget.totalDuration);
          final totalAmount = viewModel.chargingCostFor(widget.totalDuration);

          return Scaffold(
            backgroundColor: Colors.white,
            body: viewModel.isLoading
                ? const Center(child: CircularProgressIndicator())
                : Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Row(
                              children: [
                                SizedBox(width: 5),
                                Text(
                                  'Check Out',
                                  style: TextStyle(
                                    fontSize: 25,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                                ),
                              ],
                            ),
                            Padding(
                              padding: const EdgeInsets.only(right: 12),
                              child: InkWell(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const ChatbotScreen(),
                                    ),
                                  );
                                },
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.support_agent,
                                      color: Colors.blue,
                                      size: 30,
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      'Help',
                                      style: TextStyle(
                                        color: Colors.blue,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Center(
                          child: Image.asset(
                            'assets/images/charging.png',
                            fit: BoxFit.contain,
                            height: 150,
                          ),
                        ),
                        const SizedBox(height: 20),
                        _infoRow('Charging Station:', viewModel.stationName),
                        _infoRow('Charging Slot:', viewModel.chargerName),
                        _infoRow('Charger Type:', viewModel.chargerType),
                        _infoRow(
                          'Price per KWH:',
                          'RM${viewModel.pricePerVoltage}',
                        ),
                        _infoRow(
                          'Reserved Time:',
                          DateFormat(
                            'yyyy-MM-dd HH:mm',
                          ).format(viewModel.startTime),
                        ),
                        const SizedBox(height: 10),
                        _infoRow('Total Duration:', durationString),
                        _infoRow(
                          'Total Amount:',
                          'RM ${totalAmount.toStringAsFixed(2)}',
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: viewModel.isCheckingOut
                                ? null
                                : () => _confirmCheckOut(
                                    context,
                                    viewModel,
                                    durationString,
                                    totalAmount,
                                  ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              padding: const EdgeInsets.symmetric(vertical: 15),
                            ),
                            child: Text(
                              viewModel.isCheckingOut
                                  ? 'CHECKING OUT...'
                                  : 'CHECK OUT',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        _buildCountdownWidget(),
                      ],
                    ),
                  ),
          );
        },
      ),
    );
  }

  Future<void> _confirmCheckOut(
    BuildContext context,
    ChargingCheckoutViewModel viewModel,
    String durationString,
    double totalAmount,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Check Out'),
          content: const Text(
            'Are you sure you want to check out from the slot?\n'
            'Once check out, you need to reserve a slot for charging.',
          ),
          actions: [
            TextButton(
              child: const Text('NO'),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            TextButton(
              child: const Text('YES'),
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !context.mounted) return;

    final result = await viewModel.checkOut(
      duration: widget.totalDuration,
      durationText: durationString,
      penaltyCost: _penalty,
    );
    if (!context.mounted) return;

    switch (result) {
      case ChargingCheckoutResult.success:
        _countdownTimer?.cancel();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Check-out successful!')));
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChargingCheckOutSuccessScreen(
              chargingCost: totalAmount,
              penaltyCost: _penalty,
              duration: durationString,
            ),
          ),
        );
        break;
      case ChargingCheckoutResult.notEnded:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Cannot create attendance record until reservation is Ended.',
            ),
          ),
        );
        break;
      case ChargingCheckoutResult.noReservation:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No active reservation found.')),
        );
        break;
      case ChargingCheckoutResult.failed:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Check-out failed. Try again!')),
        );
        break;
    }
  }

  Widget _buildCountdownWidget() {
    if (_remainingSeconds >= 0) {
      final minutesLeft = _remainingSeconds ~/ 60;
      final secondsLeft = _remainingSeconds % 60;
      final formatted =
          '${minutesLeft.toString().padLeft(2, '0')}'
          ':${secondsLeft.toString().padLeft(2, '0')}';
      return Text(
        '⚠ You still have $formatted minutes to check out from the slot.',
        style: const TextStyle(color: Colors.orange),
      );
    }

    return Text(
      'Overtime: $_overTimeMinutes minute(s)\n'
      'Current penalty: RM$_penalty',
      style: const TextStyle(color: Colors.red),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(duration.inHours);
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$hours:$minutes:$seconds';
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(width: 5),
          Expanded(
            child: Text(
              value.isNotEmpty ? value : '-',
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }
}
