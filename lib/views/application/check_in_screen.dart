import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';

import '../../core/constants/colors.dart';
import '../../core/constants/text_styles.dart';
import '../../core/utils/app_logger.dart';
import '../../viewmodels/application/application_viewmodel.dart';
import '../../viewmodels/application/check_in_viewmodel.dart';
import 'customer/charging/charging_check_in_detail_screen.dart';
import 'widgets/home_top_nav_bar.dart';

class CheckInScreen extends StatefulWidget {
  const CheckInScreen({super.key});

  @override
  CheckInScreenState createState() => CheckInScreenState();
}

class CheckInScreenState extends State<CheckInScreen> {
  final MobileScannerController _scannerController = MobileScannerController();
  File? _selectedImage; // Store the picked image

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CheckInViewModel>().loadReservationStatus();
    });
  }

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  //Detect QR Code from the Camera Scanner
  void _onDetect(BarcodeCapture? capture) {
    if (capture != null && capture.barcodes.isNotEmpty) {
      final String scannedData = capture.barcodes.first.rawValue ?? "";
      _showScannedData(scannedData);
    }
  }

  //Pick Image from Gallery and Scan for QR Code
  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(
      source: ImageSource.gallery,
    );
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });

      //Scan the selected image for QR Code
      _scannerController
          .analyzeImage(_selectedImage!.path)
          .then((capture) {
            if (capture != null && capture.barcodes.isNotEmpty) {
              final String scannedData = capture.barcodes.first.rawValue ?? "";
              _showScannedData(scannedData);
            }
          })
          .catchError((error) {
            AppLogger.error("Error scanning image: $error");
          });
    }
  }

  ///Show Scanned QR Code Data in a Dialog
  void _showScannedData(String data) {
    switch (context.read<CheckInViewModel>().resolveScan(data)) {
      case CheckInScanResult.upcoming:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const ChargingCheckInDetailScreen(),
          ),
        );
        return;
      case CheckInScanResult.active:
        _showErrorDialog("You are charging your EV now");
        return;
      case CheckInScanResult.unavailable:
        _showErrorDialog("Can't find your reservation");
        return;
      case CheckInScanResult.empty:
        return;
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Error"),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        elevation: 0,
        backgroundColor: AppColors.black,
        title: Text(
          "EZCHARGE",
          style: AppTextStyles.headlineMedium.copyWith(
            color: AppColors.white,
            letterSpacing: 2,
          ),
        ),
      ),
      body: Stack(
        children: [
          // Mobile Scanner for QR Code
          MobileScanner(controller: _scannerController, onDetect: _onDetect),

          //Top Navigation Buttons
          Container(width: double.infinity, height: 30, color: AppColors.black),
          Positioned(
            top: 0,
            left: 20,
            right: 20,
            child: HomeTopNavBar(
              selectedSection: ApplicationHomeSection.checkIn,
              onCheckInPressed: () {
                context.read<ApplicationViewmodel>().showCheckInSection();
              },
              onHomePressed: () {
                context.read<ApplicationViewmodel>().showHomeSection();
              },
              onBookAChargePressed: () {
                context.read<ApplicationViewmodel>().showBookAChargeSection();
              },
            ),
          ),

          //QR Code Frame Overlay
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 2),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),

          //Instruction Text
          const Positioned(
            bottom: 180,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                "Position the QR code within the frame",
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
          ),

          //Display Selected Image (If available)
          if (_selectedImage != null)
            Positioned(
              bottom: 250,
              left: 20,
              right: 20,
              child: Image.file(
                _selectedImage!,
                height: 200,
                fit: BoxFit.cover,
              ),
            ),

          //Upload Button
          Positioned(
            bottom: 100,
            left: 20,
            right: 20,
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _pickImage,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                ),
                icon: const Icon(Icons.image, color: Colors.white),
                label: const Text(
                  "Choose from Gallery",
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
