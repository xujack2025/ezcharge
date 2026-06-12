import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../../../viewmodels/application/profile_viewmodel.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  EditProfileScreenState createState() => EditProfileScreenState();
}

class EditProfileScreenState extends State<EditProfileScreen> {
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  String? _selectedGender;
  String? _selectedDateOfBirth;
  bool _hasSyncedProfile = false;
  bool _hasShownLoadError = false;

  final List<String> _genders = ["Male", "Female", "Other"];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<ProfileViewModel>().loadProfile();
      }
    });
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    final profileViewModel = context.read<ProfileViewModel>();
    final result = await profileViewModel.updateProfile(
      firstName: _firstNameController.text,
      lastName: _lastNameController.text,
      email: _emailController.text,
      gender: _selectedGender,
      dateOfBirth: _selectedDateOfBirth,
    );

    if (!mounted) return;

    switch (result) {
      case ProfileUpdateResult.success:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Profile updated successfully!")),
        );
        Navigator.pop(context);
        return;
      case ProfileUpdateResult.noCustomer:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Error: Customer not found.")),
        );
        break;
      case ProfileUpdateResult.invalidEmail:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Invalid email address"),
            backgroundColor: Colors.black,
          ),
        );
        break;
      case ProfileUpdateResult.failed:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to update profile.")),
        );
        break;
    }
  }

  void _syncControllers(ProfileViewModel profileViewModel) {
    if (_hasSyncedProfile || profileViewModel.customer == null) return;

    _firstNameController.text = profileViewModel.firstName;
    _lastNameController.text = profileViewModel.lastName;
    _emailController.text = profileViewModel.email;
    _phoneController.text = profileViewModel.phone;
    _selectedGender = profileViewModel.gender;
    _selectedDateOfBirth = profileViewModel.dateOfBirth;
    _hasSyncedProfile = true;
  }

  void _showLoadErrorIfNeeded(ProfileViewModel profileViewModel) {
    final errorMessage = profileViewModel.errorMessage;
    if (_hasSyncedProfile || _hasShownLoadError || errorMessage == null) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _hasShownLoadError = true;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(errorMessage)));
    });
  }

  void _pickDate() async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );

    if (pickedDate != null) {
      setState(() {
        _selectedDateOfBirth =
            "${pickedDate.day}/${pickedDate.month}/${pickedDate.year}";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileViewModel = context.watch<ProfileViewModel>();
    _syncControllers(profileViewModel);
    _showLoadErrorIfNeeded(profileViewModel);

    return Scaffold(
      // Set the body background to grey
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        leading: IconButton(
          icon: Container(
            decoration: const BoxDecoration(
              color: Colors.blue,
              shape: BoxShape.circle,
            ),
            padding: const EdgeInsets.all(8),
            child: const Icon(Icons.arrow_back, color: Colors.white),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Edit Profile",
          style: TextStyle(
            color: Colors.black,
            fontSize: 25,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTextField(
              "First Name",
              _firstNameController,
              isRequired: true,
            ),
            _buildTextField("Last Name", _lastNameController, isRequired: true),
            _buildTextField(
              "Email Address",
              _emailController,
              hint: "Enter Email Address",
            ),
            _buildTextField(
              "Phone Number",
              _phoneController,
              isEditable: false,
            ),
            _buildDropdownField("Gender", _genders, _selectedGender, (
              newValue,
            ) {
              setState(() => _selectedGender = newValue);
            }),
            _buildDatePickerField(
              "Date of Birth",
              _selectedDateOfBirth,
              _pickDate,
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: profileViewModel.isLoading ? null : _saveProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
                child: profileViewModel.isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        "SAVE",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Function to build text fields
  Widget _buildTextField(
    String label,
    TextEditingController controller, {
    String? hint,
    bool isRequired = false,
    bool isEditable = true,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (isRequired)
                const Text(" *", style: TextStyle(color: Colors.red)),
            ],
          ),
          const SizedBox(height: 5),
          TextField(
            controller: controller,
            enabled: isEditable,
            decoration: InputDecoration(
              hintText: hint,
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(5),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Function to build dropdown fields
  Widget _buildDropdownField(
    String label,
    List<String> items,
    String? selectedValue,
    ValueChanged<String?> onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 5),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(5),
            ),
            child: DropdownButton<String>(
              isExpanded: true,
              value:
                  (selectedValue == null ||
                      selectedValue.isEmpty ||
                      !items.contains(selectedValue))
                  ? null
                  : selectedValue,
              hint: const Text("Select Gender"),
              underline: const SizedBox(),
              onChanged: onChanged,
              items: items.map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  // Function to build date picker field
  Widget _buildDatePickerField(
    String label,
    String? selectedDate,
    VoidCallback onTap,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 5),
          InkWell(
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 15),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(5),
              ),
              child: Row(
                children: [
                  Text(selectedDate ?? "Select Date of Birth"),
                  const Spacer(),
                  const Icon(
                    Icons.calendar_today,
                    color: Colors.black54,
                    size: 16,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
