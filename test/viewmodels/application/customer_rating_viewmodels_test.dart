import 'dart:io';

import 'package:ezcharge/models/customer_rating_model.dart';
import 'package:ezcharge/services/rating_service.dart';
import 'package:ezcharge/viewmodels/application/customer_complaint_viewmodel.dart';
import 'package:ezcharge/viewmodels/application/customer_review_viewmodel.dart';
import 'package:ezcharge/viewmodels/application/manage_complaints_viewmodel.dart';
import 'package:ezcharge/viewmodels/application/manage_reviews_viewmodel.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeRatingService implements RatingServiceContract {
  RatingCustomer? customer = const RatingCustomer(
    customerId: 'CUS1',
    displayName: 'Jane Doe',
  );
  List<RatingChargerBay> bays = const [];
  List<CustomerReview> reviews = const [];
  List<CustomerComplaint> complaints = const [];
  Object? error;

  String? submittedComplaintStationId;
  String? submittedComplaintChargerId;
  String? submittedComplaintChargerName;
  String? submittedComplaintReason;
  String? submittedComplaintDescription;
  File? submittedComplaintImage;
  String? submittedReviewStationId;
  int? submittedReviewRating;
  String? submittedReviewText;
  String? updatedReviewId;
  String? updatedReviewText;
  int? updatedReviewRating;
  String? deletedReviewId;

  @override
  Future<RatingCustomer?> fetchCurrentCustomer() async {
    final error = this.error;
    if (error != null) throw error;
    return customer;
  }

  @override
  Future<List<RatingChargerBay>> fetchChargingBays(String stationId) async {
    final error = this.error;
    if (error != null) throw error;
    return bays;
  }

  @override
  Future<void> submitComplaint({
    required String stationId,
    required String chargerId,
    required String chargerName,
    required String reason,
    required String description,
    File? image,
  }) async {
    final error = this.error;
    if (error != null) throw error;
    submittedComplaintStationId = stationId;
    submittedComplaintChargerId = chargerId;
    submittedComplaintChargerName = chargerName;
    submittedComplaintReason = reason;
    submittedComplaintDescription = description;
    submittedComplaintImage = image;
  }

  @override
  Future<void> submitReview({
    required String stationId,
    required int rating,
    required String reviewText,
  }) async {
    final error = this.error;
    if (error != null) throw error;
    submittedReviewStationId = stationId;
    submittedReviewRating = rating;
    submittedReviewText = reviewText;
  }

  @override
  Stream<List<CustomerReview>> watchCurrentCustomerReviews() async* {
    final error = this.error;
    if (error != null) throw error;
    yield reviews;
  }

  @override
  Future<void> updateReview({
    required String reviewId,
    required String reviewText,
    required int rating,
  }) async {
    final error = this.error;
    if (error != null) throw error;
    updatedReviewId = reviewId;
    updatedReviewText = reviewText;
    updatedReviewRating = rating;
  }

  @override
  Future<void> deleteReview(String reviewId) async {
    final error = this.error;
    if (error != null) throw error;
    deletedReviewId = reviewId;
  }

  @override
  Stream<List<CustomerComplaint>> watchCurrentCustomerComplaints() async* {
    final error = this.error;
    if (error != null) throw error;
    yield complaints;
  }
}

void main() {
  group('CustomerComplaintViewModel', () {
    test('loads bays and submits complaint through service', () async {
      final service = _FakeRatingService()
        ..bays = const [
          RatingChargerBay(chargerId: 'CH1', chargerName: 'Bay 1'),
        ];
      final viewModel = CustomerComplaintViewModel(ratingService: service);
      final image = File('/tmp/complaint.jpg');

      await viewModel.loadChargingBays('ST1');
      viewModel.selectBay('CH1');
      viewModel.selectReportReason('Blocked bay');
      viewModel.updateDetails('A car is blocking this bay');
      final result = await viewModel.submitComplaint(
        stationId: 'ST1',
        image: image,
      );

      expect(result, CustomerComplaintSubmitResult.success);
      expect(service.submittedComplaintStationId, 'ST1');
      expect(service.submittedComplaintChargerId, 'CH1');
      expect(service.submittedComplaintChargerName, 'Bay 1');
      expect(service.submittedComplaintReason, 'Blocked bay');
      expect(
        service.submittedComplaintDescription,
        'A car is blocking this bay',
      );
      expect(service.submittedComplaintImage, image);
    });

    test('blocks submit when bay or reason is missing', () async {
      final service = _FakeRatingService();
      final viewModel = CustomerComplaintViewModel(ratingService: service);

      final result = await viewModel.submitComplaint(stationId: 'ST1');

      expect(result, CustomerComplaintSubmitResult.missingRequiredFields);
      expect(service.submittedComplaintStationId, isNull);
      expect(viewModel.errorMessage, 'Please select a bay and report reason.');
    });
  });

  group('CustomerReviewViewModel', () {
    test('loads customer and submits review through service', () async {
      final service = _FakeRatingService();
      final viewModel = CustomerReviewViewModel(ratingService: service);

      await viewModel.loadCustomer();
      viewModel.updateRating(5);
      viewModel.updateComment('Excellent charger');
      final result = await viewModel.submitReview('ST1');

      expect(result, CustomerReviewSubmitResult.success);
      expect(viewModel.username, 'Jane Doe');
      expect(service.submittedReviewStationId, 'ST1');
      expect(service.submittedReviewRating, 5);
      expect(service.submittedReviewText, 'Excellent charger');
    });

    test('blocks submit when rating is missing', () async {
      final service = _FakeRatingService();
      final viewModel = CustomerReviewViewModel(ratingService: service);

      final result = await viewModel.submitReview('ST1');

      expect(result, CustomerReviewSubmitResult.missingRating);
      expect(service.submittedReviewStationId, isNull);
      expect(viewModel.errorMessage, 'Please select a star rating.');
    });
  });

  group('ManageReviewsViewModel', () {
    test('watches reviews and updates/deletes through service', () async {
      final service = _FakeRatingService()
        ..reviews = [
          CustomerReview(
            reviewId: 'RVW0001',
            reviewText: 'Good',
            rating: 4,
            reviewDate: DateTime(2026),
          ),
        ];
      final viewModel = ManageReviewsViewModel(ratingService: service);

      final reviews = await viewModel.watchReviews().first;
      final updateResult = await viewModel.updateReview(
        reviewId: 'RVW0001',
        reviewText: 'Great',
        rating: 5,
      );
      final deleteResult = await viewModel.deleteReview('RVW0001');

      expect(reviews, hasLength(1));
      expect(updateResult, ManageReviewActionResult.success);
      expect(deleteResult, ManageReviewActionResult.success);
      expect(service.updatedReviewText, 'Great');
      expect(service.updatedReviewRating, 5);
      expect(service.deletedReviewId, 'RVW0001');
    });
  });

  group('ManageComplaintsViewModel', () {
    test('watches typed complaints through service', () async {
      final service = _FakeRatingService()
        ..complaints = [
          CustomerComplaint(
            documentId: 'CUS1-CMP0001',
            complaintId: 'CMP0001',
            reason: 'Payment issue',
            description: 'Receipt missing',
            status: 'Pending',
            imageUrl: '',
            chargerBay: 'Bay 1',
            complaintDate: DateTime(2026),
          ),
        ];
      final viewModel = ManageComplaintsViewModel(ratingService: service);

      final complaints = await viewModel.watchComplaints().first;

      expect(complaints, hasLength(1));
      expect(complaints.first.reason, 'Payment issue');
    });
  });
}
