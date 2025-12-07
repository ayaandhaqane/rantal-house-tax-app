import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'home.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class HeaderArcClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final w = size.width;
    final h = size.height;

    // Concave arc (white bites into green)
    final path = Path()
      ..lineTo(0, h * 0.65)
      ..quadraticBezierTo(w / 2, h + 120, w, h * 0.65)
      ..lineTo(w, 0)
      ..close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class _SignInScreenState extends State<SignInScreen> {
  bool _obscurePassword = true;
  bool _isLoading = false;
  final TextEditingController _houseNoController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final ApiService _apiService = ApiService();
  FocusNode _houseNoFocusNode = FocusNode();

  Future<void> saveUserSession({
    required String citizenId,
    required String authToken,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('citizenId', citizenId);
    await prefs.setString('authToken', authToken);
    print("User session saved: $citizenId, $authToken");
  }

  Future<void> savePropertyId(String propertyId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('propertyId', propertyId);
    print("Property ID saved: $propertyId");
  }

  Future<double> getTaxAmount(String citizenId, String authToken) async {
    try {
      final taxSummary = await _apiService.get(
        '/taxcollections/summary/$citizenId',
        headers: {'Authorization': 'Bearer $authToken'},
      );
      if (taxSummary.containsKey('total_due')) {
        final raw = taxSummary['total_due'];
        return double.tryParse(raw.toString()) ?? 0.0;
      }
    } catch (e) {
      debugPrint('Error fetching tax amount: $e');
    }
    return 0.0;
  }

  Future<void> _signIn() async {
    final houseNo = _houseNoController.text.trim();
    final password = _passwordController.text;
    if (houseNo.isEmpty || password.isEmpty) {
      _showMessage('Please enter both House No and Password');
      return;
    }
    setState(() {
      _isLoading = true;
    });
    try {
      final response = await _apiService.post(
        endpoint: '/citizens/login',
        body: {'house_no': houseNo, 'password': password},
      );
      if (response.containsKey('citizen')) {
        final userName = response['citizen']['name'] ?? 'User';
        final citizenId =
            response['citizen']['_id'] ?? response['citizen']['citizen_id'];
        final authToken = response['token'] ?? '';
        await saveUserSession(citizenId: citizenId, authToken: authToken);
        final property = await _apiService.getPropertyByCitizenId(citizenId);
        print('Fetched property data: $property');
        final propertyId = property['property_id']?.toString() ?? '';
        if (propertyId.isNotEmpty) {
          await savePropertyId(propertyId);
        } else {
          _showMessage('No property found for this user.');
        }
        final taxAmount = await getTaxAmount(citizenId, authToken);
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => HomeScreen(
              userName: userName,
              authToken: authToken,
              citizenId: citizenId,
            ),
          ),
        );
      } else if (response.containsKey('message')) {
        _showMessage('Sign in failed: ${response['message']}');
      } else {
        _showMessage('Sign in failed: Unexpected response');
      }
    } catch (e) {
      _showMessage('Sign in failed: ${e.toString()}');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  void dispose() {
    _houseNoController.dispose();
    _passwordController.dispose();
    _houseNoFocusNode.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(  // Make the entire body scrollable
          child: Column(
            children: [
              // Top curved section
              SizedBox(
                height: 350,
                child: Stack(
                  alignment: Alignment.bottomCenter,
                  clipBehavior: Clip.none,
                  children: [
                    ClipPath(
                      clipper: HeaderArcClipper(),
                      child: Container(
                        color: const Color.fromARGB(255, 7, 13, 45),
                        width: double.infinity,
                        height: double.infinity,
                      ),
                    ),
                    Positioned(
                      bottom: -100, // Move the image outside the container
                      // left: 0.1,
                      child: Image.asset(
                        'images/taxt.png', // Keep your asset path
                        height: 330,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 60,),
              // Bottom section with form
              Container(
                padding: const EdgeInsets.all(32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Sign In',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Color.fromARGB(255, 13, 14, 13),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Enter your credentials to access your account',
                      style: TextStyle(
                        fontSize: 16,
                        color: Color(0xFF718096),
                      ),
                    ),
                    const SizedBox(height: 20),
                    // House Number Input
                    // const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.2),
                            spreadRadius: 2,
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 12),
                            child: Icon(
                              Icons.home,
                              color: Color.fromARGB(255, 10, 12, 41),
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextFormField(
                              controller: _houseNoController,
                              keyboardType: TextInputType.text,
                              decoration: const InputDecoration(
                                labelText: 'House Number',
                                labelStyle: TextStyle(color: Color.fromARGB(255, 141, 141, 141)),
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Password Input
                    const SizedBox(height: 16),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.2),
                            spreadRadius: 2,
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 12),
                            child: Icon(
                              Icons.lock,
                              color: Color.fromARGB(255, 21, 15, 48),
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextFormField(
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              focusNode: _houseNoFocusNode,  // Use focus node

                              decoration: InputDecoration(
                                labelText: 'Password',
                                 labelStyle: TextStyle(
                                  color: _houseNoFocusNode.hasFocus || _houseNoController.text.isNotEmpty
                                      ? Color(0xFF4CAF50)
                                      : Colors.grey,  // Change color based on focus
                                     ),
                                 border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ),
                          IconButton(
                            icon: Icon(
                              _obscurePassword ? Icons.visibility_off : Icons.visibility,
                              color: const Color.fromARGB(255, 19, 14, 52),
                              size: 20,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Sign In Button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _signIn,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color.fromARGB(255, 8, 6, 40),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                'Sign In',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
