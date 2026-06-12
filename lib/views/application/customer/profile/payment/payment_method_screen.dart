import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../../../viewmodels/application/payment_method_viewmodel.dart';
import 'add_card_screen.dart';
import 'top_up_screen.dart';

class PaymentMethodScreen extends StatelessWidget {
  const PaymentMethodScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => PaymentMethodViewModel()..loadPaymentMethodProfile(),
      child: const _PaymentMethodContent(),
    );
  }
}

class _PaymentMethodContent extends StatelessWidget {
  const _PaymentMethodContent();

  Future<void> _refreshPaymentMethodProfile(BuildContext context) {
    return context.read<PaymentMethodViewModel>().loadPaymentMethodProfile();
  }

  Widget _buildCardNumberDisplay(String cardNumber) {
    return cardNumber.isNotEmpty
        ? Container(
            margin: const EdgeInsets.symmetric(vertical: 15),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 5,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Row(
              children: [
                const Icon(Icons.credit_card, size: 30, color: Colors.black),
                const SizedBox(width: 10),
                Text(
                  cardNumber,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          )
        : const SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<PaymentMethodViewModel>();

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
          "Payment Method",
          style: TextStyle(
            color: Colors.black,
            fontSize: 25,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (viewModel.errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  viewModel.errorMessage!,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            // 🔹 EZCharge Wallet Balance Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 5,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "EZCharge Credits",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        "RM ${viewModel.walletBalance.toStringAsFixed(2)}",
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      final didTopUp = await Navigator.push<bool>(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const TopUpScreen(),
                        ),
                      );
                      if (didTopUp == true) {
                        if (!context.mounted) return;
                        await _refreshPaymentMethodProfile(context);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                    ),
                    child: const Text(
                      "+ TOP UP",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            //Display Saved Card (If Exists)
            if (viewModel.isLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 15),
                child: CircularProgressIndicator(),
              )
            else
              _buildCardNumberDisplay(viewModel.cardNumber),

            //Add Payment Method Section
            ElevatedButton.icon(
              onPressed: () async {
                bool? isCardAdded = await showDialog(
                  context: context,
                  builder: (context) => const AddCardScreen(),
                );

                //Refresh if card was added
                if (isCardAdded == true) {
                  if (!context.mounted) return;
                  await _refreshPaymentMethodProfile(context);
                }
              },
              icon: const Icon(Icons.add, color: Colors.blue),
              label: const Text("Add debit / credit card"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                side: const BorderSide(color: Colors.blue),
                foregroundColor: Colors.blue,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
