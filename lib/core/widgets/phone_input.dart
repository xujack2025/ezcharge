import 'package:flutter/material.dart';
import 'package:intl_phone_number_input/intl_phone_number_input.dart';

import 'package:ezcharge/core/constants/colors.dart';

class AppPhoneInput extends StatelessWidget {
  final TextEditingController controller;
  final Function(PhoneNumber) onInputChanged;
  final String? initialCountryCode;
  final String? hintText;
  final bool autofocus;

  const AppPhoneInput({
    super.key,
    required this.controller,
    required this.onInputChanged,
    this.initialCountryCode = 'MY',
    this.hintText = '123456789',
    this.autofocus = false,
  });

  @override
  Widget build(BuildContext context) {
    return InternationalPhoneNumberInput(
      onInputChanged: onInputChanged,
      textFieldController: controller,
      initialValue: PhoneNumber(isoCode: initialCountryCode),
      cursorColor: AppColors.black,
      formatInput: true,
      autoFocus: autofocus,
      selectorConfig: const SelectorConfig(
        selectorType: PhoneInputSelectorType.BOTTOM_SHEET,
        showFlags: true,
        setSelectorButtonAsPrefixIcon: true,
        leadingPadding: 16,
      ),
      inputDecoration: InputDecoration(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        hintText: hintText,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.grey, width: 2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
      ),
    );
  }
}
