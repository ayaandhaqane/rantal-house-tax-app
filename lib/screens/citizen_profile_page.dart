import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:rental_house_taxation_flutter/screens/singin.dart';
import 'package:rental_house_taxation_flutter/services/api_service.dart';
import 'package:rental_house_taxation_flutter/screens/home.dart';
import 'package:rental_house_taxation_flutter/screens/payment.dart';
import 'package:rental_house_taxation_flutter/screens/compliance_page.dart';
import 'package:rental_house_taxation_flutter/widgets/custom_button.dart';

class ProfilePage extends StatefulWidget {
  final String citizenId;
  final String authToken;

  const ProfilePage(
      {super.key, required this.citizenId, required this.authToken});

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final ApiService apiService = ApiService();

  String name = "";
  String phone = "";
  String district = "";
  String houseNo = "";
  String? profileImagePath;

  File? selectedImage; 

  bool isLoading = true;
  String? errorMessage;

  int _selectedIndex = 4;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    apiService.setAuthToken(widget.authToken);
    fetchProfile(); // fetch once when page loads
  }

  Future<void> fetchProfile() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
      // Do NOT reset selectedImage here, keep it persistent
    });

    try {
      final data = await apiService.getCitizenBasicProfile(widget.citizenId);
      print(data);
      setState(() {
        name = data['name'] ?? "";
        phone = data['phone_number'] ?? "";
        district = data['district'] ?? "";
        houseNo = data['house_no'] ?? "";
        profileImagePath = data['profile_image'];

        isLoading = false;
      });
      print("IMAGE HHHH ${profileImagePath}");
    } catch (e, stacktrace) {
      print('Error fetching profile: $e');
      print('Stacktrace: $stacktrace');
      setState(() {
        errorMessage = "Failed to load profile data.";
        isLoading = false;
      });
    }
  }

  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 600,
      maxHeight: 600,
      imageQuality: 85,
    );

    if (pickedFile != null) {
      File pickedImageFile = File(pickedFile.path);

      final bool? confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Confirm Image Upload'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.file(pickedImageFile,
                  width: 100, height: 100, fit: BoxFit.cover),
              const SizedBox(height: 12),
              const Text(
                  'Do you want to save this image as your profile picture?'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Done'),
            ),
          ],
        ),
      );

      if (confirm == true) {
        if (!isValidObjectId(widget.citizenId)) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content:
                    Text('Invalid citizen ID format, cannot upload image.')),
          );
          return;
        }

        setState(() {
          selectedImage = pickedImageFile;
        });

        try {
          final uploadResponse = await apiService.uploadProfileImage(
            citizenId: widget.citizenId,
            imageFile: selectedImage!,
          );
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Profile image uploaded successfully')),
          );
          setState(() {
            profileImagePath = uploadResponse['profile_image'];
          });
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Image upload failed: $e')),
          );
        }
      }
    }
  }

  bool isValidObjectId(String id) {
    final pattern = RegExp(r'^[a-fA-F0-9]{24}$');
    return pattern.hasMatch(id);
  }

  void _onNavTapped(int index) {
    if (_selectedIndex == index) return;

    setState(() {
      _selectedIndex = index;
    });

    switch (index) {
      case 0:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => HomeScreen(
              userName: name,
              authToken: widget.authToken,
              citizenId: widget.citizenId,
            ),
          ),
        );
        break;
      case 1:
        break;
      case 2:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PaymentScreen(
              authToken: widget.authToken,
              citizenId: widget.citizenId,
            ),
          ),
        );
        break;
      case 3:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => CompliancePage()),
        );
        break;
      case 4:
        fetchProfile();
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (errorMessage != null) {
      return Scaffold(
        body: Center(child: Text(errorMessage!)),
      );
    }

    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 43, horizontal: 20),
            decoration: const BoxDecoration(
              color: Color(0xFF1F0A38),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    const Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(top: 13),
                        child: Text(
                          "Profile",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
                const SizedBox(height: 30),
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 80,
                      backgroundColor: Colors.grey[300],
                      backgroundImage: selectedImage != null
                          ? FileImage(selectedImage!)
                          : (profileImagePath != null &&
                                  profileImagePath!.isNotEmpty)
                              ? NetworkImage('$profileImagePath')
                                  as ImageProvider
                              : null,
                      child: (selectedImage == null &&
                              (profileImagePath == null ||
                                  profileImagePath!.isEmpty))
                          ? const Icon(Icons.person,
                              size: 60, color: Colors.white)
                          : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: IconButton(
                          icon: Icon(Icons.camera_alt, color: Colors.grey[700]),
                          onPressed: _pickImage,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: ListView(
                children: [
                  _profileField(Icons.person, "Name", name),
                  _profileField(Icons.phone, "Phone", phone),
                  _profileField(Icons.location_on, "District", district),
                  _profileField(Icons.house_siding, "House No", houseNo),
                  const SizedBox(height: 20),
                  OutlinedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (context) => SignInScreen()),
                        (route) => false,
                      );
                    },
                    icon: const Icon(Icons.logout, color: Colors.red),
                    label: const Text(
                      "Logout",
                      style: TextStyle(
                          color: Colors.red, fontWeight: FontWeight.bold),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.red, width: 2),
                      padding: const EdgeInsets.all(15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),

      floatingActionButton: Padding(
        padding: EdgeInsets.only(bottom: bottomPadding + 6),
        child: FloatingActionButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PaymentScreen(
                  authToken: widget.authToken,
                  citizenId: widget.citizenId,
                ),
              ),
            );
          },
          backgroundColor: const Color(0xFF121440),
          child: const Icon(Icons.payment, size: 32, color: Colors.white),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

      bottomNavigationBar: BottomNav(
        selectedIndex: _selectedIndex,
        onTap: _onNavTapped,
        userName: name,
        taxAmount: "0",
        authToken: widget.authToken,
        citizenId: widget.citizenId,
      ),
    );
  }

  Widget _profileField(IconData icon, String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: Colors.grey, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "$label:",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.black87,
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.only(left: 0),
                    height: 1.5,
                    color: Colors.grey[400],
                    width: double.infinity,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 25),
      ],
    );
  }
}
