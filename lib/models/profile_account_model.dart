class ProfileAuthenticationUpload {
  const ProfileAuthenticationUpload({required this.downloadUrl});

  final String downloadUrl;
}

class ProfileBookmarkStation {
  const ProfileBookmarkStation({
    required this.bookmarkId,
    required this.stationId,
    required this.stationName,
    required this.description,
    required this.imageUrl,
  });

  final String bookmarkId;
  final String stationId;
  final String stationName;
  final String description;
  final String imageUrl;
}

class ProfileActivityData {
  const ProfileActivityData({
    required this.customerId,
    this.reservation,
    this.endedAttendances = const [],
  });

  final String customerId;
  final ProfileReservationActivity? reservation;
  final List<ProfileEndedAttendance> endedAttendances;
}

class ProfileReservationActivity {
  const ProfileReservationActivity({
    required this.chargerId,
    required this.stationId,
    required this.status,
    required this.stationName,
    required this.chargerName,
    required this.chargerType,
    required this.chargerVoltage,
    required this.currentType,
    required this.pricePerVoltage,
  });

  final String chargerId;
  final String stationId;
  final String status;
  final String stationName;
  final String chargerName;
  final String chargerType;
  final String chargerVoltage;
  final String currentType;
  final String pricePerVoltage;
}

class ProfileEndedAttendance {
  const ProfileEndedAttendance({
    required this.stationName,
    required this.chargerName,
    required this.totalCost,
    required this.duration,
    required this.checkInTime,
    required this.checkOutTime,
  });

  final String stationName;
  final String chargerName;
  final String totalCost;
  final String duration;
  final DateTime? checkInTime;
  final DateTime? checkOutTime;
}
