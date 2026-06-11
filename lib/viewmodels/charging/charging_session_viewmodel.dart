import 'package:flutter/foundation.dart';

import '../../core/utils/app_logger.dart';
import '../../models/charging_session_model.dart';
import '../../services/charging_session_service.dart';

enum ChargingSessionEndResult { success, noSession, failed }

class ChargingSessionViewModel extends ChangeNotifier {
  ChargingSessionViewModel({ChargingSessionServiceContract? sessionService})
    : _sessionService = sessionService ?? ChargingSessionService();

  final ChargingSessionServiceContract _sessionService;

  ChargingSessionInfo? _session;
  bool _isLoading = false;
  bool _isEnding = false;
  String? _errorMessage;

  ChargingSessionInfo? get session => _session;
  bool get isLoading => _isLoading;
  bool get isEnding => _isEnding;
  String? get errorMessage => _errorMessage;
  String get chargerName => _session?.chargerName ?? "";
  String get chargerType => _session?.chargerType ?? "";
  String get stationName => _session?.stationName ?? "";

  Future<void> load() async {
    _setLoading(true);
    _errorMessage = null;

    try {
      _session = await _sessionService.fetchCurrentSession();
    } catch (e) {
      AppLogger.error("Error loading charging session: $e");
      _session = null;
      _errorMessage = "Failed to load charging session.";
    } finally {
      _setLoading(false);
    }
  }

  Future<ChargingSessionEndResult> endSession() async {
    final customerId = _session?.customerId;
    if (customerId == null || customerId.isEmpty) {
      return ChargingSessionEndResult.noSession;
    }

    _setEnding(true);
    _errorMessage = null;

    try {
      await _sessionService.endReservation(customerId);
      return ChargingSessionEndResult.success;
    } catch (e) {
      AppLogger.error("Error ending charging session: $e");
      _errorMessage = "Failed to end charging session.";
      return ChargingSessionEndResult.failed;
    } finally {
      _setEnding(false);
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setEnding(bool value) {
    _isEnding = value;
    notifyListeners();
  }
}
