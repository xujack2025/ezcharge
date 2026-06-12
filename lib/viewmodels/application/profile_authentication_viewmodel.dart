import 'dart:io';

import 'package:flutter/foundation.dart';

import '../../core/utils/app_logger.dart';
import '../../services/image_picker_service.dart';
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
    ImagePickerServiceContract? imagePickerService,
  }) : _accountService = accountService ?? ProfileAccountService(),
       _imagePickerService = imagePickerService ?? ImagePickerService();

  final ProfileAccountServiceContract _accountService;
  final ImagePickerServiceContract _imagePickerService;

  bool _isLoading = false;
  File? _selectedImage;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  File? get selectedImage => _selectedImage;
  String? get errorMessage => _errorMessage;

  Future<void> pickImage(AppImageSource source) async {
    final image = await _imagePickerService.pickImage(source);
    if (image == null) return;
    _selectedImage = image;
    notifyListeners();
  }

  void clearSelectedImage() {
    _selectedImage = null;
    notifyListeners();
  }

  Future<ProfileAuthenticationUploadResult> uploadImage({
    required ProfileAuthenticationImageType type,
    File? image,
  }) async {
    final imageToUpload = image ?? _selectedImage;
    if (imageToUpload == null) {
      _errorMessage = 'Please select an image first.';
      notifyListeners();
      return ProfileAuthenticationUploadResult.noImage;
    }

    _setLoading(true);
    _errorMessage = null;

    try {
      await _accountService.uploadAuthenticationImage(
        type: type,
        image: imageToUpload,
      );
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
