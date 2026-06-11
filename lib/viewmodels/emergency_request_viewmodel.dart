import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_picker/image_picker.dart';

import '../core/utils/app_logger.dart';
import '../models/emergency_request_model.dart';
import '../models/location_search_model.dart';
import '../services/emergency_request_service.dart';
import '../services/location_search_service.dart';
import '../services/location_service.dart';

enum EmergencyRequestSubmitResult {
  success,
  missingCustomer,
  missingDetails,
  failed,
}

class EmergencyRequestViewModel extends ChangeNotifier {
  EmergencyRequestViewModel({
    EmergencyRequestServiceContract? emergencyRequestService,
    LocationServiceContract? locationService,
    LocationSearchServiceContract? locationSearchService,
  }) : _emergencyRequestService =
           emergencyRequestService ?? EmergencyRequestService(),
       _locationService = locationService ?? LocationService(),
       _locationSearchService =
           locationSearchService ?? LocationSearchService();

  final EmergencyRequestServiceContract _emergencyRequestService;
  final LocationServiceContract _locationService;
  final LocationSearchServiceContract _locationSearchService;

  File? selectedImage;
  String? uploadedImageUrl;
  DateTime? scheduledDateTime;
  bool isLoading = false;
  bool activeRequestExists = false;
  String? imageUrl;
  String? requestID;
  String? customerId;
  String? errorMessage;
  Stream<String?>? _driverAssignmentStream;
  StreamSubscription<ActiveEmergencyRequest>? _activeRequestSubscription;

  Stream<String?>? get driverAssignmentStream => _driverAssignmentStream;

  /// Get Emergency Requests as a Stream (Real-time Updates)
  Stream<List<EmergencyRequest>> getRequests(String customerID) {
    return _emergencyRequestService.watchRequests(customerID);
  }

  Future<void> loadRequestFormData() async {
    _setLoading(true);
    errorMessage = null;

    await Future.wait([loadCurrentCustomerId(), listenForActiveRequest()]);

    _setLoading(false);
  }

  Future<void> loadCurrentCustomerId() async {
    _setLoading(true);
    errorMessage = null;

    try {
      final phoneNumber = _emergencyRequestService.getCurrentUserPhoneNumber();
      if (phoneNumber == null || phoneNumber.isEmpty) {
        customerId = null;
        errorMessage = "No customer profile was found.";
        return;
      }

      customerId = await _emergencyRequestService.getCustomerIdByPhoneNumber(
        phoneNumber,
      );
      if (customerId == null || customerId!.isEmpty) {
        errorMessage = "No customer profile was found.";
      }
    } catch (e) {
      AppLogger.error("Error loading emergency request customer: $e");
      customerId = null;
      errorMessage = "Failed to load request history.";
    } finally {
      _setLoading(false);
    }
  }

  /// Create Emergency Request
  Future<void> createRequest(EmergencyRequest request) async {
    try {
      // Generate a unique request ID in the format: EMQ_<timestamp>
      String requestID = "EMQ${DateTime.now().millisecondsSinceEpoch}";

      // Ensure request ID is updated before saving
      request = EmergencyRequest(
        requestID: requestID,
        customerID: request.customerID,
        location: request.location,
        address: request.address,
        bookingReason: request.bookingReason,
        preferredTime: request.preferredTime,
        status: request.status,
        imageUrl: request.imageUrl,
      );

      await _emergencyRequestService.createRequest(request);

      AppLogger.info("Emergency request created successfully: $requestID");
    } catch (e) {
      AppLogger.error("Error creating request: $e");
      errorMessage = "Failed to create emergency request.";
      notifyListeners();
    }
  }

  Future<EmergencyRequestSubmitResult> submitEmergencyRequest({
    required String? customerId,
    required LatLng location,
    required String address,
    required String? bookingReason,
  }) async {
    if (customerId == null || customerId.isEmpty) {
      errorMessage = "Customer ID not found. Please try again.";
      notifyListeners();
      return EmergencyRequestSubmitResult.missingCustomer;
    }

    if (bookingReason == null || bookingReason.isEmpty || address.isEmpty) {
      errorMessage = "Please fill in all details.";
      notifyListeners();
      return EmergencyRequestSubmitResult.missingDetails;
    }

    _setLoading(true);
    errorMessage = null;

    try {
      final imageUrl = await uploadImageToFirebase();
      final requestId = "EMQ${DateTime.now().millisecondsSinceEpoch}";
      final request = EmergencyRequest(
        requestID: requestId,
        customerID: customerId,
        location: GeoPoint(location.latitude, location.longitude),
        address: address,
        bookingReason: bookingReason,
        preferredTime: scheduledDateTime?.toString() ?? "",
        status: "Pending",
        imageUrl: imageUrl ?? "",
      );

      await _emergencyRequestService.createRequest(request);
      requestID = requestId;
      return EmergencyRequestSubmitResult.success;
    } catch (e) {
      AppLogger.error("Error submitting emergency request: $e");
      errorMessage = "Failed to submit request. Try again.";
      return EmergencyRequestSubmitResult.failed;
    } finally {
      _setLoading(false);
    }
  }

  /// Update Request Status (Real-time Changes)
  Future<void> updateRequestStatus(String requestID, String status) async {
    try {
      await _emergencyRequestService.updateRequestStatus(requestID, status);
    } catch (e) {
      AppLogger.error("Error updating status: $e");
      errorMessage = "Failed to update request status.";
      notifyListeners();
    }
  }

  /// Select Image (Gallery or Camera)
  Future<void> pickImage(ImageSource source) async {
    final pickedFile = await ImagePicker().pickImage(source: source);
    if (pickedFile != null) {
      selectedImage = File(pickedFile.path);
      uploadedImageUrl = null; // Reset URL (New Image Needs Upload)
      notifyListeners();
    }
  }

  Future<LocationSelection?> loadCurrentLocationSelection() async {
    try {
      final location = await _locationService.getCurrentLocation();
      if (location == null) return null;

      final address = await _locationSearchService.reverseGeocode(location);
      return LocationSelection(location: location, address: address ?? "");
    } catch (e) {
      AppLogger.error("Error loading current emergency request location: $e");
      errorMessage = "Failed to load current location.";
      notifyListeners();
      return null;
    }
  }

  Future<List<LocationSuggestion>> fetchAddressSuggestions(String query) async {
    try {
      return _locationSearchService.fetchAddressSuggestions(query);
    } catch (e) {
      AppLogger.error("Error loading address suggestions: $e");
      errorMessage = "Failed to load address suggestions.";
      notifyListeners();
      return [];
    }
  }

  Future<LocationSelection?> selectAddress({
    required String placeId,
    required String description,
  }) async {
    try {
      return _locationSearchService.fetchPlaceDetails(
        placeId: placeId,
        description: description,
      );
    } catch (e) {
      AppLogger.error("Error selecting address: $e");
      errorMessage = "Failed to select address.";
      notifyListeners();
      return null;
    }
  }

  Future<String?> addressForLocation(LatLng location) async {
    try {
      return _locationSearchService.reverseGeocode(location);
    } catch (e) {
      AppLogger.error("Error reverse geocoding emergency location: $e");
      return null;
    }
  }

  /// Upload Image to Firebase Storage
  Future<String?> uploadImageToFirebase() async {
    if (selectedImage == null) {
      AppLogger.warning("No image selected. Skipping upload.");
      return null;
    }

    try {
      isLoading = true;
      notifyListeners(); // Show loading state

      String imageUrl = await _emergencyRequestService.uploadRequestImage(
        selectedImage!,
      );
      uploadedImageUrl = imageUrl;

      AppLogger.info("Image uploaded successfully: $imageUrl");

      return imageUrl; // Return image URL for Firestore
    } catch (e) {
      AppLogger.error("Image Upload Error: $e");
      errorMessage = "Failed to upload image.";
      return null; // Handle failure case
    } finally {
      isLoading = false;
      notifyListeners(); // Ensure UI updates after upload (success or failure)
    }
  }

  /// Show DateTime Picker for Scheduling
  Future<void> pickDateTime(BuildContext context) async {
    DateTime now = DateTime.now().toUtc().add(const Duration(hours: 8));
    //DateTime now = DateTime.now().toUtc().add(const Duration(hours: 8)); // Convert to UTC+8
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 30)),
    );
    if (!context.mounted) return;
    if (pickedDate == null) return;

    TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (!context.mounted) return;
    if (pickedTime == null) return;

    scheduledDateTime = DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      pickedTime.hour,
      pickedTime.minute,
    );

    notifyListeners();
  }

  /// 🔹 **Calculate Fee**
  double calculateFee(double kWhUsed) {
    const double baseFee = 8.0;
    const double perKWhCharge = 1.5;
    return baseFee + (kWhUsed * perKWhCharge);
  }

  /// 🔹 **Update Status to Charging**
  Future<void> startCharging(String requestID) async {
    await _emergencyRequestService.startCharging(requestID);
  }

  /// 🔹 **Update Charging Completed & Set Payment Due**
  Future<void> updateChargingComplete(String requestID, double kWhUsed) async {
    await _emergencyRequestService.updateChargingComplete(requestID, kWhUsed);
  }

  /// 🔹 **Process Payment**
  Future<void> processPayment(String requestID) async {
    await _emergencyRequestService.processPayment(requestID);
  }

  Future<void> loadBookAChargeHome() async {
    _setLoading(true);
    errorMessage = null;

    await Future.wait([loadPowerBankImage(), listenForActiveRequest()]);

    _setLoading(false);
  }

  Future<void> loadPowerBankImage() async {
    try {
      imageUrl = await _emergencyRequestService.getPowerBankImageUrl();
      notifyListeners();
    } catch (e) {
      AppLogger.error("Error loading power bank image: $e");
      errorMessage = "Failed to load image.";
      notifyListeners();
    }
  }

  Future<void> listenForActiveRequest() async {
    try {
      final phoneNumber = _emergencyRequestService.getCurrentUserPhoneNumber();
      if (phoneNumber == null || phoneNumber.isEmpty) {
        activeRequestExists = false;
        requestID = null;
        return;
      }

      final customerId = await _emergencyRequestService
          .getCustomerIdByPhoneNumber(phoneNumber);
      if (customerId == null || customerId.isEmpty) {
        activeRequestExists = false;
        requestID = null;
        return;
      }

      await _activeRequestSubscription?.cancel();
      _activeRequestSubscription = _emergencyRequestService
          .watchActiveRequest(customerId)
          .listen((request) {
            activeRequestExists = request.exists;
            requestID = request.requestId;
            notifyListeners();
          });
    } catch (e) {
      AppLogger.error("Error checking active emergency request: $e");
      errorMessage = "Failed to check active request.";
      activeRequestExists = false;
      requestID = null;
      notifyListeners();
    }
  }

  Future<String?> getAssignedDriverId(String requestId) async {
    try {
      final driverId = await _emergencyRequestService.getDriverId(requestId);
      if (driverId == null) {
        errorMessage = "Request not found. Please try again.";
        notifyListeners();
        return null;
      }

      if (driverId == "Unknown" || driverId.isEmpty) {
        _driverAssignmentStream = _emergencyRequestService.watchDriverId(
          requestId,
        );
        notifyListeners();
        return null;
      }

      return driverId;
    } catch (e) {
      AppLogger.error("Error fetching request details: $e");
      errorMessage = "Error fetching request details.";
      notifyListeners();
      return null;
    }
  }

  void clearDriverAssignmentStream() {
    _driverAssignmentStream = null;
    notifyListeners();
  }

  void _setLoading(bool value) {
    isLoading = value;
    notifyListeners();
  }

  @override
  void dispose() {
    _activeRequestSubscription?.cancel();
    super.dispose();
  }
}
