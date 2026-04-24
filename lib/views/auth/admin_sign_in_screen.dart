import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:ezcharge/core/constants/text_styles.dart';
import 'package:ezcharge/core/widgets/button.dart';
import 'package:ezcharge/core/widgets/phone_input.dart';
import 'package:ezcharge/core/widgets/top_app_bar.dart';
import 'package:ezcharge/models/user_model.dart';
import 'package:ezcharge/viewmodels/auth/auth_viewmodel.dart';
import 'package:ezcharge/views/auth/otp_screen.dart';

class AdminSignInScreen extends StatefulWidget {
  const AdminSignInScreen({super.key});

  @override
  AdminSignInScreenState createState() => AdminSignInScreenState();
}

class AdminSignInScreenState extends State<AdminSignInScreen> {
  String _fullPhoneNumber = "";
  final TextEditingController _phoneController = TextEditingController();

  AuthViewmodel get _authViewModel => context.read<AuthViewmodel>();

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

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
    final authViewModel = context.watch<AuthViewmodel>();

    return Scaffold(
      backgroundColor: Colors.grey[200], //Light Grey Background
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
                  _fullPhoneNumber = number.phoneNumber ?? "";
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
                onPressed: _sendOTP,
                borderRadius: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
