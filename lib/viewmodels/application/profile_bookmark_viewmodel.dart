import 'package:flutter/foundation.dart';

import '../../core/utils/app_logger.dart';
import '../../models/profile_account_model.dart';
import '../../services/profile_account_service.dart';

enum ProfileBookmarkRemoveResult { success, customerNotFound, failed }

class ProfileBookmarkViewModel extends ChangeNotifier {
  ProfileBookmarkViewModel({ProfileAccountServiceContract? accountService})
    : _accountService = accountService ?? ProfileAccountService();

  final ProfileAccountServiceContract _accountService;

  List<ProfileBookmarkStation> _stations = const [];
  bool _isLoading = false;
  String? _errorMessage;

  List<ProfileBookmarkStation> get stations => _stations;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> loadBookmarks() async {
    _setLoading(true);
    _errorMessage = null;

    try {
      _stations = await _accountService.fetchBookmarkedStations();
    } on ProfileAccountCustomerNotFoundException {
      _stations = const [];
      _errorMessage = 'Customer profile was not found.';
    } catch (e) {
      AppLogger.error('Error loading bookmark view state: $e');
      _stations = const [];
      _errorMessage = 'Unable to load bookmarks. Please try again.';
    } finally {
      _setLoading(false);
    }
  }

  Future<ProfileBookmarkRemoveResult> removeBookmark(String bookmarkId) async {
    try {
      await _accountService.removeBookmark(bookmarkId);
      _stations = _stations
          .where((station) => station.bookmarkId != bookmarkId)
          .toList();
      notifyListeners();
      return ProfileBookmarkRemoveResult.success;
    } on ProfileAccountCustomerNotFoundException {
      _errorMessage = 'Customer profile was not found.';
      notifyListeners();
      return ProfileBookmarkRemoveResult.customerNotFound;
    } catch (e) {
      AppLogger.error('Error removing bookmark view state: $e');
      _errorMessage = 'Unable to remove bookmark. Please try again.';
      notifyListeners();
      return ProfileBookmarkRemoveResult.failed;
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
