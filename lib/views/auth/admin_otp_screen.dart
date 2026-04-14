import 'package:ezcharge/viewmodels/auth/auth_viewmodel.dart';
import 'package:flutter/material.dart';

import 'package:ezcharge/views/admin/admin_dashboard.dart';
import 'package:provider/provider.dart';

class AdminOtpScreen extends StatefulWidget {
  final String phoneNumber;
  final String verificationID;

  const AdminOtpScreen({
    super.key,
    required this.phoneNumber,
    required this.verificationID,
  });

  @override
  AdminOtpScreenState createState() => AdminOtpScreenState();
}

class AdminOtpScreenState extends State<AdminOtpScreen> {
  final TextEditingController _otpController = TextEditingController();
  AuthViewmodel get _authViewModel => context.read<AuthViewmodel>();

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  Future<void> onVerifyPressed() async {
    _authViewModel.clearError();
    final success = await _authViewModel.verifyAdminOtp(
      widget.verificationID,
      _otpController.text.trim(),
      widget.phoneNumber,
    );

    if (success && mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const AdminDashboard()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authViewModel = context.watch<AuthViewmodel>();

    return Scaffold(
      backgroundColor: Colors.grey[200], //Light Grey Background
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            color: Colors.white,
            child: Row(
              children: [
                // Back Button (Blue Circle)
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: const BoxDecoration(
                      color: Colors.blue,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.arrow_back, color: Colors.white),
                  ),
                ),
                const SizedBox(width: 10),
                // Title
                const Text(
                  "Verification",
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),

          const SizedBox(height: 30),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              "Enter the 6-digit code sent to ${widget.phoneNumber}",
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),

          const SizedBox(height: 20),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _otpController,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  decoration: InputDecoration(
                    hintText: "Verification Code",
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    counterText: "",
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          if (authViewModel.errorMessage != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                authViewModel.errorMessage!,
                style: const TextStyle(color: Colors.red, fontSize: 14),
              ),
            ),
          // Submit Button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                // 这里改用 authViewModel.isLoading 控制
                onPressed: authViewModel.isLoading ? null : onVerifyPressed,
                style: ElevatedButton.styleFrom(
                  backgroundColor: authViewModel.isLoading
                      ? Colors.grey
                      : Colors.blue,
                  padding: const EdgeInsets.all(16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
                child: authViewModel.isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        "SUBMIT",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ),

          const SizedBox(height: 20),

          //Resend Code Section
          const Center(
            child: Text(
              "Didn't receive it?",
              style: TextStyle(color: Colors.black54),
            ),
          ),
          Center(
            child: TextButton(
              onPressed: () {}, // TODO: Implement Resend OTP
              child: const Text(
                "Get new code",
                style: TextStyle(
                  color: Colors.blue,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
