import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

import '../models/home_station_model.dart';

class BookmarkStatus {
  const BookmarkStatus({required this.isBookmarked, this.bookmarkId = ""});

  final bool isBookmarked;
  final String bookmarkId;
}

abstract class HomeServiceContract {
  Future<List<HomeStation>> fetchStations();

  Future<BookmarkStatus> getBookmarkStatus({
    required String customerId,
    required String stationId,
  });

  Future<BookmarkStatus> addBookmark({
    required String customerId,
    required String stationId,
  });

  Future<void> removeBookmark({
    required String customerId,
    required String bookmarkId,
  });
}

class HomeService implements HomeServiceContract {
  HomeService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  @override
  Future<List<HomeStation>> fetchStations() async {
    final stationSnapshot = await _firestore.collection("station").get();
    final stations = <HomeStation>[];

    for (final stationDoc in stationSnapshot.docs) {
      final chargerSnapshot = await _firestore
          .collection("station")
          .doc(stationDoc.id)
          .collection("Charger")
          .get();

      final currentTypes = <String>{};
      for (final chargerDoc in chargerSnapshot.docs) {
        final chargerData = chargerDoc.data();
        final currentType = chargerData["CurrentType"]?.toString() ?? "";
        if (currentType.isNotEmpty) {
          currentTypes.add(currentType);
        }
      }

      stations.add(
        HomeStation.fromFirestore(
          stationDoc,
          currentTypes: currentTypes.toList(),
        ),
      );
    }

    return stations;
  }

  @override
  Future<BookmarkStatus> getBookmarkStatus({
    required String customerId,
    required String stationId,
  }) async {
    if (customerId.isEmpty) {
      return const BookmarkStatus(isBookmarked: false);
    }

    final bookmarkSnapshot = await _firestore
        .collection("customers")
        .doc(customerId)
        .collection("bookmark")
        .where("StationID", isEqualTo: stationId)
        .limit(1)
        .get();

    if (bookmarkSnapshot.docs.isEmpty) {
      return const BookmarkStatus(isBookmarked: false);
    }

    return BookmarkStatus(
      isBookmarked: true,
      bookmarkId: bookmarkSnapshot.docs.first.id,
    );
  }

  @override
  Future<BookmarkStatus> addBookmark({
    required String customerId,
    required String stationId,
  }) async {
    final formattedDate = DateFormat('yyyyMMdd').format(DateTime.now());
    final bookmarkId = "BKK$formattedDate";

    await _firestore
        .collection("customers")
        .doc(customerId)
        .collection("bookmark")
        .doc(bookmarkId)
        .set({
          "BookmarkID": bookmarkId,
          "StationID": stationId,
          "CustomerID": customerId,
        });

    return BookmarkStatus(isBookmarked: true, bookmarkId: bookmarkId);
  }

  @override
  Future<void> removeBookmark({
    required String customerId,
    required String bookmarkId,
  }) async {
    await _firestore
        .collection("customers")
        .doc(customerId)
        .collection("bookmark")
        .doc(bookmarkId)
        .delete();
  }
}
