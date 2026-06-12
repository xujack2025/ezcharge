import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../core/utils/app_logger.dart';
import '../models/profile_account_model.dart';
import 'auth_service.dart';

enum ProfileAuthenticationImageType { license, selfie }

enum ProfileDeleteAccountStatus { success, noUser, customerNotFound }

abstract class ProfileAccountServiceContract {
  Future<String?> getCurrentCustomerId();

  Future<ProfileAuthenticationUpload> uploadAuthenticationImage({
    required ProfileAuthenticationImageType type,
    required File image,
  });

  Future<void> submitAuthenticationRequest();

  Future<List<ProfileBookmarkStation>> fetchBookmarkedStations();

  Future<void> removeBookmark(String bookmarkId);

  Future<ProfileActivityData?> fetchActivity();

  Future<void> cancelReservation();

  Future<ProfileDeleteAccountStatus> deleteCurrentAccount();
}

class ProfileAccountService implements ProfileAccountServiceContract {
  ProfileAccountService({
    AuthServiceContract? authService,
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
    FirebaseAuth? firebaseAuth,
  }) : _authService = authService ?? AuthService(),
       _firestore = firestore ?? FirebaseFirestore.instance,
       _storage = storage ?? FirebaseStorage.instance,
       _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance;

  final AuthServiceContract _authService;
  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;
  final FirebaseAuth _firebaseAuth;

  @override
  Future<String?> getCurrentCustomerId() {
    return _authService.getCurrentCustomerId();
  }

  @override
  Future<ProfileAuthenticationUpload> uploadAuthenticationImage({
    required ProfileAuthenticationImageType type,
    required File image,
  }) async {
    final customerId = await getCurrentCustomerId();
    if (customerId == null || customerId.isEmpty) {
      throw const ProfileAccountCustomerNotFoundException();
    }

    final folder = switch (type) {
      ProfileAuthenticationImageType.license => 'license',
      ProfileAuthenticationImageType.selfie => 'selfie',
    };
    final storageRef = _storage.ref().child('$folder/$customerId.jpg');

    try {
      final snapshot = await storageRef.putFile(image);
      final downloadUrl = await snapshot.ref.getDownloadURL();
      AppLogger.info('Uploaded $folder image for customer: $customerId');
      return ProfileAuthenticationUpload(downloadUrl: downloadUrl);
    } catch (e) {
      AppLogger.error('Error uploading $folder image: $e');
      rethrow;
    }
  }

  @override
  Future<void> submitAuthenticationRequest() async {
    final customerId = await getCurrentCustomerId();
    if (customerId == null || customerId.isEmpty) {
      throw const ProfileAccountCustomerNotFoundException();
    }

    try {
      final licenseUrl = await _storage
          .ref()
          .child('license/$customerId.jpg')
          .getDownloadURL();
      final selfieUrl = await _storage
          .ref()
          .child('selfie/$customerId.jpg')
          .getDownloadURL();

      await _firestore
          .collection('Customers')
          .doc(customerId)
          .collection('Authenticate')
          .doc('authentication')
          .set({
            'LicenseImage': licenseUrl,
            'SelfieImage': selfieUrl,
            'Status': 'Pending',
            'Timestamp': FieldValue.serverTimestamp(),
          });
      AppLogger.info('Submitted profile authentication for: $customerId');
    } catch (e) {
      AppLogger.error('Error submitting profile authentication: $e');
      rethrow;
    }
  }

  @override
  Future<List<ProfileBookmarkStation>> fetchBookmarkedStations() async {
    final customerId = await getCurrentCustomerId();
    if (customerId == null || customerId.isEmpty) {
      throw const ProfileAccountCustomerNotFoundException();
    }

    try {
      final bookmarkSnapshot = await _firestore
          .collection('Customers')
          .doc(customerId)
          .collection('Bookmark')
          .get();

      final bookmarks = <ProfileBookmarkStation>[];
      for (final bookmarkDoc in bookmarkSnapshot.docs) {
        final bookmark = bookmarkDoc.data();
        final stationId = bookmark['StationID']?.toString() ?? '';
        if (stationId.isEmpty) continue;

        final stationSnapshot = await _firestore
            .collection('Station')
            .doc(stationId)
            .get();
        if (!stationSnapshot.exists) continue;

        final station = stationSnapshot.data() ?? {};
        bookmarks.add(
          ProfileBookmarkStation(
            bookmarkId: bookmarkDoc.id,
            stationId: station['StationID']?.toString() ?? stationId,
            stationName: station['StationName']?.toString() ?? '',
            description: station['Description']?.toString() ?? '',
            imageUrl:
                station['ImageUrl']?.toString() ??
                'https://via.placeholder.com/80',
          ),
        );
      }

      return bookmarks;
    } catch (e) {
      AppLogger.error('Error fetching profile bookmarks: $e');
      rethrow;
    }
  }

  @override
  Future<void> removeBookmark(String bookmarkId) async {
    final customerId = await getCurrentCustomerId();
    if (customerId == null || customerId.isEmpty) {
      throw const ProfileAccountCustomerNotFoundException();
    }

    await _firestore
        .collection('Customers')
        .doc(customerId)
        .collection('Bookmark')
        .doc(bookmarkId)
        .delete();
  }

  @override
  Future<ProfileActivityData?> fetchActivity() async {
    final customerId = await getCurrentCustomerId();
    if (customerId == null || customerId.isEmpty) return null;

    final results = await Future.wait([
      _fetchReservationActivity(customerId),
      _fetchEndedAttendances(customerId),
    ]);

    return ProfileActivityData(
      customerId: customerId,
      reservation: results[0] as ProfileReservationActivity?,
      endedAttendances: results[1] as List<ProfileEndedAttendance>,
    );
  }

  @override
  Future<void> cancelReservation() async {
    final customerId = await getCurrentCustomerId();
    if (customerId == null || customerId.isEmpty) {
      throw const ProfileAccountCustomerNotFoundException();
    }

    await _firestore.collection('Reservation').doc(customerId).delete();
  }

  @override
  Future<ProfileDeleteAccountStatus> deleteCurrentAccount() async {
    final user = _firebaseAuth.currentUser;
    if (user == null) return ProfileDeleteAccountStatus.noUser;

    final phoneNumber = user.phoneNumber ?? '';
    if (phoneNumber.isEmpty) return ProfileDeleteAccountStatus.customerNotFound;

    final querySnapshot = await _firestore
        .collection('Customers')
        .where('PhoneNumber', isEqualTo: phoneNumber)
        .limit(1)
        .get();

    if (querySnapshot.docs.isEmpty) {
      return ProfileDeleteAccountStatus.customerNotFound;
    }

    await _firestore
        .collection('Customers')
        .doc(querySnapshot.docs.first.id)
        .delete();
    await user.delete();
    await _firebaseAuth.signOut();
    return ProfileDeleteAccountStatus.success;
  }

  Future<ProfileReservationActivity?> _fetchReservationActivity(
    String customerId,
  ) async {
    final reservationDoc = await _firestore
        .collection('Reservation')
        .doc(customerId)
        .get();
    if (!reservationDoc.exists) return null;

    final reservation = reservationDoc.data() ?? {};
    final stationId = reservation['StationID']?.toString() ?? '';
    final chargerId = reservation['ChargerID']?.toString() ?? '';

    final details = await Future.wait([
      _firestore.collection('Station').doc(stationId).get(),
      _firestore
          .collection('Station')
          .doc(stationId)
          .collection('Charger')
          .doc(chargerId)
          .get(),
    ]);
    final station = details[0].data() ?? {};
    final charger = details[1].data() ?? {};

    return ProfileReservationActivity(
      chargerId: chargerId,
      stationId: stationId,
      status: reservation['Status']?.toString() ?? '',
      stationName: station['StationName']?.toString() ?? '',
      chargerName: charger['ChargerName']?.toString() ?? '',
      chargerType: charger['ChargerType']?.toString() ?? '',
      chargerVoltage: charger['ChargerVoltage']?.toString() ?? '',
      currentType: charger['CurrentType']?.toString() ?? '',
      pricePerVoltage: charger['PricePerVoltage']?.toString() ?? '',
    );
  }

  Future<List<ProfileEndedAttendance>> _fetchEndedAttendances(
    String customerId,
  ) async {
    final attendanceSnapshot = await _firestore
        .collection('Attendance')
        .where('CustomerID', isEqualTo: customerId)
        .get();

    final attendances = <ProfileEndedAttendance>[];
    for (final doc in attendanceSnapshot.docs) {
      final attendance = doc.data();
      final stationId = attendance['StationID']?.toString() ?? '';
      final chargerId = attendance['SlotID']?.toString() ?? '';

      final stationDoc = await _firestore
          .collection('Station')
          .doc(stationId)
          .get();
      final chargerDoc = chargerId.isEmpty
          ? null
          : await _firestore
                .collection('Station')
                .doc(stationId)
                .collection('Charger')
                .doc(chargerId)
                .get();

      attendances.add(
        ProfileEndedAttendance(
          stationName:
              stationDoc.data()?['StationName']?.toString() ?? stationId,
          chargerName:
              chargerDoc?.data()?['ChargerName']?.toString() ?? chargerId,
          totalCost: attendance['TotalCost']?.toString() ?? '0.00',
          duration: attendance['Duration']?.toString() ?? '',
          checkInTime: _parseNullableDateTime(attendance['CheckInTime']),
          checkOutTime: _parseNullableDateTime(attendance['CheckOutTime']),
        ),
      );
    }

    attendances.sort((a, b) {
      final aTime = a.checkOutTime ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bTime = b.checkOutTime ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bTime.compareTo(aTime);
    });

    return attendances;
  }

  DateTime? _parseNullableDateTime(Object? value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }
}

class ProfileAccountCustomerNotFoundException implements Exception {
  const ProfileAccountCustomerNotFoundException();
}
