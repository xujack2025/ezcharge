import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../../../models/location_search_model.dart';
import '../../../../viewmodels/emergency_request_viewmodel.dart';

class EmergencyRequestView extends StatefulWidget {
  const EmergencyRequestView({super.key});

  @override
  EmergencyRequestViewState createState() => EmergencyRequestViewState();
}

class EmergencyRequestViewState extends State<EmergencyRequestView> {
  final Completer<GoogleMapController> _controller = Completer();
  final TextEditingController _locationController = TextEditingController();
  final List<String> _bookingReasons = [
    "Running Out of Charge",
    "Far from Charging Station",
    "Nearby Charging Port Occupied",
  ];

  String? _selectedReason;
  LatLng _selectedLocation = const LatLng(3.219792, 101.643793);
  bool isLoading = true;
  List<LocationSuggestion> _suggestions = [];
  Marker? _userMarker;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _initializeData();
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _initializeData() async {
    final requestViewModel = context.read<EmergencyRequestViewModel>();
    await Future.wait([
      requestViewModel.loadRequestFormData(),
      _getUserLocation(),
    ]);
    if (!mounted) return;
    setState(() => isLoading = false);
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _fetchAddressSuggestions(query);
    });
  }

  Future<void> _getUserLocation() async {
    if (mounted) {
      setState(() => isLoading = true);
    }

    final requestViewModel = context.read<EmergencyRequestViewModel>();
    final selection = await requestViewModel.loadCurrentLocationSelection();
    if (!mounted) return;

    if (selection == null) {
      setState(() => isLoading = false);
      _promptManualLocationEntry();
      return;
    }

    _selectedLocation = selection.location;
    _locationController.text = selection.address;
    _updateMarker(_selectedLocation);
    setState(() => isLoading = false);

    final controller = await _controller.future;
    if (!mounted) return;
    controller.animateCamera(
      CameraUpdate.newLatLngZoom(_selectedLocation, 14.0),
    );
  }

  void _promptManualLocationEntry() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Location Not Found"),
        content: const Text(
          "We couldn't detect your location. Please enter your address manually.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  Future<void> _fetchAddressSuggestions(String query) async {
    if (query.isEmpty) {
      setState(() => _suggestions = []);
      return;
    }

    setState(() => isLoading = true);
    final requestViewModel = context.read<EmergencyRequestViewModel>();
    final suggestions = await requestViewModel.fetchAddressSuggestions(query);
    if (!mounted) return;

    setState(() {
      _suggestions = suggestions;
      isLoading = false;
    });
  }

  Future<void> _selectAddress(LocationSuggestion suggestion) async {
    final requestViewModel = context.read<EmergencyRequestViewModel>();
    final selection = await requestViewModel.selectAddress(
      placeId: suggestion.placeId,
      description: suggestion.description,
    );
    if (!mounted || selection == null) return;

    setState(() {
      _selectedLocation = selection.location;
      _locationController.text = selection.address;
      _updateMarker(_selectedLocation);
      _suggestions = [];
    });

    final controller = await _controller.future;
    if (!mounted) return;
    controller.animateCamera(
      CameraUpdate.newLatLngZoom(_selectedLocation, 14.0),
    );
  }

  Future<void> _onMapTap(LatLng position) async {
    setState(() {
      _selectedLocation = position;
      _updateMarker(position);
    });

    final requestViewModel = context.read<EmergencyRequestViewModel>();
    final address = await requestViewModel.addressForLocation(position);
    if (!mounted || address == null) return;

    setState(() {
      _locationController.text = address;
    });
  }

  void _updateMarker(LatLng position) {
    _userMarker = Marker(
      markerId: const MarkerId("user_selected"),
      position: position,
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
    );
  }

  Future<void> _submitRequest(
    EmergencyRequestViewModel requestViewModel,
  ) async {
    final result = await requestViewModel.submitEmergencyRequest(
      customerId: requestViewModel.customerId,
      location: _selectedLocation,
      address: _locationController.text,
      bookingReason: _selectedReason,
    );
    if (!mounted) return;

    switch (result) {
      case EmergencyRequestSubmitResult.success:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Request submitted successfully!")),
        );
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) Navigator.pop(context);
        });
        return;
      case EmergencyRequestSubmitResult.missingCustomer:
      case EmergencyRequestSubmitResult.missingDetails:
      case EmergencyRequestSubmitResult.failed:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              requestViewModel.errorMessage ??
                  "Failed to submit request. Try again.",
            ),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final requestViewModel = context.watch<EmergencyRequestViewModel>();
    final isBusy = isLoading || requestViewModel.isLoading;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Emergency Request",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            flex: 1,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Enter Location",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 5),
                  TextField(
                    controller: _locationController,
                    onChanged: _onSearchChanged,
                    decoration: InputDecoration(
                      hintText: "Search for location",
                      filled: true,
                      fillColor: Colors.grey[200],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      suffixIcon: const Icon(
                        Icons.location_on,
                        color: Colors.blue,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (_suggestions.isNotEmpty)
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(5),
                        boxShadow: const [
                          BoxShadow(color: Colors.black26, blurRadius: 5),
                        ],
                      ),
                      child: Column(
                        children: _suggestions.map((suggestion) {
                          return ListTile(
                            leading: const Icon(
                              Icons.location_on,
                              color: Colors.blue,
                            ),
                            title: Text(suggestion.description),
                            onTap: () => _selectAddress(suggestion),
                          );
                        }).toList(),
                      ),
                    ),
                  const SizedBox(height: 10),
                  const Text(
                    "Select Booking Reason",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 5),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedReason,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.grey[200],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    items: _bookingReasons
                        .map(
                          (reason) => DropdownMenuItem(
                            value: reason,
                            child: Text(reason),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedReason = value;
                      });
                    },
                  ),
                  const SizedBox(height: 10),
                  ListTile(
                    title: Text(
                      requestViewModel.scheduledDateTime != null
                          ? "Scheduled Time: ${requestViewModel.scheduledDateTime}"
                          : "Schedule Time",
                    ),
                    trailing: const Icon(Icons.access_time),
                    onTap: () => requestViewModel.pickDateTime(context),
                  ),
                  const SizedBox(height: 10),
                  requestViewModel.selectedImage == null
                      ? ElevatedButton.icon(
                          onPressed: () =>
                              requestViewModel.pickImage(ImageSource.gallery),
                          icon: const Icon(Icons.image),
                          label: const Text("Upload Image"),
                        )
                      : Image.file(
                          requestViewModel.selectedImage!,
                          height: 150,
                        ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed:
                          (requestViewModel.activeRequestExists || isBusy)
                          ? null
                          : () => _submitRequest(requestViewModel),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        textStyle: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      child: isBusy
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Text(
                              requestViewModel.activeRequestExists
                                  ? "Active Request in Progress"
                                  : "Confirm Order",
                            ),
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            ),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: GoogleMap(
                onTap: _onMapTap,
                markers: _userMarker != null ? {_userMarker!} : {},
                initialCameraPosition: CameraPosition(
                  target: _selectedLocation,
                  zoom: 14.0,
                ),
                onMapCreated: (GoogleMapController controller) {
                  if (!_controller.isCompleted) {
                    _controller.complete(controller);
                  }
                },
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _getUserLocation,
        backgroundColor: Colors.blue,
        child: const Icon(Icons.my_location, size: 30, color: Colors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
