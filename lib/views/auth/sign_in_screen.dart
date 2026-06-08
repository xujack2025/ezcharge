import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/colors.dart';
import '../../core/constants/text_styles.dart';
import '../../core/routes/app_routes.dart';
import '../../core/widgets/button.dart';
import '../../core/widgets/custom_divider.dart';
import '../../core/widgets/phone_input.dart';
import '../../core/widgets/top_app_bar.dart';
import '../../models/user_model.dart';
import '../../viewmodels/auth/auth_viewmodel.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _phoneController = TextEditingController();

  final role = UserRole.customer;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authViewModel = context.watch<AuthViewModel>();

    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: CustomAppBar(title: "Sign In", showBackButton: false),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Sign in or create account with your phone number",
                style: AppTextStyles.titleLarge,
              ),
              const SizedBox(height: 5),

              const Text(
                "A verification code will be sent to this phone number",
                style: AppTextStyles.labelLarge,
              ),
              const SizedBox(height: 16),

              // Phone Number Input
              AppPhoneInput(
                controller: _phoneController,
                onInputChanged: (number) {
                  authViewModel.fullPhoneNumber = number.phoneNumber ?? "";
                },
              ),
              if (authViewModel.errorMessage != null) ...[
                const SizedBox(height: 5),
                Text(
                  authViewModel.errorMessage!,
                  style: AppTextStyles.labelLarge.copyWith(
                    color: AppColors.danger,
                  ),
                ),
              ],
              const SizedBox(height: 16),

              /// Submit Button
              CustomButton(
                text: "Submit",
                isLoading: authViewModel.isLoading,
                onPressed: () => authViewModel.submitPhoneNumber(
                  context,
                  authViewModel.fullPhoneNumber,
                  role,
                ),
                borderRadius: 22,
              ),

              /// Divider
              const SizedBox(height: 16),
              LabeledDivider(label: "Or"),
              const SizedBox(height: 16),

              // Admin Sign In Button
              Center(
                child: TextButton(
                  onPressed: () {
                    authViewModel.clearError();
                    Navigator.pushNamed(context, AppRoutes.adminSignInScreen);
                  },
                  child: Text(
                    "Sign In as Admin",
                    style: AppTextStyles.labelLarge.copyWith(
                      color: Colors.blue,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
