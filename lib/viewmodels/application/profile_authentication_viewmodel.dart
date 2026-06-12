import 'dart:io';

import 'package:flutter/foundation.dart';

import '../../core/utils/app_logger.dart';
import '../../services/profile_account_service.dart';

enum ProfileAuthenticationUploadResult {
  success,
  noImage,
  customerNotFound,
  failed,
}

enum ProfileAuthenticationSubmitResult { success, customerNotFound, failed }

class ProfileAuthenticationViewModel extends ChangeNotifier {
  ProfileAuthenticationViewModel({
    ProfileAccountServiceContract? accountService,
  }) : _accountService = accountService ?? ProfileAccountService();

  final ProfileAccountServiceContract _accountService;

  bool _isLoading = false;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<ProfileAuthenticationUploadResult> uploadImage({
    required ProfileAuthenticationImageType type,
    required File? image,
  }) async {
    if (image == null) {
      _errorMessage = 'Please select an image first.';
      notifyListeners();
      return ProfileAuthenticationUploadResult.noImage;
    }

    _setLoading(true);
    _errorMessage = null;

    try {
      await _accountService.uploadAuthenticationImage(type: type, image: image);
      return ProfileAuthenticationUploadResult.success;
    } on ProfileAccountCustomerNotFoundException {
      _errorMessage = 'Customer profile was not found.';
      return ProfileAuthenticationUploadResult.customerNotFound;
    } catch (e) {
      AppLogger.error('Error uploading authentication image: $e');
      _errorMessage = 'Failed to upload image. Please try again.';
      return ProfileAuthenticationUploadResult.failed;
    } finally {
      _setLoading(false);
    }
  }

  Future<ProfileAuthenticationSubmitResult>
  submitAuthenticationRequest() async {
    _setLoading(true);
    _errorMessage = null;

    try {
      await _accountService.submitAuthenticationRequest();
      return ProfileAuthenticationSubmitResult.success;
    } on ProfileAccountCustomerNotFoundException {
      _errorMessage = 'Customer profile was not found.';
      return ProfileAuthenticationSubmitResult.customerNotFound;
    } catch (e) {
      AppLogger.error('Error submitting authentication request: $e');
      _errorMessage = 'Unable to submit authentication request.';
      return ProfileAuthenticationSubmitResult.failed;
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
