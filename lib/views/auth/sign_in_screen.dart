import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:ezcharge/core/constants/colors.dart';
import 'package:ezcharge/core/constants/text_styles.dart';
import 'package:ezcharge/core/widgets/button.dart';
import 'package:ezcharge/core/widgets/custom_divider.dart';
import 'package:ezcharge/core/widgets/phone_input.dart';
import 'package:ezcharge/core/widgets/top_app_bar.dart';
import 'package:ezcharge/models/user_model.dart';
import 'package:ezcharge/viewmodels/auth/auth_viewmodel.dart';
import 'package:ezcharge/views/auth/admin_sign_in_screen.dart';
import 'package:ezcharge/views/auth/otp_screen.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  SignInScreenState createState() => SignInScreenState();
}

class SignInScreenState extends State<SignInScreen> {
  String _fullPhoneNumber = "";
  final TextEditingController _phoneController = TextEditingController();

  AuthViewModel get _authViewModel => context.read<AuthViewModel>();

  /// Send OTP and navigate to OTPScreen
  Future<void> _sendOTP() async {
    if (_fullPhoneNumber.isEmpty) return;

    await _authViewModel.sendOtp(
      _fullPhoneNumber,
      UserRole.customer,
      onCodeSent: (verificationId) {
        if (!mounted) return;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => OTPScreen(
              phoneNumber: _fullPhoneNumber,
              verificationID: verificationId,
              role: UserRole.customer,
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final authViewModel = context.watch<AuthViewModel>();

    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: CustomAppBar(
        title: "Sign In",
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
                  _fullPhoneNumber = number.phoneNumber ?? "";
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
                onPressed: _sendOTP,
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
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AdminSignInScreen(),
                      ),
                    );
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
