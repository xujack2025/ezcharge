import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/constants.dart';
import '../../core/constants/text_styles.dart';
import '../../core/routes/app_routes.dart';
import '../../viewmodels/onboarding/onboarding_viewmodel.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<OnboardingViewmodel>();
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        minimum: EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// Title
            Text('EZCHARGE', style: AppTextStyles.displayMedium),

            /// Content
            SizedBox(height: 60),
            Center(
              child: Column(
                children: [
                  const Text(
                    'Welcome to Malaysia',
                    style: AppTextStyles.headlineLarge,
                  ),

                  /// Map with Marker
                  const SizedBox(height: 30),
                  Image(
                    width: MediaQuery.of(context).size.width * 0.7,
                    image: AssetImage(
                      AppMedia.welcomeMap,
                    ), // Replace with actual map image
                    fit: BoxFit.cover,
                  ),

                  /// Terms and Privacy Checkbox
                  const SizedBox(height: 50),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Checkbox(
                        value: vm.isChecked,
                        onChanged: (value) {
                          vm.isChecked = value;
                        },
                      ),
                      const Expanded(
                        child: Text.rich(
                          style: AppTextStyles.bodyMedium,
                          TextSpan(
                            text: 'By continuing, you agree to the ',
                            children: [
                              TextSpan(
                                text: 'Terms of Use',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                              TextSpan(text: ' and '),
                              TextSpan(
                                text: 'Privacy Policy',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                              TextSpan(text: ', including cookie use.'),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),

                  /// Continue Button
                  const SizedBox(height: 20),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 35,
                        vertical: 10,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: vm.isChecked
                        ? () {
                            // Navigate to Sign In Screen
                            Navigator.pushNamedAndRemoveUntil(
                              context,
                              AppRoutes.signInScreen,
                              (route) => false,
                            );
                          }
                        : null,
                    child: Text(
                      'CONTINUE',
                      style: AppTextStyles.headlineMedium.copyWith(
                        color: AppColors.white,
                        letterSpacing: 8,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
