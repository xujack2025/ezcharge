import 'package:flutter/foundation.dart';

import '../../core/utils/app_logger.dart';
import '../../models/profile_payment_card_model.dart';
import '../../services/profile_payment_service.dart';

enum AddCardResult { success, emptyFields, customerNotFound, duplicate, failed }

class AddCardViewModel extends ChangeNotifier {
  AddCardViewModel({ProfilePaymentServiceContract? paymentService})
    : _paymentService = paymentService ?? ProfilePaymentService();

  final ProfilePaymentServiceContract _paymentService;

  bool _isLoading = false;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<AddCardResult> addCard({
    required String cardNumber,
    required String expiredDate,
    required String cvv,
  }) async {
    final trimmedCardNumber = cardNumber.trim();
    final trimmedExpiredDate = expiredDate.trim();
    final trimmedCvv = cvv.trim();

    if (trimmedCardNumber.isEmpty ||
        trimmedExpiredDate.isEmpty ||
        trimmedCvv.isEmpty) {
      _errorMessage = 'Please fill in all fields!';
      notifyListeners();
      return AddCardResult.emptyFields;
    }

    _setLoading(true);
    _errorMessage = null;

    try {
      final status = await _paymentService.addPaymentCard(
        ProfilePaymentCardInput(
          cardNumber: trimmedCardNumber,
          expiredDate: trimmedExpiredDate,
          cvv: trimmedCvv,
        ),
      );

      switch (status) {
        case AddProfilePaymentCardStatus.success:
          return AddCardResult.success;
        case AddProfilePaymentCardStatus.customerNotFound:
          _errorMessage = 'Customer profile was not found.';
          return AddCardResult.customerNotFound;
        case AddProfilePaymentCardStatus.duplicate:
          _errorMessage = 'This card is already registered!';
          return AddCardResult.duplicate;
      }
    } catch (e) {
      AppLogger.error('Error adding card view state: $e');
      _errorMessage = 'Failed to add card. Try again!';
      return AddCardResult.failed;
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
