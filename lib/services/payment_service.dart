import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/charging_checkout_model.dart';
import '../models/emergency_payment_model.dart';
import 'auth_service.dart';

/// Base class carrying all shared payment Firestore operations.
abstract class BasePaymentService {
  BasePaymentService({
    FirebaseFirestore? firestore,
    AuthServiceContract? authService,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _authService = authService ?? AuthService();

  final FirebaseFirestore _firestore;
  final AuthServiceContract _authService;

  /// Fetch user profile details (balances and card info) from Firestore.
  Future<Map<String, dynamic>?> fetchRawPaymentProfile() async {
    final customerId = await _authService.getCurrentCustomerId();
    if (customerId == null || customerId.isEmpty) return null;

    final customerDoc = await _firestore
        .collection('Customers')
        .doc(customerId)
        .get();
    if (!customerDoc.exists) return null;

    final customer = customerDoc.data() ?? {};
    final paymentMethodSnapshot = await _firestore
        .collection('Customers')
        .doc(customerId)
        .collection('PaymentMethod')
        .limit(1)
        .get();

    return {
      'customerId': customerId,
      'walletBalance': customer['WalletBalance'],
      'pointBalance': customer['PointBalance'],
      'cardNumber': paymentMethodSnapshot.docs.isEmpty
          ? null
          : paymentMethodSnapshot.docs.first.data()['CardNumber']?.toString(),
    };
  }

  /// Transaction-based payment deduction & rewards application.
  Future<Map<String, dynamic>> executePaymentTransaction({
    required String customerId,
    required double totalAmount,
    required bool isWallet,
    required String rewardId,
    required int rewardPoints,
  }) async {
    if (customerId.isEmpty) {
      return {'status': 'customerNotFound', 'walletBalance': 0.0};
    }

    final customerRef = _firestore.collection('Customers').doc(customerId);

    try {
      return await _firestore.runTransaction((transaction) async {
        final customerSnapshot = await transaction.get(customerRef);
        if (!customerSnapshot.exists) {
          return {'status': 'customerNotFound', 'walletBalance': 0.0};
        }

        final customer = customerSnapshot.data() ?? {};
        final currentBalance = _parseDouble(customer['WalletBalance']);
        final currentPoints = _parseInt(customer['PointBalance']);
        final updates = <String, dynamic>{};
        var newBalance = currentBalance;

        if (isWallet) {
          if (currentBalance < totalAmount) {
            return {
              'status': 'insufficientBalance',
              'walletBalance': currentBalance,
            };
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

        return {'status': 'success', 'walletBalance': newBalance};
      });
    } catch (_) {
      return {'status': 'failed', 'walletBalance': 0.0};
    }
  }

  /// Retrieve raw receipt record from the Customers PaymentHistory collection.
  Future<Map<String, dynamic>?> fetchRawPaymentHistoryDetail({
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
    return querySnap.docs.first.data();
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

/// Interface contract for Charging Payment Service.
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

/// Consolidated Charging Payment implementation leveraging BasePaymentService.
class ChargingPaymentService extends BasePaymentService
    implements ChargingPaymentServiceContract {
  ChargingPaymentService({super.firestore, super.authService});

  @override
  Future<ChargingPaymentSummaryDetails?> fetchPaymentSummaryDetails() async {
    final customerId = await _authService.getCurrentCustomerId();
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
    final data = await fetchRawPaymentProfile();
    if (data == null) return null;

    return ChargingPaymentProfile(
      customerId: data['customerId'],
      walletBalance: BasePaymentService._parseDouble(data['walletBalance']),
      pointBalance: BasePaymentService._parseInt(data['pointBalance']),
      cardNumber: data['cardNumber'],
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
    final isWallet = method == ChargingPaymentMethod.wallet;
    final result = await executePaymentTransaction(
      customerId: customerId,
      totalAmount: totalAmount,
      isWallet: isWallet,
      rewardId: rewardId,
      rewardPoints: rewardPoints,
    );

    final statusStr = result['status'] as String;
    final walletBalance = result['walletBalance'] as double;
    final paymentMethodLabel = isWallet ? 'EZCHARGE Wallet' : 'Credit Card';

    ChargingPaymentProcessStatus status;
    switch (statusStr) {
      case 'success':
        status = ChargingPaymentProcessStatus.success;
        break;
      case 'insufficientBalance':
        status = ChargingPaymentProcessStatus.insufficientBalance;
        break;
      case 'customerNotFound':
        status = ChargingPaymentProcessStatus.customerNotFound;
        break;
      default:
        status = ChargingPaymentProcessStatus.failed;
    }

    return ChargingPaymentProcessResult(
      status: status,
      paymentMethodLabel: paymentMethodLabel,
      walletBalance: walletBalance,
    );
  }

  @override
  Future<ChargingPaymentHistoryDetails?> fetchPaymentHistoryDetails() async {
    final customerId = await _authService.getCurrentCustomerId();
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
    final data = await fetchRawPaymentHistoryDetail(
      accountId: accountId,
      paymentId: paymentId,
    );
    if (data == null) return null;

    return ChargingPaymentHistoryDetail(
      totalCost: BasePaymentService._parseDouble(data['TotalCost']),
      stationName: data['StationName']?.toString() ?? '',
      chargerName: data['ChargerName']?.toString() ?? '',
      chargerType: data['ChargerType']?.toString() ?? '',
      duration: data['Duration']?.toString() ?? '',
      paymentMethod: data['PaymentMethod']?.toString() ?? '',
      paymentId: data['Payment ID']?.toString() ?? '',
      paidTime: BasePaymentService._parseNullableDateTime(data['Paid Time']),
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
}

/// Interface contract for Emergency Payment Service.
abstract class EmergencyPaymentServiceContract {
  Future<EmergencyPaymentProfile?> fetchPaymentProfile();

  Future<EmergencyPaymentProcessResult> processPayment({
    required String customerId,
    required double totalAmount,
    required EmergencyPaymentMethod method,
    required String rewardId,
    required int rewardPoints,
  });

  Future<EmergencyPaymentSuccessDetails?> fetchSuccessDetails();

  Future<String> createPaymentHistoryRecord({
    required EmergencyPaymentSuccessDetails details,
    required String paymentMethod,
    required double totalAmount,
    DateTime? paidAt,
  });

  Future<EmergencyPaymentHistoryDetail?> fetchPaymentHistoryDetail({
    required String accountId,
    required String paymentId,
  });
}

/// Consolidated Emergency Payment implementation leveraging BasePaymentService.
class EmergencyPaymentService extends BasePaymentService
    implements EmergencyPaymentServiceContract {
  EmergencyPaymentService({super.firestore, super.authService});

  @override
  Future<EmergencyPaymentProfile?> fetchPaymentProfile() async {
    final data = await fetchRawPaymentProfile();
    if (data == null) return null;

    return EmergencyPaymentProfile(
      customerId: data['customerId'],
      walletBalance: BasePaymentService._parseDouble(data['walletBalance']),
      pointBalance: BasePaymentService._parseInt(data['pointBalance']),
      cardNumber: data['cardNumber'],
    );
  }

  @override
  Future<EmergencyPaymentProcessResult> processPayment({
    required String customerId,
    required double totalAmount,
    required EmergencyPaymentMethod method,
    required String rewardId,
    required int rewardPoints,
  }) async {
    final isWallet = method == EmergencyPaymentMethod.wallet;
    final result = await executePaymentTransaction(
      customerId: customerId,
      totalAmount: totalAmount,
      isWallet: isWallet,
      rewardId: rewardId,
      rewardPoints: rewardPoints,
    );

    final statusStr = result['status'] as String;
    final walletBalance = result['walletBalance'] as double;
    final paymentMethodLabel = isWallet ? 'EZCHARGE Wallet' : 'Credit Card';

    EmergencyPaymentProcessStatus status;
    switch (statusStr) {
      case 'success':
        status = EmergencyPaymentProcessStatus.success;
        break;
      case 'insufficientBalance':
        status = EmergencyPaymentProcessStatus.insufficientBalance;
        break;
      case 'customerNotFound':
        status = EmergencyPaymentProcessStatus.customerNotFound;
        break;
      default:
        status = EmergencyPaymentProcessStatus.failed;
    }

    if (status == EmergencyPaymentProcessStatus.success) {
      await _completePaymentRequest(customerId);
    }

    return EmergencyPaymentProcessResult(
      status: status,
      paymentMethodLabel: paymentMethodLabel,
      walletBalance: walletBalance,
    );
  }

  @override
  Future<EmergencyPaymentSuccessDetails?> fetchSuccessDetails() async {
    final customerId = await _authService.getCurrentCustomerId();
    if (customerId == null || customerId.isEmpty) return null;

    final requestSnapshot = await _firestore
        .collection('EmergencyRequests')
        .where('CustomerID', isEqualTo: customerId)
        .limit(1)
        .get();
    if (requestSnapshot.docs.isEmpty) return null;

    final data = requestSnapshot.docs.first.data();
    return EmergencyPaymentSuccessDetails(
      customerId: customerId,
      requestId: data['RequestID']?.toString() ?? requestSnapshot.docs.first.id,
      duration: data['chargingFormattedTime']?.toString() ?? '',
    );
  }

  @override
  Future<String> createPaymentHistoryRecord({
    required EmergencyPaymentSuccessDetails details,
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
          'Duration': details.duration,
          'TotalCost': double.parse(totalAmount.toStringAsFixed(2)),
          'PaymentMethod': paymentMethod,
          'Paid Time': paidAt ?? DateTime.now(),
          'Payment ID': paymentId,
        });

    return paymentId;
  }

  @override
  Future<EmergencyPaymentHistoryDetail?> fetchPaymentHistoryDetail({
    required String accountId,
    required String paymentId,
  }) async {
    final data = await fetchRawPaymentHistoryDetail(
      accountId: accountId,
      paymentId: paymentId,
    );
    if (data == null) return null;

    return EmergencyPaymentHistoryDetail(
      totalCost: BasePaymentService._parseDouble(data['TotalCost']),
      duration: data['Duration']?.toString() ?? '',
      paymentMethod: data['PaymentMethod']?.toString() ?? '',
      paymentId: data['Payment ID']?.toString() ?? '',
      paidTime: BasePaymentService._parseNullableDateTime(data['Paid Time']),
    );
  }

  Future<void> _completePaymentRequest(String customerId) async {
    final snapshot = await _firestore
        .collection('EmergencyRequests')
        .where('CustomerID', isEqualTo: customerId)
        .where('Status', isEqualTo: 'Payment')
        .limit(1)
        .get();
    if (snapshot.docs.isEmpty) return;

    await snapshot.docs.first.reference.update({'Status': 'Completed'});
  }
}
