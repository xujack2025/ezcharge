import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../../../viewmodels/application/add_card_viewmodel.dart';

class AddCardScreen extends StatelessWidget {
  const AddCardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => AddCardViewModel(),
      child: const _AddCardContent(),
    );
  }
}

class _AddCardContent extends StatefulWidget {
  const _AddCardContent();

  @override
  State<_AddCardContent> createState() => _AddCardContentState();
}

class _AddCardContentState extends State<_AddCardContent> {
  final TextEditingController _cardNumberController = TextEditingController();
  final TextEditingController _expiryDateController = TextEditingController();
  final TextEditingController _cvvController = TextEditingController();

  @override
  void dispose() {
    _cardNumberController.dispose();
    _expiryDateController.dispose();
    _cvvController.dispose();
    super.dispose();
  }

  Future<void> _addCard() async {
    final viewModel = context.read<AddCardViewModel>();
    final result = await viewModel.addCard(
      cardNumber: _cardNumberController.text,
      expiredDate: _expiryDateController.text,
      cvv: _cvvController.text,
    );

    if (!mounted) return;

    switch (result) {
      case AddCardResult.success:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Card added successfully!")),
        );
        Navigator.pop(context, true);
        return;
      case AddCardResult.emptyFields:
        _showSnackBar("Please fill in all fields!");
      case AddCardResult.customerNotFound:
        _showSnackBar("Customer profile was not found.");
      case AddCardResult.duplicate:
        _showSnackBar("This card is already registered!");
      case AddCardResult.failed:
        _showSnackBar("Failed to add card. Try again!");
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<AddCardViewModel>();

    return Dialog(
      insetPadding: const EdgeInsets.all(20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Add debit / credit card",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            // Card Number Input
            const Text("Card Number"),
            TextField(
              controller: _cardNumberController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                hintText: "XXXX-XXXX-XXXX-XXXX",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),

            // Expiry Date Input
            const Text("Expired Date"),
            TextField(
              controller: _expiryDateController,
              keyboardType: TextInputType.datetime,
              decoration: const InputDecoration(
                hintText: "MM / YY",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),

            // CVV Input
            const Text("CVV"),
            TextField(
              controller: _cvvController,
              keyboardType: TextInputType.number,
              obscureText: true,
              decoration: const InputDecoration(
                hintText: "XXX",
                border: OutlineInputBorder(),
                suffixIcon: Icon(Icons.help_outline),
              ),
            ),
            const SizedBox(height: 20),

            // Proceed Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: viewModel.isLoading ? null : _addCard,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                ),
                child: viewModel.isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        "PROCEED",
                        style: TextStyle(color: Colors.white),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
