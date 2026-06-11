import 'package:flutter/foundation.dart';

import '../../core/utils/app_logger.dart';
import '../../models/charging_checkout_model.dart';
import '../../services/charging_checkout_service.dart';

enum ChargingCheckoutResult { success, notEnded, noReservation, failed }

class ChargingCheckoutViewModel extends ChangeNotifier {
  ChargingCheckoutViewModel({ChargingCheckoutServiceContract? checkoutService})
    : _checkoutService = checkoutService ?? ChargingCheckoutService();

  final ChargingCheckoutServiceContract _checkoutService;

  ChargingCheckoutDetails? _details;
  bool _isLoading = false;
  bool _isCheckingOut = false;
  String? _errorMessage;

  ChargingCheckoutDetails? get details => _details;
  bool get isLoading => _isLoading;
  bool get isCheckingOut => _isCheckingOut;
  String? get errorMessage => _errorMessage;

  String get stationName => _details?.stationName ?? '';
  String get chargerName => _details?.chargerName ?? '';
  String get chargerType => _details?.chargerType ?? '';
  double get pricePerVoltage => _details?.pricePerVoltage ?? 0;
  DateTime get startTime => _details?.startTime ?? DateTime.now();

  double chargingCostFor(Duration duration) {
    final details = _details;
    if (details == null) return 0;

    final hours = duration.inSeconds / 3600;
    return hours * details.pricePerVoltage * details.chargerVoltage;
  }

  Future<void> load() async {
    _setLoading(true);
    _errorMessage = null;

    try {
      _details = await _checkoutService.fetchCheckoutDetails();
      if (_details == null) {
        _errorMessage = 'No active reservation found.';
      }
    } catch (e) {
      AppLogger.error('Error loading checkout details: $e');
      _details = null;
      _errorMessage = 'Failed to load checkout details.';
    } finally {
      _setLoading(false);
    }
  }

  Future<ChargingCheckoutResult> checkOut({
    required Duration duration,
    required String durationText,
    required double penaltyCost,
  }) async {
    final details = _details;
    if (details == null) {
      return ChargingCheckoutResult.noReservation;
    }

    if (!details.canCheckOut) {
      return ChargingCheckoutResult.notEnded;
    }

    _setCheckingOut(true);
    _errorMessage = null;

    try {
      await _checkoutService.createAttendanceRecord(
        details: details,
        duration: durationText,
        chargingCost: chargingCostFor(duration),
        penaltyCost: penaltyCost,
      );
      return ChargingCheckoutResult.success;
    } catch (e) {
      AppLogger.error('Error creating attendance record: $e');
      _errorMessage = 'Check-out failed. Try again!';
      return ChargingCheckoutResult.failed;
    } finally {
      _setCheckingOut(false);
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setCheckingOut(bool value) {
    _isCheckingOut = value;
    notifyListeners();
  }
}
