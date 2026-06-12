import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/utils/app_logger.dart';
import '../models/profile_payment_card_model.dart';
import '../models/user_model.dart';
import 'auth_service.dart';

enum AddProfilePaymentCardStatus { success, customerNotFound, duplicate }

enum ProfileWalletTopUpStatus { success, customerNotFound }

enum ProfileReloadPinSendStatus { sent, customerNotFound, failed }

abstract class ProfilePaymentServiceContract {
  Future<ProfilePaymentMethodProfile?> fetchPaymentMethodProfile();

  Future<ProfilePaymentHistoryFeed?> watchPaymentHistory();

  Future<AddProfilePaymentCardStatus> addPaymentCard(
    ProfilePaymentCardInput card,
  );

  Future<ProfileWalletTopUpStatus> topUpWallet(double amount);

  Future<ProfileReloadPinSendStatus> sendReloadPin({
    required void Function(String verificationId) onCodeSent,
    required void Function() onVerificationCompleted,
  });

  Future<ProfileWalletTopUpStatus> verifyReloadPinAndTopUp({
    required String verificationId,
    required String otp,
    required double amount,
  });
}

class ProfilePaymentService implements ProfilePaymentServiceContract {
  ProfilePaymentService({
    AuthServiceContract? authService,
    FirebaseFirestore? firestore,
  }) : _authService = authService ?? AuthService(),
       _firestore = firestore ?? FirebaseFirestore.instance;

  final AuthServiceContract _authService;
  final FirebaseFirestore _firestore;

  @override
  Future<ProfilePaymentMethodProfile?> fetchPaymentMethodProfile() async {
    final customerId = await _authService.getCurrentCustomerId();
    if (customerId == null || customerId.isEmpty) {
      return null;
    }

    try {
      final customerDoc = await _firestore
          .collection('Customers')
          .doc(customerId)
          .get();
      if (!customerDoc.exists) {
        return null;
      }

      final customer = customerDoc.data() ?? {};
      final paymentMethodSnapshot = await _firestore
          .collection('Customers')
          .doc(customerId)
          .collection('PaymentMethod')
          .limit(1)
          .get();

      return ProfilePaymentMethodProfile(
        customerId: customerId,
        walletBalance: _parseDouble(customer['WalletBalance']),
        cardNumber: paymentMethodSnapshot.docs.isEmpty
            ? null
            : paymentMethodSnapshot.docs.first.data()['CardNumber']?.toString(),
      );
    } catch (e) {
      AppLogger.error('Error loading profile payment method: $e');
      rethrow;
    }
  }

  @override
  Future<ProfilePaymentHistoryFeed?> watchPaymentHistory() async {
    final customerId = await _authService.getCurrentCustomerId();
    if (customerId == null || customerId.isEmpty) {
      return null;
    }

    final stream = _firestore
        .collection('Customers')
        .doc(customerId)
        .collection('PaymentHistory')
        .orderBy('Paid Time', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => _paymentHistoryItem(doc.data()))
              .toList(),
        );

    return ProfilePaymentHistoryFeed(customerId: customerId, items: stream);
  }

  @override
  Future<AddProfilePaymentCardStatus> addPaymentCard(
    ProfilePaymentCardInput card,
  ) async {
    final customerId = await _authService.getCurrentCustomerId();
    if (customerId == null || customerId.isEmpty) {
      return AddProfilePaymentCardStatus.customerNotFound;
    }

    final paymentRef = _firestore
        .collection('Customers')
        .doc(customerId)
        .collection('PaymentMethod');

    try {
      final existingCards = await paymentRef
          .where('CardNumber', isEqualTo: card.cardNumber)
          .limit(1)
          .get();

      if (existingCards.docs.isNotEmpty) {
        return AddProfilePaymentCardStatus.duplicate;
      }

      final newCardId = 'PMM${DateTime.now().millisecondsSinceEpoch}';
      await paymentRef.doc(newCardId).set(card.toFirestore());
      AppLogger.info('Added payment card for customer: $customerId');
      return AddProfilePaymentCardStatus.success;
    } catch (e) {
      AppLogger.error('Error adding profile payment card: $e');
      rethrow;
    }
  }

  @override
  Future<ProfileWalletTopUpStatus> topUpWallet(double amount) async {
    final customerId = await _authService.getCurrentCustomerId();
    if (customerId == null || customerId.isEmpty) {
      return ProfileWalletTopUpStatus.customerNotFound;
    }

    final customerRef = _firestore.collection('Customers').doc(customerId);

    try {
      await _firestore.runTransaction((transaction) async {
        final customerSnapshot = await transaction.get(customerRef);
        if (!customerSnapshot.exists) {
          throw const _CustomerNotFoundException();
        }

        final customer = customerSnapshot.data() ?? {};
        final currentBalance = _parseDouble(customer['WalletBalance']);
        transaction.update(customerRef, {
          'WalletBalance': currentBalance + amount,
        });
      });

      AppLogger.info('Topped up wallet for customer: $customerId');
      return ProfileWalletTopUpStatus.success;
    } on _CustomerNotFoundException {
      return ProfileWalletTopUpStatus.customerNotFound;
    } catch (e) {
      AppLogger.error('Error topping up profile wallet: $e');
      rethrow;
    }
  }

  @override
  Future<ProfileReloadPinSendStatus> sendReloadPin({
    required void Function(String verificationId) onCodeSent,
    required void Function() onVerificationCompleted,
  }) async {
    final phoneNumber = _authService.getCurrentUserPhoneNumber();
    if (phoneNumber == null || phoneNumber.isEmpty) {
      return ProfileReloadPinSendStatus.customerNotFound;
    }

    try {
      var sendStatus = ProfileReloadPinSendStatus.sent;
      await _authService.sendOtp(
        phoneNumber,
        UserRole.customer,
        onCodeSent: onCodeSent,
        onVerificationCompleted: onVerificationCompleted,
        onError: (message) {
          AppLogger.error('Error sending reload pin: $message');
          sendStatus = ProfileReloadPinSendStatus.failed;
        },
      );
      return sendStatus;
    } catch (e) {
      AppLogger.error('Error sending reload pin: $e');
      return ProfileReloadPinSendStatus.failed;
    }
  }

  @override
  Future<ProfileWalletTopUpStatus> verifyReloadPinAndTopUp({
    required String verificationId,
    required String otp,
    required double amount,
  }) async {
    await _authService.signInWithOtp(verificationId, otp);
    return topUpWallet(amount);
  }

  double _parseDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  DateTime? _parseNullableDateTime(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }

  ProfilePaymentHistoryItem _paymentHistoryItem(Map<String, dynamic> data) {
    return ProfilePaymentHistoryItem(
      paymentId: data['Payment ID']?.toString() ?? '',
      stationName: data['StationName']?.toString() ?? '-',
      chargerName: data['ChargerName']?.toString() ?? '-',
      chargerType: data['ChargerType']?.toString() ?? '-',
      duration: data['Duration']?.toString() ?? '',
      paymentMethod: data['PaymentMethod']?.toString() ?? '',
      totalCost: _parseDouble(data['TotalCost']),
      paidTime: _parseNullableDateTime(data['Paid Time']),
    );
  }
}

class _CustomerNotFoundException implements Exception {
  const _CustomerNotFoundException();
}
