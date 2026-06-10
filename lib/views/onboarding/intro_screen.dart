import 'package:flutter/material.dart';

import '../../core/constants/colors.dart';
import '../../core/constants/constants.dart';
import '../../core/constants/text_styles.dart';
import '../../core/routes/app_routes.dart';
import '../../viewmodels/onboarding/onboarding_viewmodel.dart';

class IntroScreen extends StatefulWidget {
  const IntroScreen({super.key});

  @override
  State<IntroScreen> createState() => _IntroScreenState();
}

class _IntroScreenState extends State<IntroScreen> {
  final vm = OnboardingViewmodel();

  @override
  void initState() {
    super.initState();
    vm.requestLocationPermission(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            width: double.infinity,
            height: MediaQuery.of(context).size.height * 0.8,
            decoration: const BoxDecoration(
              color: Color(0xFF1E1E1E),
              borderRadius: BorderRadius.vertical(
                bottom: Radius.elliptical(300, 200),
              ),
            ),
            // Oval Center Widget
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // App Logo
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Image.asset(AppMedia.ezchargeLogo, fit: BoxFit.fill),
                ),
                // Title Text
                Text(
                  'EZCHARGE',
                  style: AppTextStyles.displayLarge.copyWith(
                    color: AppColors.white,
                  ),
                ),
              ],
            ),
          ),
          SafeArea(
            minimum: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pushNamed(
                        context,
                        AppRoutes.introScheduleScreen,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      "Next",
                      style: AppTextStyles.displayMedium.copyWith(
                        color: AppColors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
