import 'package:flutter/foundation.dart';

import '../../core/utils/app_logger.dart';
import '../../services/profile_account_service.dart';

enum DeleteAccountResult { success, noUser, customerNotFound, failed }

class DeleteAccountViewModel extends ChangeNotifier {
  DeleteAccountViewModel({ProfileAccountServiceContract? accountService})
    : _accountService = accountService ?? ProfileAccountService();

  final ProfileAccountServiceContract _accountService;

  bool _isLoading = false;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<DeleteAccountResult> deleteAccount() async {
    _setLoading(true);
    _errorMessage = null;

    try {
      final status = await _accountService.deleteCurrentAccount();
      switch (status) {
        case ProfileDeleteAccountStatus.success:
          return DeleteAccountResult.success;
        case ProfileDeleteAccountStatus.noUser:
          _errorMessage = 'No signed-in user was found.';
          return DeleteAccountResult.noUser;
        case ProfileDeleteAccountStatus.customerNotFound:
          _errorMessage = 'Customer profile was not found.';
          return DeleteAccountResult.customerNotFound;
      }
    } catch (e) {
      AppLogger.error('Error deleting account view state: $e');
      _errorMessage = 'Unable to delete account. Please try again.';
      return DeleteAccountResult.failed;
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
