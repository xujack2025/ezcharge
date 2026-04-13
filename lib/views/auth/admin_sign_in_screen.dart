import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:ezcharge/core/utils/app_logger.dart';
import 'package:ezcharge/views/auth/otp_admin_screen.dart';
import 'package:ezcharge/viewmodels/auth/auth_viewmodel.dart';

class AdminSignInScreen extends StatefulWidget {
  const AdminSignInScreen({super.key});

  @override
  AdminSignInScreenState createState() => AdminSignInScreenState();
}

class AdminSignInScreenState extends State<AdminSignInScreen> {
  final TextEditingController _phoneController = TextEditingController();

  AuthViewmodel get _authViewModel => context.read<AuthViewmodel>();

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  //Send OTP if phone number exists
  void _sendOTP() async {
    String phoneNumber = _phoneController.text.trim();
    _authViewModel.sendAdminOtp(
      phoneNumber,
      onCodeSent: (verificationId) {
        final admin = _authViewModel.admin;
        if (admin != null) {
          // 用 info，蓝色或带 ℹ️ 图标，表示重要的流程节点
          AppLogger.info(
            "Admin verified: ${admin.firstName} ${admin.lastName}",
          );
        }

        // 用 debug，通常是灰/白色，开发完可以随时在 AppLogger 里关掉
        AppLogger.debug("VERIFICATION ID: $verificationId");

        if (!mounted) return;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => OTPAdminScreen(
              phoneNumber: phoneNumber,
              verificationID: verificationId,
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
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // White Header (Back Button + Title)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            color: Colors.white,
            child: Row(
              children: [
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
                const Text(
                  "Admin Sign In",
                  style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Sign in with your admin phone number",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 5),
                const Text(
                  "A verification code will be sent to your registered phone number",
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 20),

                // 🔹 Phone Number Input with Error Message
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        hintText: "Enter phone number",
                        prefixIcon: const Icon(Icons.phone),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    if (authViewModel.errorMessage != null) ...[
                      const SizedBox(height: 5),
                      Text(
                        authViewModel.errorMessage!,
                        style: const TextStyle(color: Colors.red, fontSize: 14),
                      ),
                    ],
                  ],
                ),

                const SizedBox(height: 40),

                //Submit Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: authViewModel.isLoading ? null : _sendOTP,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                    child: authViewModel.isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            "SUBMIT",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
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
