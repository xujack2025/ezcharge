import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/colors.dart';
import '../../core/constants/text_styles.dart';
import '../../viewmodels/startup_viewmodel.dart';

class StartupScreen extends StatefulWidget {
  const StartupScreen({super.key});

  @override
  State<StartupScreen> createState() => _StartupScreenState();
}

class _StartupScreenState extends State<StartupScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _resolveStartupRoute();
    });
  }

  Future<void> _resolveStartupRoute() async {
    final route = await context.read<StartupViewModel>().resolveInitialRoute();
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, route);
  }

  @override
  Widget build(BuildContext context) {
    final startupViewModel = context.watch<StartupViewModel>();

    return Scaffold(
      backgroundColor: AppColors.black,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "EZCHARGE",
              style: AppTextStyles.headlineMedium.copyWith(
                color: AppColors.white,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 24),
            const CircularProgressIndicator(color: AppColors.white),
            if (startupViewModel.errorMessage != null) ...[
              const SizedBox(height: 16),
              Text(
                startupViewModel.errorMessage!,
                style: const TextStyle(color: Colors.white),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
