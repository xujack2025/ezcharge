import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/colors.dart';
import '../../viewmodels/application/application_viewmodel.dart';
import 'book_a_charge_screen.dart';
import 'check_in_screen.dart';
import 'customer/profile/profile_screen.dart';
import 'home_screen.dart';
import 'notification_screen.dart';
import 'reward_screen.dart';

class ApplicationScreen extends StatelessWidget {
  const ApplicationScreen({super.key});

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
      body: IndexedStack(
        index: appVM.selectedPages,
        children: [
          _buildHomeBody(appVM),
          const RewardScreen(),
          const NotificationScreen(),
          const ProfileScreen(),
        ],
      ),
    );
  }

  Widget _buildHomeBody(ApplicationViewmodel appVM) {
    switch (appVM.homeSection) {
      case ApplicationHomeSection.checkIn:
        return const CheckInScreen();
      case ApplicationHomeSection.bookACharge:
        return const BookAChargeScreen(showBottomNav: false);
      case ApplicationHomeSection.home:
        return const HomeScreen();
    }
  }
}
