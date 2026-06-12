import 'dart:io';

import 'package:image_picker/image_picker.dart';

enum AppImageSource { gallery, camera }

abstract class ImagePickerServiceContract {
  Future<File?> pickImage(AppImageSource source);
}

class ImagePickerService implements ImagePickerServiceContract {
  ImagePickerService({ImagePicker? picker}) : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;

  @override
  Future<File?> pickImage(AppImageSource source) async {
    final pickedFile = await _picker.pickImage(source: _toImageSource(source));
    if (pickedFile == null) return null;
    return File(pickedFile.path);
  }

  ImageSource _toImageSource(AppImageSource source) {
    return switch (source) {
      AppImageSource.gallery => ImageSource.gallery,
      AppImageSource.camera => ImageSource.camera,
    };
  }
}
