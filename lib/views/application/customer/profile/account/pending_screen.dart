import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../../../viewmodels/application/profile_authentication_viewmodel.dart';
import '../profile_screen.dart';

class PendingScreen extends StatelessWidget {
  const PendingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) =>
          ProfileAuthenticationViewModel()..submitAuthenticationRequest(),
      child: const _PendingContent(),
    );
  }
}

class _PendingContent extends StatefulWidget {
  const _PendingContent();

  @override
  State<_PendingContent> createState() => _PendingContentState();
}

class _PendingContentState extends State<_PendingContent> {
  Timer? _navigationTimer;

  @override
  void initState() {
    super.initState();
    _navigationTimer = Timer(const Duration(seconds: 10), _returnToProfile);
  }

  @override
  void dispose() {
    _navigationTimer?.cancel();
    super.dispose();
  }

  void _returnToProfile() {
    if (!mounted) return;
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
      return;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const ProfileScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<ProfileAuthenticationViewModel>();

    return Scaffold(
      backgroundColor: Colors.grey[200],
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.hourglass_empty, size: 100, color: Colors.blue),
              const SizedBox(height: 20),
              const Text(
                'Your authentication request is pending approval.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                viewModel.errorMessage ??
                    'This process may take some time. Please wait...',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: viewModel.errorMessage == null
                      ? Colors.black54
                      : Colors.red,
                ),
              ),
              if (viewModel.isLoading) ...[
                const SizedBox(height: 20),
                const CircularProgressIndicator(),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
