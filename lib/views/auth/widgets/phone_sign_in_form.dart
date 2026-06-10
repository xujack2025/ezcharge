import 'package:flutter/material.dart';
import 'package:intl_phone_number_input/intl_phone_number_input.dart';

import '../../../core/constants/colors.dart';
import '../../../core/constants/text_styles.dart';
import '../../../core/widgets/button.dart';
import '../../../core/widgets/phone_input.dart';
import '../../../viewmodels/auth/auth_viewmodel.dart';

class PhoneSignInForm extends StatelessWidget {
  const PhoneSignInForm({
    super.key,
    required this.title,
    required this.subtitle,
    required this.phoneController,
    required this.authViewModel,
    required this.onSubmit,
    this.footer,
  });

  final String title;
  final String subtitle;
  final TextEditingController phoneController;
  final AuthViewModel authViewModel;
  final VoidCallback onSubmit;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTextStyles.titleLarge),
          const SizedBox(height: 5),
          Text(subtitle, style: AppTextStyles.labelLarge),
          const SizedBox(height: 16),
          AppPhoneInput(
            controller: phoneController,
            onInputChanged: (PhoneNumber number) {
              authViewModel.fullPhoneNumber = number.phoneNumber ?? "";
            },
          ),
          if (authViewModel.errorMessage != null) ...[
            const SizedBox(height: 5),
            Text(
              authViewModel.errorMessage!,
              style: AppTextStyles.labelLarge.copyWith(color: AppColors.danger),
            ),
          ],
          const SizedBox(height: 16),
          CustomButton(
            text: "Submit",
            isLoading: authViewModel.isLoading,
            onPressed: onSubmit,
            borderRadius: 22,
          ),
          if (footer != null) ...[const SizedBox(height: 16), footer!],
        ],
      ),
    );
  }
}
