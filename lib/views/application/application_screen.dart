import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/colors.dart';
import '../../viewmodels/application/application_viewmodel.dart';
import 'customer/profile/profile_screen.dart';
import 'home_screen.dart';
import 'notification_screen.dart';
import 'reward_screen.dart';

class ApplicationScreen extends StatelessWidget {
  ApplicationScreen({super.key});
  final pages = [
    HomeScreen(),
    RewardScreen(),
    NotificationScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final appVM = context.watch<ApplicationViewmodel>();
    return Scaffold(
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: appVM.selectedPages,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.darkGrey,
        showUnselectedLabels: true,
        onTap: (value) {
          appVM.onItemTapped(value);
        },
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.directions_car),
            label: "EZCharge",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.card_giftcard),
            label: "Rewards",
          ),
          BottomNavigationBarItem(icon: Icon(Icons.mail), label: "Inbox"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Me"),
        ],
      ),
      body: Stack(children: [pages[appVM.selectedPages]]),
    );
  }
}
