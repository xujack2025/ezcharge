import 'package:flutter/material.dart';

class TopNavIcon extends StatelessWidget {
  const TopNavIcon(
    this.icon, {
    super.key,
    required this.isSelected,
    this.onTap,
  });

  final IconData icon;
  final bool isSelected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue : Colors.white,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          color: isSelected ? Colors.white : Colors.black,
          size: 30,
        ),
      ),
    );
  }
}
