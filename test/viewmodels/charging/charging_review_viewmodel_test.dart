import 'package:ezcharge/models/charging_review_model.dart';
import 'package:ezcharge/services/charging_review_service.dart';
import 'package:ezcharge/viewmodels/charging/charging_review_viewmodel.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeChargingReviewService implements ChargingReviewServiceContract {
  _FakeChargingReviewService({this.user});

  ChargingReviewUser? user;
  String? submittedCustomerId;
  String? submittedStationId;
  int? submittedRating;
  String? submittedComment;

  @override
  Future<ChargingReviewUser?> fetchCurrentReviewUser() async {
    return user;
  }

  @override
  Future<void> submitReview({
    required String customerId,
    required String stationId,
    required int rating,
    required String comment,
    DateTime? submittedAt,
  }) async {
    submittedCustomerId = customerId;
    submittedStationId = stationId;
    submittedRating = rating;
    submittedComment = comment;
  }
}

void main() {
  test('submits review through service after loading current user', () async {
    final service = _FakeChargingReviewService(
      user: const ChargingReviewUser(customerId: 'CUS1', username: 'Jane Doe'),
    );
    final viewModel = ChargingReviewViewModel(reviewService: service);

    await viewModel.loadUser();
    viewModel.updateRating(5);
    viewModel.updateComment('Great charging bay');
    final result = await viewModel.submitReview('ST1');

    expect(result, ChargingReviewSubmitResult.success);
    expect(viewModel.username, 'Jane Doe');
    expect(service.submittedCustomerId, 'CUS1');
    expect(service.submittedStationId, 'ST1');
    expect(service.submittedRating, 5);
    expect(service.submittedComment, 'Great charging bay');
  });

  test('blocks submit when rating is missing', () async {
    final service = _FakeChargingReviewService(
      user: const ChargingReviewUser(customerId: 'CUS1', username: 'Jane Doe'),
    );
    final viewModel = ChargingReviewViewModel(reviewService: service);

    await viewModel.loadUser();
    final result = await viewModel.submitReview('ST1');

    expect(result, ChargingReviewSubmitResult.missingRating);
    expect(service.submittedCustomerId, isNull);
    expect(viewModel.errorMessage, 'Please select a rating!');
  });
}
