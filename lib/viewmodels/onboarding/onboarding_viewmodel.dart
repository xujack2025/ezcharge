import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../../core/routes/app_routes.dart';

class OnboardingViewmodel extends ChangeNotifier {
  final _pageController = PageController();
  int _currentIndex = 0;
  final _totalPages = 3;
  bool _isChecked = false;

  PageController get pageController => _pageController;
  int get currentIndex => _currentIndex;
  int get totalPages => _totalPages;
  bool get isChecked => _isChecked;

  set isChecked(bool? value) {
    if (_isChecked != value) {
      _isChecked = value ?? false;
      notifyListeners();
    }
  }

  /// Location Permission
  Future<void> requestLocationPermission(BuildContext context) async {
    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return;
      }
    }

    if (!context.mounted) return;
    if (permission == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Location access permanently denied. Enable it in settings.",
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
  }

  /// Change Index for Page Controller
  void setCurrentIndex(int index) {
    _currentIndex = index;
    notifyListeners();
  }

  ///
  void nextPage(BuildContext context) {
    if (_currentIndex < _totalPages - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.welcomeScreen,
        (route) => false,
      );
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
}
