import 'package:flutter/foundation.dart';

import '../../core/utils/app_logger.dart';
import '../../models/customer_rating_model.dart';
import '../../services/rating_service.dart';

class ManageComplaintsViewModel extends ChangeNotifier {
  ManageComplaintsViewModel({RatingServiceContract? ratingService})
    : _ratingService = ratingService ?? RatingService();

  final RatingServiceContract _ratingService;

  String? _errorMessage;

  String? get errorMessage => _errorMessage;

  Stream<List<CustomerComplaint>> watchComplaints() async* {
    try {
      yield* _ratingService.watchCurrentCustomerComplaints();
    } catch (error) {
      AppLogger.error('Error watching complaints: $error');
      _errorMessage = error is RatingCustomerNotFoundException
          ? 'Customer profile not found. Please log in again.'
          : 'Unable to load complaints. Please try again.';
      notifyListeners();
      rethrow;
    }
  }
}
