import 'dart:io';

import 'package:expense_tracker/models/init_shared_pref.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

class ImageController extends ChangeNotifier {
  final InitSheredPref _initSheredPref = InitSheredPref.instance;

  ImageController() {
    pickImage();
  }

  File? _imageFile;

  File? get imageFile => _imageFile;

  final ImagePicker _picker = ImagePicker();

  Future<void> pickFromGallery() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      final savedImage = await _saveImagePermanently(pickedFile.path);

      _imageFile = savedImage;

      await _initSheredPref.setImages(savedImage.path);

      notifyListeners();
    }
  }

  Future<void> pickFromCamera() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.camera);

    if (pickedFile != null) {
      final savedImage = await _saveImagePermanently(pickedFile.path);

      _imageFile = savedImage;

      await _initSheredPref.setImages(savedImage.path);

      notifyListeners();
    }
  }

  Future<File> _saveImagePermanently(String path) async {
    final dir = await getApplicationDocumentsDirectory();

    final fileName = path.split('/').last;

    final savedImage = await File(path).copy('${dir.path}/$fileName');

    return savedImage;
  }

  Future<void> pickImage() async {
    final imagePath = await _initSheredPref.getImages();

    if (imagePath != null) {
      final imageFile = File(imagePath);

      if (imageFile.existsSync()) {
        _imageFile = imageFile;
        notifyListeners();
      }
    }
  }
}
