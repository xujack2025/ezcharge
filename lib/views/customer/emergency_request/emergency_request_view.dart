import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:location/location.dart';
import 'package:provider/provider.dart';
import '../../../models/emergency_request_model.dart';
import '../../../viewmodels/emergency_request_viewmodel.dart';
import 'package:http/http.dart' as http;
import 'package:ezcharge/secrets.dart';

const String googleMapsApiKey = Secrets.googleMapsApiKey;

class EmergencyRequestView extends StatefulWidget {
  @override
  _EmergencyRequestViewState createState() => _EmergencyRequestViewState();
}

class _EmergencyRequestViewState extends State<EmergencyRequestView> {
  final Completer<GoogleMapController> _controller = Completer();
  final Location _location = Location();
  final TextEditingController _locationController = TextEditingController();
  final List<String> _bookingReasons = [
    "Running Out of Charge",
    "Far from Charging Station",
    "Nearby Charging Port Occupied",
  ];

  String? requestID;
  String? _selectedReason;
  String _preferredTime = "";
  String? customerID;

  LatLng _selectedLocation = const LatLng(3.219792, 101.643793); // Default KL
  bool isLoading = true, activeRequestExists = false;
  List<dynamic> _suggestions = [];
  Marker? _userMarker;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  /// 🔹 Initialize Data (Location, Customer ID, Active Request Check)
  Future<void> _initializeData() async {
    await Future.wait([_getUserLocation(), _fetchCustomerID()]);
    _checkActiveRequest();
    setState(() => isLoading = false);
  }

  // Function to check if there is an active request
  void _checkActiveRequest() {
    String? phoneNumber = FirebaseAuth.instance.currentUser?.phoneNumber;
    if (phoneNumber == null) {
      print("❌ No phone number found for user.");
      return;
    }

    FirebaseFirestore.instance
        .collection('customers')
        .where('PhoneNumber', isEqualTo: phoneNumber)
        .limit(1)
        .snapshots() // 🔹 Listen for real-time changes
        .listen((customerQuery) {
          if (customerQuery.docs.isEmpty) {
            print("❌ No customer found with this phone number.");
            return;
          }

          // ✅ Extract CustomerID
          String customerID = customerQuery.docs.first['CustomerID'];
          print("✅ Found CustomerID: $customerID");

          // ✅ Listen for active requests in real-time
          FirebaseFirestore.instance
              .collection('emergency_requests')
              .where('CustomerID', isEqualTo: customerID)
              .where(
                'status',
                whereIn: [
                  "Pending",
                  "Upcoming",
                  "Arrived",
                  "Charging",
                  "Payment",
                ],
              )
              .limit(1)
              .snapshots() // 🔹 Real-time listener for request updates
              .listen((activeRequests) {
                if (activeRequests.docs.isNotEmpty) {
                  // ✅ Extract active request ID
                  String fetchedRequestID = activeRequests.docs.first.id;
                  print("🔄 Request Updated! New requestID: $fetchedRequestID");

                  // ✅ Update state with the new request in real-time
                  if (mounted) {
                    setState(() {
                      activeRequestExists = true;
                      requestID = fetchedRequestID;
                      isLoading = false;
                    });
                  }
                } else {
                  print("✅ No active request found.");
                  if (mounted) {
                    setState(() {
                      activeRequestExists = false;
                      requestID = null;
                      isLoading = false;
                    });
                  }
                }
              });
        });
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _fetchAddressSuggestions(query);
    });
  }

  /// 🔹 Fetch customerID from Firestore
  Future<void> _fetchCustomerID() async {
    var phone = FirebaseAuth.instance.currentUser?.phoneNumber;
    if (phone == null) return;

    var query = await FirebaseFirestore.instance
        .collection('customers')
        .where('PhoneNumber', isEqualTo: phone)
        .limit(1)
        .get();

    if (query.docs.isNotEmpty) {
      setState(() => customerID = query.docs.first['CustomerID']);
    } else {
      print("❌ No customer document found.");
    }
  }

  /// 🔹 Get User's GPS Location
  Future<void> _getUserLocation() async {
    setState(() {
      isLoading = true; // ✅ Show loading while fetching suggestions
    });

    try {
      bool serviceEnabled = await _location.serviceEnabled();
      if (!serviceEnabled) {
        serviceEnabled = await _location.requestService();
      }

      PermissionStatus permission = await _location.hasPermission();
      if (permission == PermissionStatus.denied ||
          permission == PermissionStatus.deniedForever) {
        permission = await _location.requestPermission();
      }

      if (permission == PermissionStatus.granted) {
        LocationData locationData = await _location.getLocation();

        if (!mounted) return; // ✅ Prevents errors if widget is disposed

        _selectedLocation = LatLng(
          locationData.latitude!,
          locationData.longitude!,
        );
        _updateMarker(_selectedLocation);

        // ✅ Convert LatLng to Address and Autofill the TextField
        await _convertLatLngToAddress(_selectedLocation);

        setState(() {
          isLoading = false; // ✅ Hide loading after fetching location
        });

        final GoogleMapController controller = await _controller.future;
        controller.animateCamera(
          CameraUpdate.newLatLngZoom(_selectedLocation, 14.0),
        );
      } else {
        // 🚨 If location access is denied, prompt user to enter manually
        _promptManualLocationEntry();
      }
    } catch (error) {
      print("❌ Location Error: $error");
      _promptManualLocationEntry(); // 🚨 Show prompt if error occurs
    }
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
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  /// 🔹 Fetch Address Suggestions from Google Places API
  Future<void> _fetchAddressSuggestions(String query) async {
    if (query.isEmpty) {
      setState(() => _suggestions = []);
      return;
    }

    setState(() {
      isLoading = true; // ✅ Show loading while fetching suggestions
    });

    final String url =
        "https://maps.googleapis.com/maps/api/place/autocomplete/json?input=$query&key=$googleMapsApiKey&components=country:MY";

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        if (!mounted)
          return; // ✅ Prevent modifying state after widget is disposed
        setState(() {
          _suggestions = json.decode(response.body)["predictions"];
        });
      } else {
        throw Exception("Failed to fetch address suggestions");
      }
    } catch (error) {
      print("❌ API Error: $error");
    }
  }

  /// 🔹 Get Address Details & Move Map
  Future<void> _selectAddress(String placeId, String description) async {
    final String detailsUrl =
        "https://maps.googleapis.com/maps/api/place/details/json?place_id=$placeId&key=$googleMapsApiKey";

    final response = await http.get(Uri.parse(detailsUrl));

    if (response.statusCode == 200) {
      final details = json.decode(response.body);
      double lat = details["result"]["geometry"]["location"]["lat"];
      double lng = details["result"]["geometry"]["location"]["lng"];

      setState(() {
        _selectedLocation = LatLng(lat, lng);
        _locationController.text = description;
        _updateMarker(_selectedLocation);
        _suggestions = []; // Hide suggestions
      });

      final GoogleMapController controller = await _controller.future;
      controller.animateCamera(
        CameraUpdate.newLatLngZoom(_selectedLocation, 14.0),
      );
    }
  }

  /// 🔹 Convert LatLng → Address using Google Geocoding API
  Future<void> _convertLatLngToAddress(LatLng latLng) async {
    final String url =
        "https://maps.googleapis.com/maps/api/geocode/json?latlng=${latLng.latitude},${latLng.longitude}&key=$googleMapsApiKey";

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data["results"].isNotEmpty) {
          if (!mounted) return;
          setState(() {
            _locationController.text =
                data["results"][0]["formatted_address"]; // ✅ Autofill the location field
          });
        }
      } else {
        throw Exception("Failed to fetch address");
      }
    } catch (error) {
      print("❌ Address Fetch Error: $error");
    }
  }

  /// 🔹 Allow user to tap on the map to drop a pin
  void _onMapTap(LatLng position) {
    setState(() {
      _selectedLocation = position;
      _updateMarker(position);
      _convertLatLngToAddress(
        position,
      ); // Convert the selected location to an address
    });
  }

  /// 🔹 Update Marker Position on Map
  void _updateMarker(LatLng position) {
    setState(() {
      _userMarker = Marker(
        markerId: const MarkerId("user_selected"),
        position: position,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
      );
    });
  }

  /// ✅ Function to Track Request Status in Real-Time
  void _trackRequestStatus(String requestID) {
    FirebaseFirestore.instance
        .collection('emergency_requests')
        .doc(requestID)
        .snapshots()
        .listen((snapshot) {
          if (snapshot.exists) {
            var requestData = snapshot.data() as Map<String, dynamic>;
            String status = requestData['status'];
            String? driverID = requestData['driverID'];

            print("🔄 Request Status Updated: $status");

            if (status == "Upcoming" && driverID != null) {
              // ✅ Driver Assigned → Show Driver Details
              setState(() {
                isLoading = false;
              });
            } else if (status == "Pending") {
              // ✅ Still Pending → Keep Loading Indicator
              setState(() {
                isLoading = true;
              });
            }
          }
        });
  }

  void _submitRequest(String? customerID) async {
    if (customerID == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("❌ Customer ID not found. Please try again."),
        ),
      );
      return;
    }

    final requestViewModel = Provider.of<EmergencyRequestViewModel>(
      context,
      listen: false,
    );

    if (_selectedReason == null || _locationController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("⚠️ Please fill in all details.")),
      );
      return;
    }

    setState(() {
      isLoading = true; // ✅ Show loading spinner
    });

    // ✅ Generate a request ID in the format: EMQ_<timestamp>
    String requestID = "EMQ${DateTime.now().millisecondsSinceEpoch}";
    String? imageUrl = await requestViewModel.uploadImageToFirebase();

    GeoPoint customerGeoPoint = GeoPoint(
      _selectedLocation.latitude,
      _selectedLocation.longitude,
    );

    var newRequest = EmergencyRequest(
      requestID: requestID,
      customerID: customerID,
      location: customerGeoPoint,
      address: _locationController.text,
      bookingReason: _selectedReason!,
      preferredTime: requestViewModel.scheduledDateTime != null
          ? requestViewModel.scheduledDateTime.toString()
          : _preferredTime,
      status: "Pending",
      imageUrl: imageUrl ?? "", // ✅ Store image URL if uploaded
    );

    try {
      await requestViewModel.createRequest(newRequest);

      if (!mounted) return;

      setState(() {
        requestID = requestID; // ✅ Store requestID to track status updates
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ Request submitted successfully!")),
      );

      _trackRequestStatus(requestID); // ✅ Start listening for status updates

      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) Navigator.pop(context);
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

      print("❌ Firestore Save Error: $error");

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("❌ Failed to submit request. Try again.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final requestViewModel = Provider.of<EmergencyRequestViewModel>(context);

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
          /// ✅ Input Fields & Confirm Button (Scrollable)
          Expanded(
            flex: 1,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  /// ✅ Enter Location Input
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

                  /// ✅ Address Suggestions (Only Show When Needed)
                  if (_suggestions.isNotEmpty)
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(5),
                        boxShadow: [
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
                            title: Text(suggestion["description"]),
                            onTap: () {
                              _selectAddress(
                                suggestion["place_id"],
                                suggestion["description"],
                              );
                            },
                          );
                        }).toList(),
                      ),
                    ),
                  const SizedBox(height: 10),

                  /// ✅ Booking Reason Dropdown
                  const Text(
                    "Select Booking Reason",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 5),
                  DropdownButtonFormField<String>(
                    value: _selectedReason,
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

                  /// 🔹 Schedule Time Picker
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

                  /// 🔹 Image Upload Feature
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

                  /// ✅ Confirm Order Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: (activeRequestExists || isLoading)
                          ? null // Disable button if request is active or still loading
                          : () async {
                              setState(
                                () => isLoading = true,
                              ); // ✅ Show loading

                              _submitRequest(
                                customerID,
                              ); // ✅ Now call _submitRequest()
                            },
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
                      child: isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Text(
                              activeRequestExists
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

          /// ✅ Google Map (Rounded Corners)
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12), // ✅ Rounded edges
              child: GoogleMap(
                onTap: _onMapTap,
                markers: _userMarker != null ? {_userMarker!} : {},
                initialCameraPosition: CameraPosition(
                  target: _selectedLocation,
                  zoom: 14.0,
                ),
                onMapCreated: (GoogleMapController controller) {
                  _controller.complete(controller);
                },
              ),
            ),
          ),
        ],
      ),

      /// ✅ Floating "Locate Me" Button (Fixed Position)
      floatingActionButton: FloatingActionButton(
        onPressed: _getUserLocation,
        backgroundColor: Colors.blue,
        child: const Icon(Icons.my_location, size: 30, color: Colors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
