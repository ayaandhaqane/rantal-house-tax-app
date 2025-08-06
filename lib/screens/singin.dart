import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'home.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  bool _obscurePassword = true;
  bool _isLoading = false;

  final TextEditingController _houseNoController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  final ApiService _apiService = ApiService();

  Future<void> saveUserSession({
  required String citizenId,
  required String authToken,
}) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('citizenId', citizenId);
  await prefs.setString('authToken', authToken);
  
  // Debug print
  print("User session saved: $citizenId, $authToken");
}

  Future<void> savePropertyId(String propertyId) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  await prefs.setString('propertyId', propertyId);

  // Debug print
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
        final authToken = response['token'] ?? ''; // <--- get your token here

        // Save citizenId to SharedPreferences
        await saveUserSession(citizenId: citizenId, authToken: authToken);

        // Fetch property by citizenId and save propertyId
        final property = await _apiService.getPropertyByCitizenId(citizenId);
        print('Fetched property data: $property');

        final propertyId = property['property_id']?.toString() ?? '';
        if (propertyId.isNotEmpty) {
          await savePropertyId(propertyId);
        } else {
          _showMessage('No property found for this user.');
        }

        // now fetch the summary
        //  final taxSummary = await _apiService.get(
        //     '/taxcollections/summary/$citizenId',
        //     headers: {'Authorization': 'Bearer $authToken'},
        //   );

        final taxAmount = await getTaxAmount(citizenId, authToken);
        // if (taxSummary.containsKey('total_due')) {
        //   // can be double, string or int, so parse
        //   final raw = taxSummary['total_due'];
        //   taxAmount=double.parse(raw.toString());
        //   // if (raw is int) taxAmount = raw;
        //   // else if (raw is double) taxAmount = raw.toInt();
        //   // else if (raw is String) taxAmount = int.tryParse(raw) ?? double.tryParse(raw)?.toInt() ?? 0;
        // }

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => HomeScreen(
              userName: userName,
             
              authToken: authToken, // <--- pass token here
              citizenId: citizenId, // pass citizenId directly
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
              child: Image.asset(
                'images/welcome.jpg',
                height: 260,
                fit: BoxFit.contain,
              ),
            ),
            Expanded(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                decoration: const BoxDecoration(
                  color: Color.fromARGB(184, 118, 118, 138),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(40),
                    topRight: Radius.circular(40),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 12,
                      offset: Offset(0, -5),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Sign In',
                      style: TextStyle(
                        color: Color(0xFF121440),
                        fontWeight: FontWeight.bold,
                        fontSize: 22,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 30),
                    TextFormField(
                      controller: _houseNoController,
                      keyboardType: TextInputType.text,
                      decoration: InputDecoration(
                        labelText: 'House no',
                        border: const OutlineInputBorder(),
                        isDense: true,
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                            color: Color.fromARGB(255, 206, 203, 203),
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    // const Text(
                    //   style: TextStyle(fontSize: 12, color: Colors.black54),
                    // ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        border: const OutlineInputBorder(),
                        isDense: true,
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                            color: Color.fromARGB(255, 216, 213, 213),
                            width: 1.5,
                          ),
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility
                                : Icons.visibility_off,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                    SizedBox(
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _signIn,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color.fromARGB(255, 4, 7, 68),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isLoading
                            ? const CircularProgressIndicator(
                                color: Colors.white)
                            : const Text(
                                'Sign In',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
