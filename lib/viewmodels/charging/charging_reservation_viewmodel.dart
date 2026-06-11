import 'package:flutter/foundation.dart';

import '../../core/utils/app_logger.dart';
import '../../models/charging_reservation_charger_model.dart';
import '../../services/charging_reservation_service.dart';

enum ChargingReservationTimeResult {
  selected,
  noChargerSelected,
  slotTaken,
  failed,
}

enum ChargingReservationSubmitResult {
  success,
  noChargerSelected,
  termsNotAccepted,
  customerNotFound,
  failed,
}

class ChargingReservationViewModel extends ChangeNotifier {
  ChargingReservationViewModel({
    ChargingReservationServiceContract? reservationService,
  }) : _reservationService = reservationService ?? ChargingReservationService();

  final ChargingReservationServiceContract _reservationService;

  List<ChargingReservationCharger> _chargers = [];
  String? _selectedChargerId;
  DateTime _selectedTime = DateTime.now();
  bool _isTermsAccepted = false;
  bool _isLoading = false;
  bool _isSubmitting = false;
  String? _customerId;
  String? _errorMessage;

  List<ChargingReservationCharger> get chargers => List.unmodifiable(_chargers);
  String? get selectedChargerId => _selectedChargerId;
  DateTime get selectedTime => _selectedTime;
  bool get isTermsAccepted => _isTermsAccepted;
  bool get isLoading => _isLoading;
  bool get isSubmitting => _isSubmitting;
  String? get errorMessage => _errorMessage;
  bool get canSubmit =>
      _selectedChargerId != null && _isTermsAccepted && !_isSubmitting;

  Future<void> load(String stationId) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      final results = await Future.wait<Object?>([
        _reservationService.getCurrentCustomerId(),
        _reservationService.fetchChargers(stationId),
      ]);

      _customerId = results[0] as String?;
      _chargers = results[1] as List<ChargingReservationCharger>;
    } catch (e) {
      AppLogger.error("Error loading reservation options: $e");
      _errorMessage = "Failed to load chargers.";
      _chargers = [];
    } finally {
      _setLoading(false);
    }
  }

  void selectCharger(String chargerId) {
    if (_selectedChargerId == chargerId) {
      return;
    }

    _selectedChargerId = chargerId;
    notifyListeners();
  }

  void setTermsAccepted(bool value) {
    if (_isTermsAccepted == value) {
      return;
    }

    _isTermsAccepted = value;
    notifyListeners();
  }

  Future<ChargingReservationTimeResult> selectStartTime(
    DateTime startTime,
  ) async {
    final chargerId = _selectedChargerId;
    if (chargerId == null) {
      return ChargingReservationTimeResult.noChargerSelected;
    }

    try {
      final isTaken = await _reservationService.isSlotTaken(
        chargerId: chargerId,
        startTime: startTime,
      );

      if (isTaken) {
        return ChargingReservationTimeResult.slotTaken;
      }

      _selectedTime = startTime;
      notifyListeners();
      return ChargingReservationTimeResult.selected;
    } catch (e) {
      AppLogger.error("Error checking reservation slot: $e");
      _errorMessage = "Failed to check reservation slot.";
      notifyListeners();
      return ChargingReservationTimeResult.failed;
    }
  }

  Future<ChargingReservationSubmitResult> submitReservation(
    String stationId,
  ) async {
    final chargerId = _selectedChargerId;
    if (chargerId == null) {
      return ChargingReservationSubmitResult.noChargerSelected;
    }

    if (!_isTermsAccepted) {
      return ChargingReservationSubmitResult.termsNotAccepted;
    }

    final customerId = _customerId;
    if (customerId == null || customerId.isEmpty) {
      return ChargingReservationSubmitResult.customerNotFound;
    }

    _setSubmitting(true);
    _errorMessage = null;

    try {
      await _reservationService.createReservation(
        customerId: customerId,
        stationId: stationId,
        chargerId: chargerId,
        startTime: _selectedTime,
      );
      return ChargingReservationSubmitResult.success;
    } catch (e) {
      AppLogger.error("Error submitting reservation: $e");
      _errorMessage = "Failed to reserve the charger.";
      return ChargingReservationSubmitResult.failed;
    } finally {
      _setSubmitting(false);
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setSubmitting(bool value) {
    _isSubmitting = value;
    notifyListeners();
  }
}
