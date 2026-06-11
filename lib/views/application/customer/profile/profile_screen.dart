import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/routes/app_routes.dart';
import '../../../../viewmodels/auth/auth_viewmodel.dart';
import 'account/activity_screen.dart';
import 'account/authenticate_account_screen.dart';
import 'account/bookmark_screen.dart';
import 'account/edit_profile_screen.dart';
import 'account/fail_screen.dart';
import 'account/pass_screen.dart';
import 'account/pending_screen.dart';
import 'others/delete_account_screen.dart';
import 'payment/payment_history_list.dart';
import 'payment/payment_method_screen.dart';
import 'payment/top_up_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  ProfileScreenState createState() => ProfileScreenState();
}

class ProfileScreenState extends State<ProfileScreen> {
  String _customerName = "Loading...";
  String _accountId = "00000000";
  double _walletBalance = 0.0;
  int _pointBalance = 0;
  String _authStatus = "";

  @override
  void initState() {
    super.initState();
    _fetchCustomerData();
  }

  // Fetch current log in user id from Firestore
  Future<void> _fetchCustomerData() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        String userPhone = user.phoneNumber ?? "";
        if (userPhone.isEmpty) return;

        QuerySnapshot querySnapshot = await FirebaseFirestore.instance
            .collection("Customers")
            .where("PhoneNumber", isEqualTo: userPhone)
            .limit(1)
            .get();

        if (querySnapshot.docs.isNotEmpty) {
          var userDoc = querySnapshot.docs.first;

          setState(() {
            _customerName = "${userDoc["FirstName"]} ${userDoc["LastName"]}";
            _accountId = userDoc["CustomerID"];
            _walletBalance = userDoc["WalletBalance"].toDouble();
            _pointBalance = userDoc["PointBalance"];
          });
          _fetchAuthenticationStatus();
        }
      }
    } catch (e) {
      debugPrint("Error fetching customer data: $e");
    }
  }

  // Fetch current sign in user's Authentication Status from Firestore
  Future<void> _fetchAuthenticationStatus() async {
    if (_accountId.isEmpty) return;

    try {
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection("Customers")
          .doc(_accountId)
          .collection("Authenticate")
          .doc("authentication")
          .get();

      if (doc.exists) {
        setState(() {
          _authStatus = doc["Status"];
        });
      }
    } catch (e) {
      debugPrint("Error fetching authentication status: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        automaticallyImplyLeading: false,
        title: const Text(
          "Account",
          style: TextStyle(
            color: Colors.black,
            fontSize: 30,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // User Info Section
                  Container(
                    color: Colors.black,
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _customerName,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Account ID: $_accountId",
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.white,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.bolt,
                                    color: Colors.blue,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    "$_pointBalance pts",
                                    style: const TextStyle(
                                      color: Colors.blue,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Wallet Balance Section
                  Container(
                    margin: const EdgeInsets.all(16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.account_balance_wallet,
                              color: Colors.white,
                              size: 28,
                            ),
                            const SizedBox(width: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  "EZCharge Credits",
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.white,
                                  ),
                                ),
                                Text(
                                  "RM ${_walletBalance.toStringAsFixed(2)}",
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const TopUpScreen(),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                          ),
                          child: const Text(
                            "+ TOP UP",
                            style: TextStyle(color: Colors.blue, fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                  ),
                  //Selection button
                  _buildSection("My Account", [
                    _buildListItem(
                      "Edit Profile",
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const EditProfileScreen(),
                          ),
                        );
                      },
                    ),
                    _buildListItem(
                      "Charging",
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ActivityScreen(),
                          ),
                        );
                      },
                    ),
                    _buildListItem(
                      "Authenticate Account",
                      onTap: () {
                        if (_authStatus == "Pending") {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const PendingScreen(),
                            ),
                          );
                        } else if (_authStatus == "Pass") {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const PassScreen(),
                            ),
                          );
                        } else if (_authStatus == "Fail") {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const FailScreen(),
                            ),
                          );
                        } else {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const AuthenticateAccountScreen(),
                            ),
                          );
                        }
                      },
                    ),
                    _buildListItem(
                      "Bookmarks",
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const BookmarkScreen(),
                          ),
                        );
                      },
                    ),
                  ]),
                  _buildSection("Payments", [
                    _buildListItem(
                      "Payment Methods",
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const PaymentMethodScreen(),
                          ),
                        );
                      },
                    ),
                    _buildListItem(
                      "Payment History",
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const PaymentHistoryListScreen(),
                          ),
                        );
                      },
                    ),
                  ]),
                  _buildSection("Others", [
                    _buildListItem("F.A.Q"),
                    _buildListItem("Contact Us"),
                    _buildListItem("Terms of Use"),
                    _buildListItem("Privacy Policy"),
                    _buildListItem(
                      "Delete Account",
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const DeleteAccountScreen(),
                          ),
                        );
                      },
                    ),
                  ]),

                  _buildCenteredListItem(context, "Log Out", Icons.logout),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // UI Components
  Widget _buildSection(String title, List<Widget> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          color: Colors.grey[300],
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
        ),
        Column(children: items),
      ],
    );
  }

  Widget _buildListItem(String title, {VoidCallback? onTap}) {
    return ListTile(
      title: Text(title),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }

  Widget _buildCenteredListItem(
    BuildContext context,
    String title,
    IconData icon,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: Colors.grey[300],
      child: Center(
        child: InkWell(
          onTap: () => _logoutUser(context),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.black),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _logoutUser(BuildContext context) async {
    await context.read<AuthViewModel>().signOut();
    if (!context.mounted) return;
    Navigator.pushNamedAndRemoveUntil(
      context,
      AppRoutes.signInScreen,
      (route) => false,
    );
  }
}
