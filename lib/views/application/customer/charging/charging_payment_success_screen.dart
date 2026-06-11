import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../viewmodels/charging/charging_payment_viewmodel.dart';
import 'charging_payment_history_detail_screen.dart';

class ChargingPaymentSuccessScreen extends StatefulWidget {
  final String paymentMethod;
  final double totalAmount;

  const ChargingPaymentSuccessScreen({
    super.key,
    required this.paymentMethod,
    required this.totalAmount,
  });

  @override
  State<ChargingPaymentSuccessScreen> createState() =>
      _ChargingPaymentSuccessScreenState();
}

class _ChargingPaymentSuccessScreenState
    extends State<ChargingPaymentSuccessScreen> {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ChargingPaymentViewModel()..loadPaymentHistoryDetails(),
      child: Consumer<ChargingPaymentViewModel>(
        builder: (context, viewModel, _) {
          return Scaffold(
            backgroundColor: Colors.white,
            body: viewModel.isLoading
                ? const Center(child: CircularProgressIndicator())
                : Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'Payment Successful!',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 20),
                          const Icon(
                            Icons.check_circle,
                            color: Colors.green,
                            size: 100,
                          ),
                          const SizedBox(height: 20),
                          const Text(
                            'Thank you for your payment\n'
                            'Kindly check your receipt in the payment history',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 16),
                          ),
                          const SizedBox(height: 80),
                          SizedBox(
                            width: 200,
                            height: 45,
                            child: ElevatedButton(
                              onPressed: viewModel.isCreatingHistory
                                  ? null
                                  : () => _createPaymentHistory(
                                      context,
                                      viewModel,
                                    ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: Text(
                                viewModel.isCreatingHistory ? 'SAVING' : 'DONE',
                                style: const TextStyle(
                                  fontSize: 25,
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

  Future<void> _createPaymentHistory(
    BuildContext context,
    ChargingPaymentViewModel viewModel,
  ) async {
    final (result, paymentId) = await viewModel.createPaymentHistory(
      paymentMethod: widget.paymentMethod,
      totalAmount: widget.totalAmount,
    );
    if (!context.mounted) return;

    switch (result) {
      case ChargingPaymentHistoryResult.success:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChargingPaymentHistoryDetailScreen(
              accountId: viewModel.historyDetails!.customerId,
              paymentDocId: paymentId!,
            ),
          ),
        );
        break;
      case ChargingPaymentHistoryResult.noDetails:
      case ChargingPaymentHistoryResult.failed:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to create payment record.')),
        );
        break;
    }
  }
}
