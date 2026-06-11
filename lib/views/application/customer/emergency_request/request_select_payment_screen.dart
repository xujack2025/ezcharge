import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../models/emergency_payment_model.dart';
import '../../../../viewmodels/emergency_payment_viewmodel.dart';
import '../profile/payment/top_up_screen.dart';
import 'request_payment_success_screen.dart';

class RequestSelectPaymentScreen extends StatefulWidget {
  const RequestSelectPaymentScreen({
    super.key,
    required this.totalAmount,
    required this.rewardID,
    required this.rewardPoints,
  });

  final double totalAmount;
  final String rewardID;
  final int rewardPoints;

  @override
  State<RequestSelectPaymentScreen> createState() =>
      _RequestSelectPaymentScreenState();
}

class _RequestSelectPaymentScreenState
    extends State<RequestSelectPaymentScreen> {
  @override
  Widget build(BuildContext context) {
    final totalStr = widget.totalAmount.toStringAsFixed(2);

    return ChangeNotifierProvider(
      create: (_) => EmergencyPaymentViewModel()..loadPaymentProfile(),
      child: Consumer<EmergencyPaymentViewModel>(
        builder: (context, viewModel, _) {
          return Scaffold(
            backgroundColor: Colors.white,
            body: SafeArea(
              child: viewModel.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              InkWell(
                                onTap: () => Navigator.pop(context),
                                child: Container(
                                  width: 40,
                                  height: 40,
                                  decoration: const BoxDecoration(
                                    color: Colors.blue,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.arrow_back,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Text(
                                "Payment",
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              const Text(
                                "Total Amount",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "RM $totalStr",
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                              const SizedBox(height: 24),
                              const Text(
                                "Please choose a payment method",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.black,
                                ),
                              ),
                              const SizedBox(height: 16),
                              if (viewModel.cardNumber != null &&
                                  viewModel.cardNumber!.isNotEmpty)
                                _buildCardOption(viewModel),
                              _buildWalletOption(context, viewModel),
                            ],
                          ),
                          const Spacer(),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    viewModel.selectedMethod == null ||
                                        viewModel.isProcessing
                                    ? Colors.grey
                                    : Colors.blue,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              onPressed:
                                  viewModel.selectedMethod == null ||
                                      viewModel.isProcessing
                                  ? null
                                  : () => _processPayment(context, viewModel),
                              child: viewModel.isProcessing
                                  ? const CircularProgressIndicator(
                                      color: Colors.white,
                                    )
                                  : const Text(
                                      "PAY",
                                      style: TextStyle(
                                        fontSize: 18,
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

  Future<void> _processPayment(
    BuildContext context,
    EmergencyPaymentViewModel viewModel,
  ) async {
    final result = await viewModel.processPayment(
      totalAmount: widget.totalAmount,
      rewardId: widget.rewardID,
      rewardPoints: widget.rewardPoints,
    );
    if (!context.mounted) return;

    switch (result) {
      case EmergencyPaymentResult.success:
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Payment successful!")));
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => RequestPaymentSuccessScreen(
              paymentMethod: viewModel.selectedPaymentMethodLabel(),
              totalAmount: widget.totalAmount,
            ),
          ),
        );
        return;
      case EmergencyPaymentResult.insufficientBalance:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Your wallet balance is not enough.")),
        );
        return;
      case EmergencyPaymentResult.noCustomer:
      case EmergencyPaymentResult.failed:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              viewModel.errorMessage ?? "Payment failed. Try again!",
            ),
          ),
        );
    }
  }

  Widget _buildCardOption(EmergencyPaymentViewModel viewModel) {
    final cardNumber = viewModel.cardNumber ?? '';
    final last4 = cardNumber.length >= 4
        ? cardNumber.substring(cardNumber.length - 4)
        : cardNumber;
    final maskedCard = "**** **** **** $last4";

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () => viewModel.selectPaymentMethod(EmergencyPaymentMethod.card),
        child: Row(
          children: [
            Icon(
              viewModel.selectedMethod == EmergencyPaymentMethod.card
                  ? Icons.radio_button_checked
                  : Icons.radio_button_off,
              color: Colors.blue,
            ),
            const SizedBox(width: 8),
            const Icon(Icons.credit_card, size: 30),
            const SizedBox(width: 8),
            Text(maskedCard, style: const TextStyle(fontSize: 16)),
          ],
        ),
      ),
    );
  }

  Widget _buildWalletOption(
    BuildContext context,
    EmergencyPaymentViewModel viewModel,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () =>
            viewModel.selectPaymentMethod(EmergencyPaymentMethod.wallet),
        child: Row(
          children: [
            Icon(
              viewModel.selectedMethod == EmergencyPaymentMethod.wallet
                  ? Icons.radio_button_checked
                  : Icons.radio_button_off,
              color: Colors.blue,
            ),
            const SizedBox(width: 8),
            const Icon(Icons.account_balance_wallet_outlined, size: 30),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                "Credit Balance: RM${viewModel.walletBalance.toStringAsFixed(2)}",
                style: const TextStyle(fontSize: 16),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const TopUpScreen()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                padding: const EdgeInsets.symmetric(
                  horizontal: 17,
                  vertical: 9,
                ),
              ),
              child: const Text(
                "+ TOP UP",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
