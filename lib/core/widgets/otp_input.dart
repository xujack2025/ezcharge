import 'package:flutter/material.dart';
import 'package:pinput/pinput.dart';

class CustomOtpInput extends StatelessWidget {
  final TextEditingController controller;
  final Function(String)? onCompleted;
  final int length;

  const CustomOtpInput({
    super.key,
    required this.controller,
    this.onCompleted,
    this.length = 6,
  });

  @override
  Widget build(BuildContext context) {
    final defaultPinTheme = PinTheme(
      width: 45,
      height: 50,
      textStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(8),
      ),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Pinput(
        length: length,
        controller: controller,
        defaultPinTheme: defaultPinTheme,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        onCompleted: onCompleted,
      ),
    );
  }
}
