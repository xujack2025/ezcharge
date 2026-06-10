import 'package:flutter/material.dart';

import '../../../viewmodels/application/application_viewmodel.dart';
import 'top_nav_icon.dart';

class HomeTopNavBar extends StatelessWidget {
  const HomeTopNavBar({
    super.key,
    required this.selectedSection,
    required this.onCheckInPressed,
    required this.onHomePressed,
    required this.onBookAChargePressed,
  });

  final ApplicationHomeSection selectedSection;
  final VoidCallback onCheckInPressed;
  final VoidCallback onHomePressed;
  final VoidCallback onBookAChargePressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: const [BoxShadow(blurRadius: 6, color: Colors.black12)],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          TopNavIcon(
            Icons.qr_code,
            isSelected: selectedSection == ApplicationHomeSection.checkIn,
            onTap: onCheckInPressed,
          ),
          TopNavIcon(
            Icons.electric_bolt,
            isSelected: selectedSection == ApplicationHomeSection.home,
            onTap: onHomePressed,
          ),
          TopNavIcon(
            Icons.local_gas_station,
            isSelected: selectedSection == ApplicationHomeSection.bookACharge,
            onTap: onBookAChargePressed,
          ),
        ],
      ),
    );
  }
}
