import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/widgets/top_app_bar.dart';
import '../../models/user_model.dart';
import '../../viewmodels/auth/auth_viewmodel.dart';
import 'otp_screen.dart';
import 'widgets/phone_sign_in_form.dart';

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

  Future<void> _submitPhoneNumber(AuthViewModel authViewModel) async {
    final phoneNumber = authViewModel.fullPhoneNumber;
    final verificationId = await authViewModel.submitPhoneNumber(
      phoneNumber,
      role,
    );

    if (!mounted || verificationId == null) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OTPScreen(
          phoneNumber: phoneNumber,
          verificationID: verificationId,
          role: role,
        ),
      ),
    );
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
        child: PhoneSignInForm(
          title: "Sign in with phone number",
          subtitle:
              "A verification code will be sent to your registered phone number",
          phoneController: _phoneController,
          authViewModel: authViewModel,
          onSubmit: () => _submitPhoneNumber(authViewModel),
        ),
      ),
    );
  }
}
