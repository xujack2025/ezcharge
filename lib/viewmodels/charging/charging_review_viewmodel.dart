import 'package:flutter/foundation.dart';

import '../../core/utils/app_logger.dart';
import '../../models/charging_review_model.dart';
import '../../services/charging_review_service.dart';

enum ChargingReviewSubmitResult { success, missingRating, userNotFound, failed }

class ChargingReviewViewModel extends ChangeNotifier {
  ChargingReviewViewModel({ChargingReviewServiceContract? reviewService})
    : _reviewService = reviewService ?? ChargingReviewService();

  final ChargingReviewServiceContract _reviewService;

  ChargingReviewUser? _user;
  int _rating = 0;
  String _comment = '';
  bool _isLoading = false;
  bool _isSubmitting = false;
  String? _errorMessage;

  ChargingReviewUser? get user => _user;
  int get rating => _rating;
  String get comment => _comment;
  bool get isLoading => _isLoading;
  bool get isSubmitting => _isSubmitting;
  String? get errorMessage => _errorMessage;
  String get username => _user?.username ?? '';

  Future<void> loadUser() async {
    _setLoading(true);
    _errorMessage = null;

    try {
      _user = await _reviewService.fetchCurrentReviewUser();
      if (_user == null) {
        _errorMessage = 'User not found. Please log in again.';
      }
    } catch (e) {
      AppLogger.error('Error loading review user: $e');
      _user = null;
      _errorMessage = 'Failed to load user details.';
    } finally {
      _setLoading(false);
    }
  }

  void updateRating(int value) {
    _rating = value;
    notifyListeners();
  }

  void updateComment(String value) {
    _comment = value;
    notifyListeners();
  }

  Future<ChargingReviewSubmitResult> submitReview(String stationId) async {
    if (_rating == 0) {
      _errorMessage = 'Please select a rating!';
      notifyListeners();
      return ChargingReviewSubmitResult.missingRating;
    }

    final user = _user;
    if (user == null) {
      _errorMessage = 'User not found. Please log in again.';
      notifyListeners();
      return ChargingReviewSubmitResult.userNotFound;
    }

    _setSubmitting(true);
    _errorMessage = null;

    try {
      await _reviewService.submitReview(
        customerId: user.customerId,
        stationId: stationId,
        rating: _rating,
        comment: _comment,
      );
      return ChargingReviewSubmitResult.success;
    } catch (e) {
      AppLogger.error('Error submitting review: $e');
      _errorMessage = 'Review submission failed. Try again!';
      return ChargingReviewSubmitResult.failed;
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
