import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../service/chatbot_screen.dart';
import 'start_charging.dart';

class CheckDetailScreen extends StatefulWidget {
  const CheckDetailScreen({super.key});

  @override
  CheckDetailScreenState createState() => CheckDetailScreenState();
}

class CheckDetailScreenState extends State<CheckDetailScreen> {
  String _accountId = "";
  String _chargerId = "";
  String _stationId = "";
  String _reservationStatus = "";
  String _stationName = "";
  String _chargerName = "";
  String _chargerType = "";
  String _pricepervoltage = " ";
  Timestamp _startTime = Timestamp.now();
  bool isLoading = false;
  bool isChecked = false;

  @override
  void initState() {
    super.initState();
    _getCustomerID();
  }

  //Get the Logged-in User's Customer ID
  Future<void> _getCustomerID() async {
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
            _accountId = userDoc["CustomerID"];
          });

          //Fetch Reservation after getting CustomerID
          _fetchReservationRecord();
        }
      }
    } catch (e) {
      debugPrint("Error fetching customer data: $e");
    }
  }

  //Fetch the Latest Reservation for the User
  Future<void> _fetchReservationRecord() async {
    if (_accountId.isEmpty) return; // Ensure _accountId is available

    try {
      //Fetch reservation document for the user
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection("Reservation")
          .doc(_accountId)
          .get();

      if (doc.exists) {
        setState(() {
          _chargerId = doc["ChargerID"];
          _stationId = doc["StationID"];
          _reservationStatus = doc["Status"];
          _startTime = doc["StartTime"];
        });
        if (_reservationStatus == "Upcoming") {
          await _fetchStation();
          await _fetchCharger();
        }
      }
    } catch (e) {
      debugPrint("Error fetching reservation record: $e");
    }
  }

  Future<void> _fetchStation() async {
    if (_stationId.isEmpty) return;

    try {
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection("Station")
          .doc(_stationId)
          .get();

      if (doc.exists) {
        setState(() {
          _stationName = doc["StationName"];
        });
      }
    } catch (e) {
      debugPrint("Error fetching station: $e");
    }
  }

  Future<void> _fetchCharger() async {
    if (_stationId.isEmpty || _chargerId.isEmpty) return;

    try {
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection("Station")
          .doc(_stationId)
          .collection("Charger")
          .doc(_chargerId)
          .get();

      if (doc.exists) {
        setState(() {
          _chargerName = doc["ChargerName"];
          _chargerType = doc["ChargerType"];
          _pricepervoltage = doc["PricePerVoltage"].toString();
        });
      }
    } catch (e) {
      debugPrint("Error fetching charger: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  //Back Button & Title
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Left side: back button + "Check In"
                      Row(
                        children: [
                          IconButton(
                            icon: Container(
                              decoration: const BoxDecoration(
                                color: Colors.blue,
                                shape: BoxShape.circle,
                              ),
                              padding: const EdgeInsets.all(8),
                              child: const Icon(
                                Icons.arrow_back,
                                color: Colors.white,
                              ),
                            ),
                            onPressed: () => Navigator.pop(context),
                          ),
                          const SizedBox(width: 5),
                          const Text(
                            "Check In",
                            style: TextStyle(
                              fontSize: 25,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                        ],
                      ),
                      // Right side: "Help"
                      Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const ChatbotScreen(),
                              ),
                            );
                          },
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.support_agent,
                                color: Colors.blue,
                                size: 30,
                              ),
                              SizedBox(width: 8),
                              Text(
                                "Help",
                                style: TextStyle(
                                  color: Colors.blue,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  //Image
                  Center(
                    child: Image.asset(
                      'assets/images/charging.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(height: 20),
                  //Reservation Details
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 5),
                    child: Row(
                      children: [
                        const Text(
                          "Charging Station: ",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Expanded(
                          child: Text(
                            _stationName,
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 5),
                    child: Row(
                      children: [
                        const Text(
                          "Charging Slot: ",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Expanded(
                          child: Text(
                            _chargerName,
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 5),
                    child: Row(
                      children: [
                        const Text(
                          "Charger Type: ",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Expanded(
                          child: Text(
                            _chargerType,
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 5),
                    child: Row(
                      children: [
                        const Text(
                          "Price per KWH: ",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Expanded(
                          child: Text(
                            "RM$_pricepervoltage",
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 5),
                    child: Row(
                      children: [
                        const Text(
                          "Reserved Time: ",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Expanded(
                          child: Text(
                            // Convert the Timestamp to a DateTime, then format it
                            DateFormat(
                              'yyyy-MM-dd HH:mm',
                            ).format(_startTime.toDate()),
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),
                  //Terms & Conditions Checkbox
                  Row(
                    children: [
                      Checkbox(
                        value: isChecked,
                        onChanged: (value) {
                          setState(() {
                            isChecked = value!;
                          });
                        },
                      ),
                      const Expanded(
                        child: Text(
                          "I have checked the details and request for charging",
                          style: TextStyle(fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  //Check-In Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed:
                          (isChecked &&
                              DateTime.now().isAfter(_startTime.toDate()))
                          ? _checkIn
                          : () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    "Now isn't your check-in time!",
                                  ),
                                ),
                              );
                            }, // Disable button
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            (isChecked &&
                                DateTime.now().isAfter(_startTime.toDate()))
                            ? Colors.blue
                            : Colors.grey,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                      ),
                      child: const Text(
                        "CHECK IN",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  //Handle Check-In Action
  Future<void> _checkIn() async {
    try {
      //Update reservation status to "Active" (or any status you want).
      await FirebaseFirestore.instance
          .collection("Reservation")
          .doc(_accountId)
          .update({"Status": "Active"});

      await FirebaseFirestore.instance
          .collection("Station")
          .doc(_stationId)
          .collection("Charger")
          .doc(_chargerId)
          .update({"Status": "Occupied"});

      // Show a success message (optional).
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Check-in successful!")));

      // Navigate to StartChargingScreen.
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const StartChargingScreen()),
      );
    } catch (e) {
      debugPrint("Error during check-in: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Check-in failed. Try again!")),
      );
    }
  }
}
