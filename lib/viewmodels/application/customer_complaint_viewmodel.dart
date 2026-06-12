import 'dart:io';

import 'package:flutter/foundation.dart';

import '../../core/utils/app_logger.dart';
import '../../models/customer_rating_model.dart';
import '../../services/image_picker_service.dart';
import '../../services/rating_service.dart';

enum CustomerComplaintSubmitResult {
  success,
  missingRequiredFields,
  customerNotFound,
  failed,
}

class CustomerComplaintViewModel extends ChangeNotifier {
  CustomerComplaintViewModel({RatingServiceContract? ratingService})
    : _ratingService = ratingService ?? RatingService(),
      _imagePickerService = ImagePickerService();

  final RatingServiceContract _ratingService;
  final ImagePickerServiceContract _imagePickerService;

  List<RatingChargerBay> _chargingBays = const [];
  bool _isLoading = false;
  bool _isSubmitting = false;
  File? _selectedImage;
  String? _selectedBayId;
  String? _selectedBayName;
  String? _reportReason;
  String _details = '';
  String? _errorMessage;

  List<RatingChargerBay> get chargingBays => _chargingBays;
  bool get isLoading => _isLoading;
  bool get isSubmitting => _isSubmitting;
  String? get selectedBayId => _selectedBayId;
  String? get selectedBayName => _selectedBayName;
  String? get reportReason => _reportReason;
  String get details => _details;
  File? get selectedImage => _selectedImage;
  String? get errorMessage => _errorMessage;

  Future<void> pickImage() async {
    final image = await _imagePickerService.pickImage(AppImageSource.gallery);
    if (image == null) return;
    _selectedImage = image;
    notifyListeners();
  }

  Future<void> loadChargingBays(String stationId) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      _chargingBays = await _ratingService.fetchChargingBays(stationId);
    } catch (e) {
      AppLogger.error('Error loading complaint charging bays: $e');
      _chargingBays = const [];
      _errorMessage = 'Unable to load charging bays. Please try again.';
    } finally {
      _setLoading(false);
    }
  }

  void selectBay(String? chargerId) {
    _selectedBayId = chargerId;
    _selectedBayName = null;
    for (final bay in _chargingBays) {
      if (bay.chargerId == chargerId) {
        _selectedBayName = bay.chargerName;
        break;
      }
    }
    notifyListeners();
  }

  void selectReportReason(String? value) {
    _reportReason = value;
    notifyListeners();
  }

  void updateDetails(String value) {
    _details = value;
    notifyListeners();
  }

  Future<CustomerComplaintSubmitResult> submitComplaint({
    required String stationId,
    File? image,
  }) async {
    final bayId = _selectedBayId;
    final bayName = _selectedBayName;
    final reason = _reportReason;
    if (bayId == null || bayName == null || reason == null) {
      _errorMessage = 'Please select a bay and report reason.';
      notifyListeners();
      return CustomerComplaintSubmitResult.missingRequiredFields;
    }

    _setSubmitting(true);
    _errorMessage = null;

    try {
      await _ratingService.submitComplaint(
        stationId: stationId,
        chargerId: bayId,
        chargerName: bayName,
        reason: reason,
        description: _details,
        image: image ?? _selectedImage,
      );
      _reportReason = null;
      _selectedBayId = null;
      _selectedBayName = null;
      _details = '';
      _selectedImage = null;
      return CustomerComplaintSubmitResult.success;
    } on RatingCustomerNotFoundException {
      _errorMessage = 'Customer profile not found. Please log in again.';
      return CustomerComplaintSubmitResult.customerNotFound;
    } catch (e) {
      AppLogger.error('Error submitting complaint: $e');
      _errorMessage = 'Unable to submit complaint. Please try again.';
      return CustomerComplaintSubmitResult.failed;
    } finally {
      _setSubmitting(false);
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setSubmitting(bool value) {
    _isSubmitting = value;
    notifyListeners();
  }
}
