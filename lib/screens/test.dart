import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

// Your helper class (not a widget)
class ImagePickerHelper {
  final ImagePicker _picker = ImagePicker();

  Future<File?> pickImageFromGallery() async {
    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 600,
      maxHeight: 600,
      imageQuality: 85,
    );
    if (pickedFile != null) {
      return File(pickedFile.path);
    }
    return null;
  }
}

// Widget that uses the helper
class ImagePickerScreen extends StatefulWidget {
  const ImagePickerScreen({Key? key}) : super(key: key);

  @override
  State<ImagePickerScreen> createState() => _ImagePickerScreenState();
}

class _ImagePickerScreenState extends State<ImagePickerScreen> {
  final ImagePickerHelper _pickerHelper = ImagePickerHelper();
  File? _pickedImage;

  Future<void> _pickImage() async {
    final image = await _pickerHelper.pickImageFromGallery();
    if (image != null) {
      setState(() {
        _pickedImage = image;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Image Picker Demo')),
      body: Center(
        child: _pickedImage == null
            ? const Text('No image selected.')
            : Image.file(_pickedImage!),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _pickImage,
        child: const Icon(Icons.image),
      ),
    );
  }
}

void main() {
  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Rental House Taxation',
      home: const ImagePickerScreen(),  // Use the widget here
    ),
  );
}
