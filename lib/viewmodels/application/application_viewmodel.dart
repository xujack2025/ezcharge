import 'package:flutter/material.dart';

class ApplicationViewmodel extends ChangeNotifier {
  int _selectedPages = 0;

  int get selectedPages => _selectedPages;

  void onItemTapped(int index) {
    if (_selectedPages != index) {
      _selectedPages = index;
      notifyListeners();
    }
  }
}
