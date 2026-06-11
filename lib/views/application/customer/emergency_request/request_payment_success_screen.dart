import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../viewmodels/emergency_payment_viewmodel.dart';
import 'request_payment_history_detail_screen.dart';

class RequestPaymentSuccessScreen extends StatefulWidget {
  const RequestPaymentSuccessScreen({
    super.key,
    required this.paymentMethod,
    required this.totalAmount,
  });

  final String paymentMethod;
  final double totalAmount;

  @override
  State<RequestPaymentSuccessScreen> createState() =>
      _RequestPaymentSuccessScreenState();
}

class _RequestPaymentSuccessScreenState
    extends State<RequestPaymentSuccessScreen> {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => EmergencyPaymentViewModel()..loadSuccessDetails(),
      child: Consumer<EmergencyPaymentViewModel>(
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
                            "Payment Successful!",
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
                            "Thank you for your payment\n"
                            "Kindly check your receipt in the payment history",
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
                              child: viewModel.isCreatingHistory
                                  ? const CircularProgressIndicator(
                                      color: Colors.white,
                                    )
                                  : const Text(
                                      "DONE",
                                      style: TextStyle(
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
    EmergencyPaymentViewModel viewModel,
  ) async {
    final details = viewModel.successDetails;
    final (result, paymentId) = await viewModel.createPaymentHistory(
      paymentMethod: widget.paymentMethod,
      totalAmount: widget.totalAmount,
    );
    if (!context.mounted) return;

    switch (result) {
      case EmergencyPaymentHistoryResult.success:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => RequestPaymentHistoryDetailScreen(
              accountId: details?.customerId ?? "",
              paymentDocId: paymentId ?? "",
              requestId: details?.requestId ?? "",
            ),
          ),
        );
        return;
      case EmergencyPaymentHistoryResult.noDetails:
      case EmergencyPaymentHistoryResult.failed:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              viewModel.errorMessage ?? "Failed to create payment record.",
            ),
          ),
        );
    }
  }
}
