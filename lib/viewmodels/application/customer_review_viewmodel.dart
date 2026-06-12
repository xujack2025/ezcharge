import 'package:flutter/foundation.dart';

import '../../core/utils/app_logger.dart';
import '../../models/customer_rating_model.dart';
import '../../services/rating_service.dart';

enum CustomerReviewSubmitResult {
  success,
  missingRating,
  customerNotFound,
  failed,
}

class CustomerReviewViewModel extends ChangeNotifier {
  CustomerReviewViewModel({RatingServiceContract? ratingService})
    : _ratingService = ratingService ?? RatingService();

  final RatingServiceContract _ratingService;

  RatingCustomer? _customer;
  int _rating = 0;
  String _comment = '';
  bool _isLoading = false;
  bool _isSubmitting = false;
  String? _errorMessage;

  RatingCustomer? get customer => _customer;
  int get rating => _rating;
  String get comment => _comment;
  bool get isLoading => _isLoading;
  bool get isSubmitting => _isSubmitting;
  String? get errorMessage => _errorMessage;
  String get username => _customer?.displayName ?? 'Guest';

  Future<void> loadCustomer() async {
    _setLoading(true);
    _errorMessage = null;

    try {
      _customer = await _ratingService.fetchCurrentCustomer();
      if (_customer == null) {
        _errorMessage = 'Customer profile not found. Please log in again.';
      }
    } catch (e) {
      AppLogger.error('Error loading review customer: $e');
      _customer = null;
      _errorMessage = 'Unable to load customer details.';
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

  Future<CustomerReviewSubmitResult> submitReview(String stationId) async {
    if (_rating == 0) {
      _errorMessage = 'Please select a star rating.';
      notifyListeners();
      return CustomerReviewSubmitResult.missingRating;
    }

    _setSubmitting(true);
    _errorMessage = null;

    try {
      await _ratingService.submitReview(
        stationId: stationId,
        rating: _rating,
        reviewText: _comment,
      );
      _rating = 0;
      _comment = '';
      return CustomerReviewSubmitResult.success;
    } on RatingCustomerNotFoundException {
      _errorMessage = 'Customer profile not found. Please log in again.';
      return CustomerReviewSubmitResult.customerNotFound;
    } catch (e) {
      AppLogger.error('Error submitting review: $e');
      _errorMessage = 'Unable to submit review. Please try again.';
      return CustomerReviewSubmitResult.failed;
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
