import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../core/utils/app_logger.dart';
import '../../models/profile_payment_card_model.dart';
import '../../services/profile_payment_service.dart';

class PaymentHistoryViewModel extends ChangeNotifier {
  PaymentHistoryViewModel({ProfilePaymentServiceContract? paymentService})
    : _paymentService = paymentService ?? ProfilePaymentService();

  final ProfilePaymentServiceContract _paymentService;

  StreamSubscription<List<ProfilePaymentHistoryItem>>? _historySubscription;
  List<ProfilePaymentHistoryItem> _items = const [];
  bool _isLoading = false;
  String? _errorMessage;
  String _customerId = '';

  List<ProfilePaymentHistoryItem> get items => _items;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get customerId => _customerId;
  bool get hasCustomer => _customerId.isNotEmpty;

  Future<void> loadPaymentHistory() async {
    _setLoading(true);
    _errorMessage = null;
    await _historySubscription?.cancel();

    try {
      final feed = await _paymentService.watchPaymentHistory();
      if (feed == null) {
        _customerId = '';
        _items = const [];
        _errorMessage = 'No account ID found.';
        _setLoading(false);
        return;
      }

      _customerId = feed.customerId;
      _historySubscription = feed.items.listen(
        (items) {
          _items = items;
          _errorMessage = null;
          _setLoading(false);
        },
        onError: (Object error) {
          AppLogger.error('Error loading payment history stream: $error');
          _items = const [];
          _errorMessage = 'Error loading payment history.';
          _setLoading(false);
        },
      );
    } catch (e) {
      AppLogger.error('Error loading payment history view state: $e');
      _customerId = '';
      _items = const [];
      _errorMessage = 'Error loading payment history.';
      _setLoading(false);
    }
  }

  @override
  void dispose() {
    _historySubscription?.cancel();
    super.dispose();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
