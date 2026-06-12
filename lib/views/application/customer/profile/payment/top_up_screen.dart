import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../../viewmodels/application/top_up_viewmodel.dart';
import 'reload_pin_screen.dart';

class TopUpScreen extends StatelessWidget {
  const TopUpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => TopUpViewModel()..loadTopUpProfile(),
      child: const _TopUpContent(),
    );
  }
}

class _TopUpContent extends StatefulWidget {
  const _TopUpContent();

  @override
  State<_TopUpContent> createState() => _TopUpContentState();
}

class _TopUpContentState extends State<_TopUpContent> {
  final TextEditingController _amountController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _amountController.addListener(_syncAmount);
  }

  @override
  void dispose() {
    _amountController
      ..removeListener(_syncAmount)
      ..dispose();
    super.dispose();
  }

  void _syncAmount() {
    context.read<TopUpViewModel>().setAmountText(_amountController.text);
  }

  void _setQuickAmount(int amount) {
    _amountController.value = TextEditingValue(
      text: amount.toString(),
      selection: TextSelection.collapsed(offset: amount.toString().length),
    );
    context.read<TopUpViewModel>().selectQuickAmount(amount);
  }

  Widget _buildCardNumberDisplay(TopUpViewModel viewModel) {
    if (!viewModel.hasCard) {
      return const SizedBox.shrink();
    }

    return GestureDetector(
      onTap: () => viewModel.selectPaymentMethod(TopUpPaymentMethod.card),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 15),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: viewModel.isCardSelected
              ? Colors.blue.withValues(alpha: 0.3)
              : Colors.white,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(
              Icons.credit_card,
              size: 30,
              color: viewModel.isCardSelected ? Colors.blue : Colors.black,
            ),
            const SizedBox(width: 10),
            Text(
              viewModel.cardNumber,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitTopUp(TopUpViewModel viewModel) async {
    final enteredAmount = viewModel.selectedAmount;
    if (enteredAmount == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid top-up amount.')),
      );
      return;
    }

    if (viewModel.isReloadPinSelected) {
      final didTopUp = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (context) => ReloadPINScreen(topUpAmount: enteredAmount),
        ),
      );
      if (didTopUp == true && mounted) {
        Navigator.pop(context, true);
      }
      return;
    }

    if (!viewModel.isCardSelected) return;

    final result = await viewModel.topUpWithCard();
    if (!mounted) return;

    switch (result) {
      case TopUpResult.success:
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Top-up successful!')));
        Navigator.pop(context, true);
      case TopUpResult.invalidAmount:
      case TopUpResult.customerNotFound:
      case TopUpResult.failed:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              viewModel.errorMessage ??
                  'Unable to update wallet. Please try again.',
            ),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<TopUpViewModel>();
    final canSubmit = viewModel.canSubmit && !viewModel.isLoading;

    return Scaffold(
      backgroundColor: Colors.grey[200],
      resizeToAvoidBottomInset: false,
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
          'Top Up EZCHARGE Credit',
          style: TextStyle(
            color: Colors.black,
            fontSize: 23,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
                          'EZCharge Credits',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          'RM ${viewModel.walletBalance.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    if (viewModel.isLoading)
                      const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                  ],
                ),
              ),
              if (viewModel.errorMessage != null) ...[
                const SizedBox(height: 10),
                Text(
                  viewModel.errorMessage!,
                  style: const TextStyle(color: Colors.red),
                ),
              ],
              const SizedBox(height: 20),
              const Text(
                'Enter Top Up Amount',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  prefixText: 'RM ',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [50, 100, 150].map((amount) {
                  return ElevatedButton(
                    onPressed: () => _setQuickAmount(amount),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      side: const BorderSide(color: Colors.blue),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                    ),
                    child: Text(
                      'RM $amount',
                      style: const TextStyle(
                        color: Colors.blue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  );
                }).toList(),
              ),
              _buildCardNumberDisplay(viewModel),
              GestureDetector(
                onTap: () {
                  if (viewModel.isReloadPinSelected) {
                    viewModel.clearPaymentMethod();
                  } else {
                    viewModel.selectPaymentMethod(TopUpPaymentMethod.reloadPin);
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: viewModel.isReloadPinSelected
                        ? Colors.blue[100]
                        : Colors.white,
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
                      Icon(
                        Icons.autorenew,
                        color: viewModel.isReloadPinSelected
                            ? Colors.blue
                            : Colors.black,
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        'Reload PIN',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 270),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: canSubmit ? () => _submitTopUp(viewModel) : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: canSubmit ? Colors.blue : Colors.grey,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                  ),
                  child: viewModel.isProcessingTopUp
                      ? const CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        )
                      : const Text(
                          'Top Up',
                          style: TextStyle(color: Colors.white, fontSize: 18),
                        ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
