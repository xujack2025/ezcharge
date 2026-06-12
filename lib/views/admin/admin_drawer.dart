import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/colors.dart';
import '../../core/routes/app_routes.dart';
import '../../viewmodels/auth/auth_viewmodel.dart';
import 'reports/admin_report.dart';
import 'admin_authenticate.dart';
import 'admin_emergency_requests.dart';
import 'admin_notification.dart';
import 'admin_rewards.dart';

class AdminDrawer extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemTapped;

  const AdminDrawer({
    super.key,
    required this.selectedIndex,
    required this.onItemTapped,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(color: Colors.blue),
            child: Text(
              "Admin Panel",
              style: TextStyle(color: Colors.white, fontSize: 22),
            ),
          ),
          _drawerItem(context, Icons.dashboard, "Dashboard", 0),
          _drawerItem(context, Icons.bar_chart, "Analytics", 1),
          _drawerItem(context, Icons.report, "Complaints", 2),
          _drawerItem(context, Icons.ev_station, "Charging Stations", 3),
          _drawerItem(context, Icons.person, "Profile", 4),

          const Divider(),

          /// Manage Notifications
          ListTile(
            leading: const Icon(Icons.notifications),
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Manage Notifications"),
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('Notifications')
                      .where('isRead', isEqualTo: false)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return const SizedBox(); // No unread notifications
                    }
                    return Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        snapshot.data!.docs.length.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AdminNotificationPage(),
                ),
              );
            },
          ),

          /// 🔹 Add Authenticate Customers Option
          ListTile(
            leading: const Icon(Icons.verified_user, color: Colors.blue),
            title: const Text(
              "Authenticate Customers",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AdminAuthenticatePage(),
                ),
              );
            },
          ),

          /// Rewards Page
          ListTile(
            leading: const Icon(
              Icons.local_offer,
              color: AppColors.primaryLight,
            ),
            title: const Text(
              "Rewards",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AdminRewardsScreen(),
                ),
              );
            },
          ),

          /// Emergency Request Assign Page
          ListTile(
            leading: const Icon(Icons.warning, color: AppColors.danger),
            title: const Text(
              "Assign Drivers",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AdminEmergencyRequestsPage(),
                ),
              );
            },
          ),

          /// Print Report Screen
          ListTile(
            leading: const Icon(Icons.print, color: Colors.blue),
            title: const Text(
              "Print Report",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const PrintReportScreen(),
                ),
              );
            },
          ),

          /// Logout Button
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text("Logout", style: TextStyle(color: Colors.red)),
            onTap: () => _showLogoutDialog(context),
          ),
        ],
      ),
    );
  }

  // 🔹 Drawer Item Builder
  Widget _drawerItem(
    BuildContext context,
    IconData icon,
    String title,
    int index,
  ) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      selected: selectedIndex == index,
      onTap: () {
        onItemTapped(index);
        if (Navigator.canPop(context)) {
          Navigator.pop(context); // Close drawer if open
        }
      },
    );
  }

  // 🔹 Logout Confirmation Dialog
  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Logout"),
        content: const Text("Are you sure you want to log out?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () async {
              await context.read<AuthViewModel>().signOut();
              if (!context.mounted) return;
              Navigator.pop(context);
              Navigator.pushNamedAndRemoveUntil(
                context,
                AppRoutes.signInScreen,
                (route) => false,
              );
            },
            child: const Text("Logout", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
