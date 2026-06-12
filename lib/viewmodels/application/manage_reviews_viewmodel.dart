import 'package:flutter/foundation.dart';

import '../../core/utils/app_logger.dart';
import '../../models/customer_rating_model.dart';
import '../../services/rating_service.dart';

enum ManageReviewActionResult { success, failed }

class ManageReviewsViewModel extends ChangeNotifier {
  ManageReviewsViewModel({RatingServiceContract? ratingService})
    : _ratingService = ratingService ?? RatingService();

  final RatingServiceContract _ratingService;

  String? _errorMessage;

  String? get errorMessage => _errorMessage;

  Stream<List<CustomerReview>> watchReviews() async* {
    try {
      yield* _ratingService.watchCurrentCustomerReviews();
    } catch (error) {
      AppLogger.error('Error watching reviews: $error');
      _errorMessage = error is RatingCustomerNotFoundException
          ? 'Customer profile not found. Please log in again.'
          : 'Unable to load reviews. Please try again.';
      notifyListeners();
      rethrow;
    }
  }

  Future<ManageReviewActionResult> updateReview({
    required String reviewId,
    required String reviewText,
    required int rating,
  }) async {
    try {
      await _ratingService.updateReview(
        reviewId: reviewId,
        reviewText: reviewText,
        rating: rating,
      );
      _errorMessage = null;
      return ManageReviewActionResult.success;
    } catch (e) {
      AppLogger.error('Error updating review: $e');
      _errorMessage = 'Unable to update review. Please try again.';
      notifyListeners();
      return ManageReviewActionResult.failed;
    }
  }

  Future<ManageReviewActionResult> deleteReview(String reviewId) async {
    try {
      await _ratingService.deleteReview(reviewId);
      _errorMessage = null;
      return ManageReviewActionResult.success;
    } catch (e) {
      AppLogger.error('Error deleting review: $e');
      _errorMessage = 'Unable to delete review. Please try again.';
      notifyListeners();
      return ManageReviewActionResult.failed;
    }
  }
}
