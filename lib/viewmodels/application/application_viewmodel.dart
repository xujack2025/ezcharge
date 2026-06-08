import 'package:flutter/material.dart';

enum ApplicationHomeSection { home, checkIn, bookACharge }

class ApplicationViewmodel extends ChangeNotifier {
  int _selectedPages = 0;
  int _selectedTab = 1;
  ApplicationHomeSection _homeSection = ApplicationHomeSection.home;

  int get selectedPages => _selectedPages;
  int get selectedTab => _selectedTab;
  ApplicationHomeSection get homeSection => _homeSection;

  void onItemTapped(int index) {
    if (_selectedPages != index) {
      _selectedPages = index;
      if (index == 0) {
        _homeSection = ApplicationHomeSection.home;
      }
      notifyListeners();
    }
  }

  void onTabTapped(int index) {
    if (_selectedTab != index) {
      _selectedTab = index;
      notifyListeners();
    }
  }

  void showHomeSection() {
    if (_homeSection == ApplicationHomeSection.home) {
      return;
    }

    _homeSection = ApplicationHomeSection.home;
    notifyListeners();
  }

  void showCheckInSection() {
    if (_homeSection == ApplicationHomeSection.checkIn) {
      return;
    }

    _homeSection = ApplicationHomeSection.checkIn;
    notifyListeners();
  }

  void showBookAChargeSection() {
    if (_homeSection == ApplicationHomeSection.bookACharge) {
      return;
    }

    _homeSection = ApplicationHomeSection.bookACharge;
    notifyListeners();
  }
}
