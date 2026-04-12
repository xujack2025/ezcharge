import 'dart:developer';

import 'package:flutter/material.dart';

//file
import 'package:ezcharge/views/customer/rating/customer_complaint.dart';
import 'package:ezcharge/views/customer/rating/customer_review.dart';

//firebase
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../constants/colors.dart';
import '../../../constants/text_styles.dart';

class RatingPage extends StatefulWidget {
  final String stationId; // Accept station ID

  const RatingPage({super.key, required this.stationId});

  @override
  State<RatingPage> createState() => _RatingPageState();
}

class _RatingPageState extends State<RatingPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String? _customerID; // Holds retrieved CustomerID

  @override
  void initState() {
    super.initState();
    _retrieveCustomerID(); // Fetch CustomerID on page load
  }

  // ✅ Function to retrieve the current CustomerID
  Future<void> _retrieveCustomerID() async {
    final User? user = FirebaseAuth.instance.currentUser;

    if (user == null || user.phoneNumber == null) {
      log("❌ User not logged in or phone number missing.");
      return;
    }

    try {
      var customerQuery = await _firestore
          .collection("customers")
          .where(
            "PhoneNumber",
            isEqualTo: user.phoneNumber,
          ) // 🔹 Using phone number
          .limit(1)
          .get();

      if (customerQuery.docs.isEmpty) {
        log(
          "❌ Error: Customer ID not found for phone number ${user.phoneNumber}",
        );
        return;
      }

      setState(() {
        _customerID = customerQuery.docs.first["CustomerID"];
      });

      log("✅ Retrieved CustomerID: $_customerID");
    } catch (e) {
      log("❌ Error retrieving CustomerID: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Rate & Report"),
        actions: [
          // Three-dot button to open the modal
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {
              _showReviewReportModal(context);
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "Tap the three-dot button to rate or report.",
              style: AppTextStyles.subheading,
            ),
            const SizedBox(height: 20),
            _customerID != null
                ? Text("Customer ID: $_customerID", style: AppTextStyles.body)
                : const CircularProgressIndicator(), // Show loader until ID is retrieved
          ],
        ),
      ),
    );
  }

  // 🔹 Function to Show Modal Bottom Sheet
  void _showReviewReportModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Ensures modal adapts to content
      backgroundColor: Colors.transparent, // Makes background match UI
      builder: (context) {
        return Container(
          width: double.infinity,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
          ),
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 🔹 **灰色滑动条**
              Container(
                width: 50, // 宽度
                height: 5, // 高度
                decoration: BoxDecoration(
                  color: Colors.grey[400], // 灰色
                  borderRadius: BorderRadius.circular(10), // 圆角
                ),
              ),

              const SizedBox(height: 20), // 间距
              // ⭐ Review Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(
                    Icons.chat_bubble_outline,
                    color: Colors.white,
                  ),
                  label: const Text(
                    "Review",
                    style: TextStyle(fontSize: 18, color: Colors.white),
                  ),
                  onPressed: () {
                    Navigator.pop(context); // Close modal
                    // Navigator.push(
                    //   context,
                    //   MaterialPageRoute(builder: (context) => ReviewPage(stationId: widget.stationId)),
                    // );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 10), // Spacing between buttons
              // ⚠️ Report Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.report, color: Colors.white),
                  label: const Text(
                    "Report",
                    style: TextStyle(fontSize: 18, color: Colors.white),
                  ),
                  onPressed: () {
                    Navigator.pop(context); // Close modal
                    /*Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const CustomerComplaintPage()),
                    );*/
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
