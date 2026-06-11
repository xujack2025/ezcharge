import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../models/charging_checkout_model.dart';
import '../../../../viewmodels/charging/charging_payment_viewmodel.dart';
import '../profile/payment/top_up_screen.dart';
import 'charging_payment_success_screen.dart';

class ChargingPaymentMethodScreen extends StatefulWidget {
  final double totalAmount;
  final String rewardID;
  final int rewardPoints;

  const ChargingPaymentMethodScreen({
    super.key,
    required this.totalAmount,
    required this.rewardID,
    required this.rewardPoints,
  });

  @override
  State<ChargingPaymentMethodScreen> createState() =>
      _ChargingPaymentMethodScreenState();
}

class _ChargingPaymentMethodScreenState
    extends State<ChargingPaymentMethodScreen> {
  @override
  Widget build(BuildContext context) {
    final totalStr = widget.totalAmount.toStringAsFixed(2);

    return ChangeNotifierProvider(
      create: (_) => ChargingPaymentViewModel()..loadPaymentProfile(),
      child: Consumer<ChargingPaymentViewModel>(
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
                                'Payment',
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
                                'Total Amount',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'RM $totalStr',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                              const SizedBox(height: 24),
                              const Text(
                                'Please choose a payment method',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.black,
                                ),
                              ),
                              const SizedBox(height: 16),
                              RadioGroup<ChargingPaymentMethod>(
                                groupValue: viewModel.selectedMethod,
                                onChanged: (value) {
                                  if (value != null) {
                                    viewModel.selectPaymentMethod(value);
                                  }
                                },
                                child: Column(
                                  children: [
                                    if (viewModel.cardNumber != null &&
                                        viewModel.cardNumber!.isNotEmpty)
                                      _buildCardOption(viewModel),
                                    _buildWalletOption(context, viewModel),
                                  ],
                                ),
                              ),
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
                                  : () => _pay(context, viewModel),
                              child: Text(
                                viewModel.isProcessing ? 'PAYING...' : 'PAY',
                                style: const TextStyle(
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

  Future<void> _pay(
    BuildContext context,
    ChargingPaymentViewModel viewModel,
  ) async {
    if (viewModel.selectedMethod == ChargingPaymentMethod.card) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Processing card payment...')),
      );
      await Future.delayed(const Duration(seconds: 3));
      if (!context.mounted) return;
    }

    final paymentMethodLabel = viewModel.selectedPaymentMethodLabel();
    final result = await viewModel.processPayment(
      totalAmount: widget.totalAmount,
      rewardId: widget.rewardID,
      rewardPoints: widget.rewardPoints,
    );
    if (!context.mounted) return;

    switch (result) {
      case ChargingPaymentResult.success:
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Payment successful!')));
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ChargingPaymentSuccessScreen(
              paymentMethod: paymentMethodLabel,
              totalAmount: widget.totalAmount,
            ),
          ),
        );
        break;
      case ChargingPaymentResult.insufficientBalance:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Your wallet balance is not enough.')),
        );
        break;
      case ChargingPaymentResult.noCustomer:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Customer payment profile was not found.'),
          ),
        );
        break;
      case ChargingPaymentResult.failed:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Payment failed. Try again!')),
        );
        break;
    }
  }

  Widget _buildCardOption(ChargingPaymentViewModel viewModel) {
    final cardNumber = viewModel.cardNumber ?? '';
    final last4 = cardNumber.length >= 4
        ? cardNumber.substring(cardNumber.length - 4)
        : cardNumber;
    final maskedCard = '**** **** **** $last4';

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () => viewModel.selectPaymentMethod(ChargingPaymentMethod.card),
        child: Row(
          children: [
            const Radio<ChargingPaymentMethod>(
              value: ChargingPaymentMethod.card,
            ),
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
    ChargingPaymentViewModel viewModel,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () =>
            viewModel.selectPaymentMethod(ChargingPaymentMethod.wallet),
        child: Row(
          children: [
            const Radio<ChargingPaymentMethod>(
              value: ChargingPaymentMethod.wallet,
            ),
            const Icon(Icons.account_balance_wallet_outlined, size: 30),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Credit Balance: RM${viewModel.walletBalance.toStringAsFixed(2)}',
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
                '+ TOP UP',
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
