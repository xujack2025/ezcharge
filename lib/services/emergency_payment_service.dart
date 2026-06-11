import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/emergency_payment_model.dart';

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

class EmergencyPaymentService implements EmergencyPaymentServiceContract {
  EmergencyPaymentService({FirebaseAuth? auth, FirebaseFirestore? firestore})
    : _auth = auth ?? FirebaseAuth.instance,
      _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  @override
  Future<EmergencyPaymentProfile?> fetchPaymentProfile() async {
    final customerSnapshot = await _fetchCurrentCustomerSnapshot();
    if (customerSnapshot == null) return null;

    final customer = customerSnapshot.data();
    final customerId =
        customer['CustomerID']?.toString() ?? customerSnapshot.id;
    final paymentMethodSnapshot = await _firestore
        .collection('Customers')
        .doc(customerId)
        .collection('PaymentMethod')
        .limit(1)
        .get();

    return EmergencyPaymentProfile(
      customerId: customerId,
      walletBalance: _parseDouble(customer['WalletBalance']),
      pointBalance: _parseInt(customer['PointBalance']),
      cardNumber: paymentMethodSnapshot.docs.isEmpty
          ? null
          : paymentMethodSnapshot.docs.first.data()['CardNumber']?.toString(),
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
    if (customerId.isEmpty) {
      return const EmergencyPaymentProcessResult(
        status: EmergencyPaymentProcessStatus.customerNotFound,
        paymentMethodLabel: '',
        walletBalance: 0,
      );
    }

    final customerRef = _firestore.collection('Customers').doc(customerId);

    try {
      final result = await _firestore.runTransaction((transaction) async {
        final customerSnapshot = await transaction.get(customerRef);
        if (!customerSnapshot.exists) {
          return const EmergencyPaymentProcessResult(
            status: EmergencyPaymentProcessStatus.customerNotFound,
            paymentMethodLabel: '',
            walletBalance: 0,
          );
        }

        final customer = customerSnapshot.data() ?? {};
        final currentBalance = _parseDouble(customer['WalletBalance']);
        final currentPoints = _parseInt(customer['PointBalance']);
        final updates = <String, dynamic>{};
        var newBalance = currentBalance;

        if (method == EmergencyPaymentMethod.wallet) {
          if (currentBalance < totalAmount) {
            return EmergencyPaymentProcessResult(
              status: EmergencyPaymentProcessStatus.insufficientBalance,
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

        return EmergencyPaymentProcessResult(
          status: EmergencyPaymentProcessStatus.success,
          paymentMethodLabel: method == EmergencyPaymentMethod.wallet
              ? 'EZCHARGE Wallet'
              : 'Credit Card',
          walletBalance: newBalance,
        );
      });

      if (result.status == EmergencyPaymentProcessStatus.success) {
        await _completePaymentRequest(customerId);
      }

      return result;
    } catch (_) {
      return EmergencyPaymentProcessResult(
        status: EmergencyPaymentProcessStatus.failed,
        paymentMethodLabel: method == EmergencyPaymentMethod.wallet
            ? 'EZCHARGE Wallet'
            : 'Credit Card',
        walletBalance: 0,
      );
    }
  }

  @override
  Future<EmergencyPaymentSuccessDetails?> fetchSuccessDetails() async {
    final customerSnapshot = await _fetchCurrentCustomerSnapshot();
    if (customerSnapshot == null) return null;

    final customerId =
        customerSnapshot.data()['CustomerID']?.toString() ??
        customerSnapshot.id;
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
    final querySnap = await _firestore
        .collection('Customers')
        .doc(accountId)
        .collection('PaymentHistory')
        .where('Payment ID', isEqualTo: paymentId)
        .limit(1)
        .get();

    if (querySnap.docs.isEmpty) return null;

    final data = querySnap.docs.first.data();
    return EmergencyPaymentHistoryDetail(
      totalCost: _parseDouble(data['TotalCost']),
      duration: data['Duration']?.toString() ?? '',
      paymentMethod: data['PaymentMethod']?.toString() ?? '',
      paymentId: data['Payment ID']?.toString() ?? '',
      paidTime: _parseNullableDateTime(data['Paid Time']),
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
