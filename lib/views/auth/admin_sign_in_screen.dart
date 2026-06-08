import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/text_styles.dart';
import '../../core/widgets/button.dart';
import '../../core/widgets/phone_input.dart';
import '../../core/widgets/top_app_bar.dart';
import '../../models/user_model.dart';
import '../../viewmodels/auth/auth_viewmodel.dart';

class AdminSignInScreen extends StatefulWidget {
  const AdminSignInScreen({super.key});

  @override
  AdminSignInScreenState createState() => AdminSignInScreenState();
}

class AdminSignInScreenState extends State<AdminSignInScreen> {
  final _phoneController = TextEditingController();
  final role = UserRole.admin;

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
      appBar: CustomAppBar(
        title: "Admin Sign In",
        showBackButton: true,
        onBackPress: () {
          authViewModel.clearError();
          Navigator.maybePop(context);
        },
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Sign in with phone number",
                style: AppTextStyles.titleLarge,
              ),
              const SizedBox(height: 5),

              const Text(
                "A verification code will be sent to your registered phone number",
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
                  style: const TextStyle(color: Colors.red, fontSize: 14),
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
            ],
          ),
        ),
      ),
    );
  }
}
