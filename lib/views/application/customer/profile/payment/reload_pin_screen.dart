import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../../viewmodels/application/reload_pin_viewmodel.dart';

class ReloadPINScreen extends StatelessWidget {
  const ReloadPINScreen({required this.topUpAmount, super.key});

  final double topUpAmount;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) =>
          ReloadPinViewModel(topUpAmount: topUpAmount)..sendReloadPin(),
      child: const _ReloadPinContent(),
    );
  }
}

class _ReloadPinContent extends StatefulWidget {
  const _ReloadPinContent();

  @override
  State<_ReloadPinContent> createState() => _ReloadPinContentState();
}

class _ReloadPinContentState extends State<_ReloadPinContent> {
  final TextEditingController _otpController = TextEditingController();

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _verifyAndTopUp() async {
    final viewModel = context.read<ReloadPinViewModel>();
    final result = await viewModel.verifyAndTopUp(_otpController.text);

    if (!mounted) return;

    switch (result) {
      case ReloadPinResult.success:
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Top-up successful!')));
        Navigator.pop(context, true);
      case ReloadPinResult.emptyOtp:
      case ReloadPinResult.missingVerification:
      case ReloadPinResult.customerNotFound:
      case ReloadPinResult.invalidOtp:
      case ReloadPinResult.failed:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              viewModel.errorMessage ?? 'Unable to top up. Please try again.',
            ),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<ReloadPinViewModel>();

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
          'Reload with Reload PIN',
          style: TextStyle(
            color: Colors.black,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
      ),
      body: viewModel.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (viewModel.errorMessage != null) ...[
                    Text(
                      viewModel.errorMessage!,
                      style: const TextStyle(color: Colors.red),
                    ),
                    const SizedBox(height: 16),
                  ],
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blue[200],
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Column(
                        children: [
                          Icon(Icons.wallet, size: 50, color: Colors.white),
                          SizedBox(height: 10),
                          Text(
                            'RELOAD PIN\n'
                            '   ******',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Please enter the Reload PIN :',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _otpController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: 'Reload PIN',
                      errorText: viewModel.isOtpValid
                          ? null
                          : viewModel.errorMessage ?? 'Invalid Reload OTP',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: viewModel.hasVerificationId
                          ? _verifyAndTopUp
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: viewModel.hasVerificationId
                            ? Colors.blue
                            : Colors.grey,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                      ),
                      child: const Text(
                        'TOP UP',
                        style: TextStyle(color: Colors.white, fontSize: 18),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
