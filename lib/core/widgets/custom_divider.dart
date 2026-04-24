import 'package:flutter/material.dart';

import 'package:ezcharge/core/constants/colors.dart';
import 'package:ezcharge/core/constants/text_styles.dart';

class CustomDivider extends StatelessWidget {
  final double height; // 线占用的总空间高度
  final double thickness; // 线本身的粗细
  final Color? color; // 线的颜色
  final double indent; // 左边缩进
  final double endIndent; // 右边缩进

  const CustomDivider({
    super.key,
    this.height = 16.0,
    this.thickness = 1.0,
    this.color,
    this.indent = 0.0,
    this.endIndent = 0.0,
  });

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: height,
      thickness: thickness,
      // 如果没传颜色，默认用系统的主题颜色（通常是淡淡的灰色）
      color: AppColors.grey.withValues(alpha: 0.3),
      indent: indent,
      endIndent: endIndent,
    );
  }
}

class LabeledDivider extends StatelessWidget {
  final String label;
  final double thickness;
  final double indent;
  final Color? color;

  const LabeledDivider({
    super.key,
    required this.label,
    this.thickness = 1.0,
    this.indent = 10.0,
    this.color = AppColors.grey,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Container(
            margin: EdgeInsets.only(right: indent),
            height: thickness,
            color: color,
          ),
        ),

        Text(label, style: AppTextStyles.bodyMedium.copyWith(color: color)),

        Expanded(
          child: Container(
            margin: EdgeInsets.only(left: indent),
            height: thickness,
            color: color,
          ),
        ),
      ],
    );
  }
}
