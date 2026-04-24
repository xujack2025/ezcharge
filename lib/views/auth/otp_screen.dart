import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:ezcharge/core/constants/colors.dart';
import 'package:ezcharge/core/constants/text_styles.dart';
import 'package:ezcharge/core/widgets/otp_input.dart';
import 'package:ezcharge/core/widgets/top_app_bar.dart';
import 'package:ezcharge/models/user_model.dart';
import 'package:ezcharge/viewmodels/auth/auth_viewmodel.dart';
import 'package:ezcharge/views/admin/admin_dashboard.dart';
import 'package:ezcharge/views/ezcharge/home_screen.dart';

class OTPScreen extends StatefulWidget {
  final String phoneNumber;
  final String verificationID;
  final UserRole role;

  const OTPScreen({
    super.key,
    required this.phoneNumber,
    required this.verificationID,
    required this.role,
  });

  @override
  OTPScreenState createState() => OTPScreenState();
}

class OTPScreenState extends State<OTPScreen> {
  final TextEditingController _otpController = TextEditingController();
  AuthViewmodel get _authViewModel => context.read<AuthViewmodel>();

  //Verify OTP
  Future<void> onVerifyPressed() async {
    _authViewModel.clearError();
    final success = await _authViewModel.verifyOtp(
      widget.verificationID,
      _otpController.text.trim(),
      widget.phoneNumber,
      widget.role,
    );

    if (success && mounted) {
      Widget destination = (widget.role == UserRole.admin)
          ? const AdminDashboard()
          : const HomeScreen();

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => destination),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authViewModel = context.watch<AuthViewmodel>();

    return Scaffold(
      backgroundColor: AppColors.backgroundGrey,
      appBar: CustomAppBar(
        title: "Verification",
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
              /// OTP Prompt Text
              Text(
                "Enter the 6-digit code sent to ${widget.phoneNumber}",
                style: AppTextStyles.titleLarge,
              ),
              SizedBox(height: 16),

              /// OTP Input Field
              CustomOtpInput(
                controller: _otpController,
                onCompleted: (pin) {
                  onVerifyPressed();
                },
              ),
              if (authViewModel.errorMessage != null)
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    authViewModel.errorMessage!,
                    style: const TextStyle(color: Colors.red, fontSize: 14),
                  ),
                ),
              SizedBox(height: 16),

              // Resend Code Section
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Didn't receive it?",
                    style: TextStyle(color: Colors.black54),
                  ),
                  TextButton(
                    onPressed: () {}, // TODO: Implement Resend OTP
                    child: const Text(
                      "Get new code",
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
