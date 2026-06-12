import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../../../viewmodels/application/delete_account_viewmodel.dart';
import '../../../../onboarding/intro_screen.dart';

class ConfirmDeleteScreen extends StatelessWidget {
  const ConfirmDeleteScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => DeleteAccountViewModel(),
      child: const _ConfirmDeleteContent(),
    );
  }
}

class _ConfirmDeleteContent extends StatelessWidget {
  const _ConfirmDeleteContent();

  Future<void> _deleteAccount(BuildContext context) async {
    final viewModel = context.read<DeleteAccountViewModel>();
    final result = await viewModel.deleteAccount();
    if (!context.mounted) return;

    switch (result) {
      case DeleteAccountResult.success:
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const IntroScreen()),
          (route) => false,
        );
      case DeleteAccountResult.noUser:
      case DeleteAccountResult.customerNotFound:
      case DeleteAccountResult.failed:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              viewModel.errorMessage ??
                  'Unable to delete account. Please try again.',
            ),
          ),
        );
    }
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'Delete Account',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: const Text(
            'Are you sure you want to permanently remove your account?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('No', style: TextStyle(color: Colors.blue)),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                _deleteAccount(context);
              },
              child: const Text('Yes', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<DeleteAccountViewModel>();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
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
          'Delete Account',
          style: TextStyle(
            color: Colors.black,
            fontSize: 30,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'We are sorry to receive your leaving',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              'Are you sure you want to delete your account?\nYou will permanently lose:',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 10),
            const Text(
              '- Profile\n- Bookmarks\n- Charging records\n- Rewards',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),
            const Row(
              children: [
                Icon(Icons.warning, color: Colors.orange),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Please note that the account deletion is irreversible. Think wise!',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ),
              ],
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: viewModel.isLoading
                    ? null
                    : () => _showDeleteConfirmation(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
                child: viewModel.isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'DELETE',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
