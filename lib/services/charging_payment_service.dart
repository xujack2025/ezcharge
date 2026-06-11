import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/charging_checkout_model.dart';

abstract class ChargingPaymentServiceContract {
  Future<ChargingPaymentSummaryDetails?> fetchPaymentSummaryDetails();

  Future<ChargingPaymentProfile?> fetchPaymentProfile();

  Future<ChargingPaymentProcessResult> processPayment({
    required String customerId,
    required double totalAmount,
    required ChargingPaymentMethod method,
    required String rewardId,
    required int rewardPoints,
  });

  Future<ChargingPaymentHistoryDetails?> fetchPaymentHistoryDetails();

  Future<ChargingPaymentHistoryDetail?> fetchPaymentHistoryDetail({
    required String accountId,
    required String paymentId,
  });

  Future<String> createPaymentHistoryRecord({
    required ChargingPaymentHistoryDetails details,
    required String paymentMethod,
    required double totalAmount,
    DateTime? paidAt,
  });
}

class ChargingPaymentService implements ChargingPaymentServiceContract {
  ChargingPaymentService({FirebaseAuth? auth, FirebaseFirestore? firestore})
    : _auth = auth ?? FirebaseAuth.instance,
      _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  @override
  Future<ChargingPaymentSummaryDetails?> fetchPaymentSummaryDetails() async {
    final customerId = await _fetchCurrentCustomerId();
    if (customerId == null || customerId.isEmpty) return null;

    final reservationDoc = await _firestore
        .collection('Reservation')
        .doc(customerId)
        .get();
    if (!reservationDoc.exists) return null;

    final reservation = reservationDoc.data() ?? {};
    final stationId = reservation['StationID']?.toString() ?? '';
    final chargerId = reservation['ChargerID']?.toString() ?? '';
    final reservationStatus = reservation['Status']?.toString() ?? '';

    Map<String, dynamic> station = {};
    Map<String, dynamic> charger = {};
    if (reservationStatus == 'Ended') {
      final results = await Future.wait([
        _firestore.collection('Station').doc(stationId).get(),
        _firestore
            .collection('Station')
            .doc(stationId)
            .collection('Charger')
            .doc(chargerId)
            .get(),
      ]);
      station = results[0].data() ?? {};
      charger = results[1].data() ?? {};
    }

    return ChargingPaymentSummaryDetails(
      customerId: customerId,
      stationId: stationId,
      chargerId: chargerId,
      stationName: station['StationName']?.toString() ?? '',
      chargerName: charger['ChargerName']?.toString() ?? '',
      chargerType: charger['ChargerType']?.toString() ?? '',
      stationImageUrl: station['ImageUrl']?.toString() ?? '',
      reservationStatus: reservationStatus,
    );
  }

  @override
  Future<ChargingPaymentProfile?> fetchPaymentProfile() async {
    final customerSnapshot = await _fetchCurrentCustomerSnapshot();
    if (customerSnapshot == null) return null;

    final customer = customerSnapshot.data();
    final paymentMethodSnapshot = await _firestore
        .collection('Customers')
        .doc(customerSnapshot.id)
        .collection('PaymentMethod')
        .limit(1)
        .get();

    return ChargingPaymentProfile(
      customerId: customer['CustomerID']?.toString() ?? customerSnapshot.id,
      walletBalance: _parseDouble(customer['WalletBalance']),
      pointBalance: _parseInt(customer['PointBalance']),
      cardNumber: paymentMethodSnapshot.docs.isEmpty
          ? null
          : paymentMethodSnapshot.docs.first.data()['CardNumber']?.toString(),
    );
  }

  @override
  Future<ChargingPaymentProcessResult> processPayment({
    required String customerId,
    required double totalAmount,
    required ChargingPaymentMethod method,
    required String rewardId,
    required int rewardPoints,
  }) async {
    if (customerId.isEmpty) {
      return const ChargingPaymentProcessResult(
        status: ChargingPaymentProcessStatus.customerNotFound,
        paymentMethodLabel: '',
        walletBalance: 0,
      );
    }

    final customerRef = _firestore.collection('Customers').doc(customerId);

    try {
      return await _firestore.runTransaction((transaction) async {
        final customerSnapshot = await transaction.get(customerRef);
        if (!customerSnapshot.exists) {
          return const ChargingPaymentProcessResult(
            status: ChargingPaymentProcessStatus.customerNotFound,
            paymentMethodLabel: '',
            walletBalance: 0,
          );
        }

        final customer = customerSnapshot.data() ?? {};
        final currentBalance = _parseDouble(customer['WalletBalance']);
        final currentPoints = _parseInt(customer['PointBalance']);
        final updates = <String, dynamic>{};
        var newBalance = currentBalance;

        if (method == ChargingPaymentMethod.wallet) {
          if (currentBalance < totalAmount) {
            return ChargingPaymentProcessResult(
              status: ChargingPaymentProcessStatus.insufficientBalance,
              paymentMethodLabel: '',
              walletBalance: currentBalance,
            );
          }

          newBalance = currentBalance - totalAmount;
          updates['WalletBalance'] = newBalance;
        }

        if (rewardId.isNotEmpty) {
          updates['UsedReward'] = FieldValue.arrayUnion([rewardId]);
          if (rewardPoints > 0) {
            updates['PointBalance'] = currentPoints - rewardPoints;
          }
        }

        if (updates.isNotEmpty) {
          transaction.update(customerRef, updates);
        }

        return ChargingPaymentProcessResult(
          status: ChargingPaymentProcessStatus.success,
          paymentMethodLabel: method == ChargingPaymentMethod.wallet
              ? 'EZCHARGE Wallet'
              : 'Credit Card',
          walletBalance: newBalance,
        );
      });
    } catch (_) {
      return ChargingPaymentProcessResult(
        status: ChargingPaymentProcessStatus.failed,
        paymentMethodLabel: method == ChargingPaymentMethod.wallet
            ? 'EZCHARGE Wallet'
            : 'Credit Card',
        walletBalance: 0,
      );
    }
  }

  @override
  Future<ChargingPaymentHistoryDetails?> fetchPaymentHistoryDetails() async {
    final customerId = await _fetchCurrentCustomerId();
    if (customerId == null || customerId.isEmpty) return null;

    final reservationDoc = await _firestore
        .collection('Reservation')
        .doc(customerId)
        .get();
    if (!reservationDoc.exists) return null;

    final reservationId =
        (reservationDoc.data() ?? {})['ReservationID']?.toString() ?? '';
    if (reservationId.isEmpty) return null;

    final attendanceSnapshot = await _firestore
        .collection('Attendance')
        .where('ReservationID', isEqualTo: reservationId)
        .limit(1)
        .get();
    if (attendanceSnapshot.docs.isEmpty) return null;

    final attendance = attendanceSnapshot.docs.first.data();
    final stationId = attendance['StationID']?.toString() ?? '';
    final chargerId = attendance['SlotID']?.toString() ?? '';

    final results = await Future.wait([
      _firestore.collection('Station').doc(stationId).get(),
      _firestore
          .collection('Station')
          .doc(stationId)
          .collection('Charger')
          .doc(chargerId)
          .get(),
    ]);
    final station = results[0].data() ?? {};
    final charger = results[1].data() ?? {};

    return ChargingPaymentHistoryDetails(
      customerId: customerId,
      duration: attendance['Duration']?.toString() ?? '',
      stationName: station['StationName']?.toString() ?? '',
      chargerName: charger['ChargerName']?.toString() ?? '',
      chargerType: charger['ChargerType']?.toString() ?? '',
    );
  }

  @override
  Future<ChargingPaymentHistoryDetail?> fetchPaymentHistoryDetail({
    required String accountId,
    required String paymentId,
  }) async {
    final querySnap = await _firestore
        .collection('Customers')
        .doc(accountId)
        .collection('PaymentHistory')
        .where('Payment ID', isEqualTo: paymentId)
        .limit(1)
        .get();

    if (querySnap.docs.isEmpty) return null;

    final data = querySnap.docs.first.data();
    return ChargingPaymentHistoryDetail(
      totalCost: _parseDouble(data['TotalCost']),
      stationName: data['StationName']?.toString() ?? '',
      chargerName: data['ChargerName']?.toString() ?? '',
      chargerType: data['ChargerType']?.toString() ?? '',
      duration: data['Duration']?.toString() ?? '',
      paymentMethod: data['PaymentMethod']?.toString() ?? '',
      paymentId: data['Payment ID']?.toString() ?? '',
      paidTime: _parseNullableDateTime(data['Paid Time']),
    );
  }

  @override
  Future<String> createPaymentHistoryRecord({
    required ChargingPaymentHistoryDetails details,
    required String paymentMethod,
    required double totalAmount,
    DateTime? paidAt,
  }) async {
    final paymentId = 'PAY${DateTime.now().millisecondsSinceEpoch}';
    await _firestore
        .collection('Customers')
        .doc(details.customerId)
        .collection('PaymentHistory')
        .doc(paymentId)
        .set({
          'StationName': details.stationName,
          'ChargerName': details.chargerName,
          'ChargerType': details.chargerType,
          'Duration': details.duration,
          'TotalCost': double.parse(totalAmount.toStringAsFixed(2)),
          'PaymentMethod': paymentMethod,
          'Paid Time': paidAt ?? DateTime.now(),
          'Payment ID': paymentId,
        });

    return paymentId;
  }

  Future<String?> _fetchCurrentCustomerId() async {
    final customerSnapshot = await _fetchCurrentCustomerSnapshot();
    if (customerSnapshot == null) return null;

    return customerSnapshot.data()['CustomerID']?.toString() ??
        customerSnapshot.id;
  }

  Future<QueryDocumentSnapshot<Map<String, dynamic>>?>
  _fetchCurrentCustomerSnapshot() async {
    final phoneNumber = _auth.currentUser?.phoneNumber;
    if (phoneNumber == null || phoneNumber.isEmpty) return null;

    final querySnapshot = await _firestore
        .collection('Customers')
        .where('PhoneNumber', isEqualTo: phoneNumber)
        .limit(1)
        .get();
    if (querySnapshot.docs.isEmpty) return null;

    return querySnapshot.docs.first;
  }

  static double _parseDouble(Object? value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  static int _parseInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static DateTime? _parseNullableDateTime(Object? value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }
}
