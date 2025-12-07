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

  const ProfilePage({
    super.key,
    required this.citizenId,
    required this.authToken,
  });

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
    fetchProfile();
  }

  Future<void> fetchProfile() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final data = await apiService.getCitizenBasicProfile(widget.citizenId);
      setState(() {
        name = data['name'] ?? "";
        phone = data['phone_number'] ?? "";
        district = data['district'] ?? "";
        houseNo = data['house_no'] ?? "";
        profileImagePath = data['profile_image'];
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = "Failed to load profile data.";
        isLoading = false;
      });
    }
  }



Future<void> _pickImage() async {
  final ImagePicker _picker = ImagePicker();
  
  // Pick an image from the gallery
  final XFile? pickedFile = await _picker.pickImage(
    source: ImageSource.gallery,
    maxWidth: 600,
    maxHeight: 600,
    imageQuality: 85,
  );

  if (pickedFile != null) {
    final pickedImageFile = File(pickedFile.path);

    // Get the file extension
    String fileExtension = pickedImageFile.path.split('.').last.toLowerCase();
    if (!['jpg', 'jpeg', 'png'].contains(fileExtension)) {
      // Show an error if the file type is not allowed
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a JPG, JPEG, or PNG image.')),
      );
      return;  // Exit if the file type is invalid
    }

    // Show a confirmation dialog to upload the image
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Image Upload'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.file(pickedImageFile, width: 100, height: 100, fit: BoxFit.cover),
            const SizedBox(height: 12),
            const Text('Do you want to save this image as your profile picture?'),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Done')),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => selectedImage = pickedImageFile);

      try {
        // Assuming apiService.uploadProfileImage is defined properly
        final uploadResponse = await apiService.uploadProfileImage(
          citizenId: widget.citizenId,
          imageFile: selectedImage!,
        );
        
        // Success message after uploading
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile image uploaded successfully')),
        );

        setState(() {
          profileImagePath = uploadResponse['profile_image'];  // Update state with the uploaded image URL
        });
      } catch (e) {
        // Display the error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Image upload failed: $e')),
        );
      }
    }
  } else {
    // No image selected, inform the user
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('No image selected')),
    );
  }
}


  bool isValidObjectId(String id) {
    final pattern = RegExp(r'^[a-fA-F0-9]{24}$');
    return pattern.hasMatch(id);
  }

  void _onNavTapped(int index) {
    if (_selectedIndex == index) return;
    setState(() => _selectedIndex = index);

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
          MaterialPageRoute(builder: (context) => const CompliancePage()),
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
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (errorMessage != null) {
      return Scaffold(body: Center(child: Text(errorMessage!)));
    }

    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 255, 255, 255),
appBar: AppBar(
  backgroundColor: const Color.fromARGB(255, 18, 20, 68),
  elevation: 6,
  centerTitle: true,
  leading: null, // Remove the default leading button
  title: null,   // Remove the default title
  shape: const RoundedRectangleBorder(
    borderRadius: BorderRadius.vertical(bottom: Radius.elliptical(190, 130)),
  ),
  toolbarHeight: 240, // Keep the same height for the AppBar
  flexibleSpace: Stack(
    clipBehavior: Clip.none,
    alignment: Alignment.topCenter,
    children: [
      // Positioned Title and Back Icon to go upwards
      Positioned(
        top: 20,  // Adjust this value to control how far upwards the text and back icon go
        left: 0,
        right: 0,
        bottom: 140,
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.of(context).pop(),
            ),
            const Expanded(
              child: Text(
                'Profile',
                textAlign: TextAlign.center, // Center the title
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 20),
              ),
            ),
          ],
        ),
      ),
      // Profile image
 Positioned(
  bottom: -50,  // Move the image downward inside the rounded shape
  left: 130,    // Adjust left position if needed
  child: Container(
    width: 150,
    height: 150,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: Colors.grey[300],
    ),
    clipBehavior: Clip.antiAlias,
    child: selectedImage != null  // If an image is selected, display it
        ? Image.file(selectedImage!, fit: BoxFit.cover)  // Show the selected image
        : (profileImagePath != null && profileImagePath!.isNotEmpty)  // If there's a profile image URL
            ? Image.network(
                profileImagePath!,
                fit: BoxFit.cover,
                loadingBuilder: (BuildContext context, Widget child, ImageChunkEvent? loadingProgress) {
                  if (loadingProgress == null) {
                    return child;
                  } else {
                    return Center(
                      child: CircularProgressIndicator(
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded / (loadingProgress.expectedTotalBytes ?? 1)
                            : null,
                      ),
                    );
                  }
                },
                errorBuilder: (context, error, stackTrace) {
                  // Display default icon if image fails to load
                  return const Icon(Icons.person, size: 96, color: Colors.white);
                },
              )
            : const Icon(Icons.person, size: 96, color: Colors.white),  // Default icon when no image
  ),
),


      // Add button (plus icon) outside the profile image
      Positioned(
        left: 220,  // Adjust the left position to place it outside the circle
        bottom: -30,  // Adjust the bottom position to make sure it's outside the profile image
        child: Material(
          color: Colors.transparent, // Ensure the button's background is transparent
          child: InkWell(
            onTap: () {
              print("Add image button clicked");  // Check if tap is detected
              _pickImage();  // Your image picker logic
            },
            child: Container(
              width: 50,  // Adjust size for better visibility
              height: 50,
              decoration: BoxDecoration(
                color: Colors.black87,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 8),
                ],
              ),
              child: const Icon(
                Icons.add,
                color: Colors.white,
                size: 36,  // Adjust icon size for better visibility
              ),
            ),
          ),
        ),
      ),
    ],
  ),
),

      body: Container(
        padding: EdgeInsets.fromLTRB(16, 40, 16, bottomPadding),
        child: Column(
          children: [
            
            const SizedBox(height: 28),

            // info tiles (value below the title)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  _infoTile(icon: Icons.person_outline, title: "Name", value: name),
                  _infoTile(icon: Icons.phone_outlined, title: "Phone", value: phone),
                  _infoTile(icon: Icons.location_on_outlined, title: "District", value: district),
                  _infoTile(icon: Icons.home_outlined, title: "House No", value: houseNo),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // logout
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (context) => const SignInScreen()),
                    (route) => false,
                  );
                },
                icon: const Icon(Icons.logout, color: Colors.black87),
                label: const Text(
                  "Log out",
                  style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w600, fontSize: 16),
                ),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 56),
                  side: BorderSide(color: Colors.black.withOpacity(0.2), width: 1.6),
                  shape: const StadiumBorder(),
                  backgroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
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
                      )),
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

  Widget _infoTile({
    required IconData icon,
    required String title,
    required String value,
    VoidCallback? onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 243, 243, 243),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 12, offset: const Offset(0, 6)),
        ],
      ),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: Colors.black87),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700, color: Colors.black87)),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.black54, fontSize: 14),
          ),
        ),
        onTap: onTap,
      ),
    );
  }
}
