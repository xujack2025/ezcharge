import 'package:cloud_firestore/cloud_firestore.dart';

import 'charging_reservation_charger_model.dart';

class ChargingStationDetail {
  const ChargingStationDetail({
    required this.stationId,
    required this.stationName,
    required this.description,
    required this.location,
    required this.latitude,
    required this.longitude,
    required this.imageUrl,
    required this.capacity,
  });

  final String stationId;
  final String stationName;
  final String description;
  final String location;
  final String latitude;
  final String longitude;
  final String imageUrl;
  final int capacity;

  factory ChargingStationDetail.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    return ChargingStationDetail(
      stationId: data["StationID"]?.toString() ?? doc.id,
      stationName: data["StationName"]?.toString() ?? "Charging Station",
      description: data["Description"]?.toString() ?? "Location details",
      location: data["Location"]?.toString() ?? "Location not available",
      latitude: data["Latitude"]?.toString() ?? "",
      longitude: data["Longitude"]?.toString() ?? "",
      imageUrl:
          data["ImageUrl"]?.toString() ?? "https://via.placeholder.com/80",
      capacity: (data["Capacity"] as num?)?.toInt() ?? 0,
    );
  }

  ChargingStationDetail copyWith({int? capacity}) {
    return ChargingStationDetail(
      stationId: stationId,
      stationName: stationName,
      description: description,
      location: location,
      latitude: latitude,
      longitude: longitude,
      imageUrl: imageUrl,
      capacity: capacity ?? this.capacity,
    );
  }

  double? get parsedLatitude => double.tryParse(latitude);
  double? get parsedLongitude => double.tryParse(longitude);
}

class ChargingStationReview {
  const ChargingStationReview({
    required this.rating,
    required this.reviewText,
    required this.reviewerLabel,
    required this.reviewDate,
  });

  final int rating;
  final String reviewText;
  final String reviewerLabel;
  final DateTime? reviewDate;

  factory ChargingStationReview.fromMap(Map<String, dynamic> data) {
    final rawDate = data["ReviewDate"];

    return ChargingStationReview(
      rating: (data["Rating"] as num?)?.toInt() ?? 0,
      reviewText: data["ReviewText"]?.toString() ?? "No comment",
      reviewerLabel:
          data["CarModel"]?.toString() ??
          data["CustomerID"]?.toString() ??
          "Unknown User",
      reviewDate: rawDate is Timestamp ? rawDate.toDate() : null,
    );
  }
}

class ChargingStationDetailData {
  const ChargingStationDetailData({
    required this.station,
    required this.chargers,
  });

  final ChargingStationDetail station;
  final List<ChargingReservationCharger> chargers;
}

class ChargingStationAccess {
  const ChargingStationAccess({
    required this.customerId,
    required this.authenticationStatus,
    required this.reservationStatus,
  });

  final String customerId;
  final String authenticationStatus;
  final String reservationStatus;

  bool get canReserve =>
      authenticationStatus == "Pass" &&
      reservationStatus != "Upcoming" &&
      reservationStatus != "Active";

  bool get hasBlockingReservation =>
      reservationStatus == "Upcoming" || reservationStatus == "Active";
}
