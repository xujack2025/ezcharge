import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../viewmodels/charging/charging_payment_viewmodel.dart';
import 'charging_payment_method_screen.dart';
import 'charging_reward_selection_screen.dart';

class ChargingPaymentSummaryScreen extends StatefulWidget {
  final double chargingCost;
  final double penaltyCost;
  final String duration;

  const ChargingPaymentSummaryScreen({
    super.key,
    required this.chargingCost,
    required this.penaltyCost,
    required this.duration,
  });

  @override
  State<ChargingPaymentSummaryScreen> createState() =>
      _ChargingPaymentSummaryScreenState();
}

class _ChargingPaymentSummaryScreenState
    extends State<ChargingPaymentSummaryScreen> {
  double _rewardDiscount = 0;
  String _selectedRewardId = '';
  int _rewardPoints = 0;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ChargingPaymentViewModel()..loadSummaryDetails(),
      child: Consumer<ChargingPaymentViewModel>(
        builder: (context, viewModel, _) {
          final subtotal = viewModel.subtotal(
            chargingCost: widget.chargingCost,
            penaltyCost: widget.penaltyCost,
          );
          final totalAmount = viewModel.totalAfterDiscount(
            chargingCost: widget.chargingCost,
            penaltyCost: widget.penaltyCost,
            rewardDiscount: _rewardDiscount,
          );

          return Scaffold(
            backgroundColor: Colors.white,
            body: SafeArea(
              child: viewModel.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Payment',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Container(
                            height: 200,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(8),
                              image: viewModel.stationImageUrl.isEmpty
                                  ? null
                                  : DecorationImage(
                                      image: NetworkImage(
                                        viewModel.stationImageUrl,
                                      ),
                                      fit: BoxFit.cover,
                                    ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          _infoRow('Charging Station:', viewModel.stationName),
                          _infoRow('Charging Slot:', viewModel.chargerName),
                          _infoRow('Charger Type:', viewModel.chargerType),
                          _infoRow('Total Duration:', widget.duration),
                          const SizedBox(height: 16),
                          const Text(
                            'Reward Discount',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          InkWell(
                            onTap: _selectReward,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                vertical: 12,
                                horizontal: 8,
                              ),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade300),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('Select Reward'),
                                  Text(
                                    _rewardDiscount == 0
                                        ? '-'
                                        : '-RM${_rewardDiscount.toStringAsFixed(2)}',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: _rewardDiscount == 0
                                          ? Colors.black
                                          : Colors.red,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          _infoRow(
                            'Charging total:',
                            'RM ${widget.chargingCost.toStringAsFixed(2)}',
                          ),
                          _infoRow(
                            'Penalty total:',
                            'RM ${widget.penaltyCost.toStringAsFixed(2)}',
                          ),
                          _infoRow(
                            'Subtotal:',
                            'RM ${subtotal.toStringAsFixed(2)}',
                          ),
                          _infoRow(
                            'Reward Discount:',
                            _rewardDiscount == 0
                                ? '-'
                                : '-RM${_rewardDiscount.toStringAsFixed(2)}',
                          ),
                          const Divider(height: 32),
                          _infoRow(
                            'Total Amount:',
                            'RM ${totalAmount.toStringAsFixed(2)}',
                            isBold: true,
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        ChargingPaymentMethodScreen(
                                          totalAmount: totalAmount,
                                          rewardID: _selectedRewardId,
                                          rewardPoints: _rewardPoints,
                                        ),
                                  ),
                                );
                              },
                              child: const Text(
                                'CONTINUE',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _selectReward() async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(builder: (_) => const ChargingRewardSelectionScreen()),
    );
    if (result == null || !mounted) return;

    setState(() {
      _rewardDiscount = (result['discount'] as num?)?.toDouble() ?? 0;
      _selectedRewardId = result['rewardID']?.toString() ?? '';
      _rewardPoints = (result['points'] as num?)?.toInt() ?? 0;
    });
  }

  Widget _infoRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 3,
            child: Text(label, style: const TextStyle(fontSize: 16)),
          ),
          Expanded(
            flex: 5,
            child: Text(
              value.isNotEmpty ? value : '-',
              style: TextStyle(
                fontSize: 16,
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
