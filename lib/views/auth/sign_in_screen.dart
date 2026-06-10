import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/text_styles.dart';
import '../../core/routes/app_routes.dart';
import '../../core/widgets/custom_divider.dart';
import '../../core/widgets/top_app_bar.dart';
import '../../models/user_model.dart';
import '../../viewmodels/auth/auth_viewmodel.dart';
import 'otp_screen.dart';
import 'widgets/phone_sign_in_form.dart';

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
      appBar: CustomAppBar(title: "Sign In", showBackButton: false),
      body: SafeArea(
        child: PhoneSignInForm(
          title: "Sign in or create account with your phone number",
          subtitle: "A verification code will be sent to this phone number",
          phoneController: _phoneController,
          authViewModel: authViewModel,
          onSubmit: () => _submitPhoneNumber(authViewModel),
          footer: Column(
            children: [
              LabeledDivider(label: "Or"),
              const SizedBox(height: 16),
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
