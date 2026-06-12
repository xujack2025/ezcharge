import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../../../../../services/profile_account_service.dart';
import '../../../../../../viewmodels/application/profile_authentication_viewmodel.dart';
import 'pending_screen.dart';

class UploadSelfieScreen extends StatelessWidget {
  const UploadSelfieScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ProfileAuthenticationViewModel(),
      child: const _UploadSelfieContent(),
    );
  }
}

class _UploadSelfieContent extends StatefulWidget {
  const _UploadSelfieContent();

  @override
  State<_UploadSelfieContent> createState() => _UploadSelfieContentState();
}

class _UploadSelfieContentState extends State<_UploadSelfieContent> {
  final ImagePicker _picker = ImagePicker();
  File? _selfieImage;

  Future<void> _getImage(ImageSource source) async {
    final image = await _picker.pickImage(source: source);
    if (image == null || !mounted) return;
    setState(() => _selfieImage = File(image.path));
  }

  Future<void> _uploadSelfieImage() async {
    final viewModel = context.read<ProfileAuthenticationViewModel>();
    final result = await viewModel.uploadImage(
      type: ProfileAuthenticationImageType.selfie,
      image: _selfieImage,
    );

    if (!mounted) return;

    switch (result) {
      case ProfileAuthenticationUploadResult.success:
        _showSuccessDialog();
      case ProfileAuthenticationUploadResult.noImage:
      case ProfileAuthenticationUploadResult.customerNotFound:
      case ProfileAuthenticationUploadResult.failed:
        _showErrorDialog(
          viewModel.errorMessage ?? 'Failed to upload image. Please try again.',
        );
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Upload Successful'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 60),
            SizedBox(height: 10),
            Text('Your selfie has been uploaded successfully.'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushReplacement(
                this.context,
                MaterialPageRoute(builder: (context) => const PendingScreen()),
              );
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Upload Failed', style: TextStyle(color: Colors.red)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error, color: Colors.red, size: 50),
            const SizedBox(height: 10),
            Text(message),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<ProfileAuthenticationViewModel>();

    return Scaffold(
      backgroundColor: Colors.grey[200],
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            color: Colors.white,
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: const BoxDecoration(
                      color: Colors.blue,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.arrow_back, color: Colors.white),
                  ),
                ),
                const SizedBox(width: 10),
                const Text(
                  'Authenticate Account',
                  style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          Container(
            width: double.infinity,
            color: Colors.grey[200],
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: const Text(
              'Step 2/2',
              textAlign: TextAlign.right,
              style: TextStyle(fontSize: 14, color: Colors.black54),
            ),
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              height: 180,
              decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.black45,
                  width: 1.5,
                  style: BorderStyle.solid,
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: _selfieImage == null
                    ? const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.camera_alt,
                            size: 50,
                            color: Colors.black45,
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Please upload your selfie',
                            style: TextStyle(
                              color: Colors.black54,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      )
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(_selfieImage!, fit: BoxFit.cover),
                      ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          if (_selfieImage == null) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: Column(
                children: [
                  _ImageSourceButton(
                    icon: Icons.image,
                    label: 'Choose from Gallery',
                    onPressed: () => _getImage(ImageSource.gallery),
                  ),
                  const SizedBox(height: 10),
                  _ImageSourceButton(
                    icon: Icons.camera_alt,
                    label: 'Take a picture',
                    onPressed: () => _getImage(ImageSource.camera),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 20),
          if (_selfieImage != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: viewModel.isLoading ? null : _uploadSelfieImage,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                  child: viewModel.isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'UPLOAD',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ImageSourceButton extends StatelessWidget {
  const _ImageSourceButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, color: Colors.white),
        label: Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
        ),
      ),
    );
  }
}
