import 'dart:io';

import 'package:flutter/material.dart';
import 'package:rental_house_taxation_flutter/screens/compliance_page.dart';
import 'package:rental_house_taxation_flutter/screens/notification_page.dart';
import 'package:rental_house_taxation_flutter/screens/payment.dart';
import 'package:rental_house_taxation_flutter/screens/tax_info.dart';
import 'package:rental_house_taxation_flutter/services/api_service.dart';
import 'package:rental_house_taxation_flutter/widgets/custom_button.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomeScreen extends StatefulWidget {
  final String userName;

  final String authToken;
  final String citizenId; 
  final String? houseNo;

  const HomeScreen({
    super.key,
    required this.userName,
    required this.authToken, 
    required this.citizenId, 
    this.houseNo, 
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _showTransactions = false;
  int _selectedIndex = 0;
  late String citizenId;
  late String authToken; // Add this
  String? houseNo; // Define houseNo here
  late ApiService apiService;
  bool isLoading = true;
  String district = '';
  String branch = '';
  String zone = '';
  String houseRent = '0';
  String taxRate = '0';
  String propertyId = '';
  String? errorMessage;
  double? taxAmount;
  bool isTaxLoading = true;
  String? profileImagePath; // For storing the profile image URL
  File? selectedImage; 
  List<Map<String, dynamic>> transactions = [];

  @override
  void initState() {
    super.initState();
    citizenId = widget.citizenId;
    authToken = widget.authToken;
    apiService = ApiService();
    apiService.setAuthToken(authToken);
    fetchProfileImage();
    fetchPropertyByCitizenId();
      getTaxAmount().then((value) {
        setState(() {
          taxAmount = value;  // Set the fetched tax amount
          isTaxLoading = false;  // Stop loading once data is fetched
        });
      });
    fetchTransactions();
  }

  bool isLoadingHouseNo = true;
  String myHouseNo = ''; // <-- Add this here

Future<double> getTaxAmount() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final citizenId = prefs.getString('citizenId');
    final authToken = prefs.getString('authToken');

    if (citizenId == null || authToken == null) {
      debugPrint('Missing citizenId or authToken in storage');
      return 0.0; // Return 0.0 if data is missing
    }

    final taxSummary = await ApiService().get(
      '/taxcollections/summary/$citizenId',
      headers: {'Authorization': 'Bearer $authToken'},
    );

    if (taxSummary.containsKey('total_due')) {
      final raw = taxSummary['total_due'];
      return double.tryParse(raw.toString()) ?? 0.0; // Return 0.0 if the value is not parseable
    } else {
      debugPrint('Tax summary not found');
      return 0.0; // Return 0.0 if the total_due key is missing
    }
  } catch (e) {
    debugPrint('Error fetching tax amount: $e');
    return 0.0; // Return 0.0 if an error occurs
  }
}


  Future<void> _loadCitizenId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? storedCitizenId = prefs.getString('citizenId');

    if (storedCitizenId == null) {
      // Handle user not logged in or navigate to login screen
      print('No citizenId found in SharedPreferences!');
      setState(() {
        isLoading = false;
      });
      return;
    }

    setState(() {
      citizenId = storedCitizenId;
      isLoading = false;
    });

    // Now fetch property or any other data that depends on citizenId
    fetchPropertyByCitizenId();
  }

  Future<void> fetchHouseNo() async {
    try {
      final data = await apiService.getPropertyByCitizenId(citizenId);
      final fetchedHouseNo = data['house_no'] ?? '';

      if (fetchedHouseNo.isEmpty) {
        throw Exception("House number not found for this citizen");
      }

      setState(() {
        myHouseNo = fetchedHouseNo;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        myHouseNo = '';
        isLoading = false;
      });
      print('Error fetching house no: $e');
    }
  }

  Future<void> fetchPropertyByCitizenId() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? citizenId = prefs.getString('citizenId');

      if (citizenId == null) {
        throw Exception('User not logged in!');
      }

      final data = await apiService.getPropertyByCitizenId(citizenId);
      print('Fetched property data: $data');

      setState(() {
        houseNo = data['house_no'] ?? '';
        district = data['district'] ?? '';
        branch = data['branch'] ?? '';
        zone = data['zone'] ?? '';
        houseRent = data['house_rent'] ?? '0';
        taxRate = data['tax_rate'] ?? '0';
        propertyId = data['property_id'] ?? '';
        isLoading = false;
        print('propertyId: $propertyId, houseNo: $houseNo');
      });
    } catch (e) {
      setState(() {
        errorMessage = e.toString();
        isLoading = false;
      });
    }
  }

  
  Future<void> fetchProfileImage() async {
    try {
      final data = await apiService.getCitizenBasicProfile(citizenId);
      setState(() {
        profileImagePath = data['profile_image']; // Store the profile image URL
      });
    } catch (e) {
      setState(() {
        profileImagePath = null; // Set it to null in case of error
      });
      debugPrint('Error fetching profile image: $e');
    }
  }

  void _toggleTransactionsVisibility() {
    setState(() {
      _showTransactions = !_showTransactions;
    });
  }

  void _onNavTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    if (index == 2) {
      Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => PaymentScreen(
                  authToken: widget.authToken,
                  citizenId: widget.citizenId,
                )),
      );
    }
  }

  Future<void> fetchTransactions() async {
    try {
      final api = ApiService();
      final txs = await api.getTransactions(widget.citizenId);
      final txList = List<Map<String, dynamic>>.from(txs);

      setState(() {
        transactions = txList;
      });
    } catch (e) {
      setState(() {
        transactions = [];
      });
    }
  }

  

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 255, 255, 255),
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 45, 69, 109),
        toolbarHeight: 75,
        automaticallyImplyLeading: false,
        title: ListTile(
          contentPadding: EdgeInsets.zero,
          leading: CircleAvatar(
            radius: 30,
            backgroundColor: Colors.grey[300],
            backgroundImage: selectedImage != null
                ? FileImage(selectedImage!) // Use local image if selected
                : (profileImagePath != null && profileImagePath!.isNotEmpty)
                    ? NetworkImage(profileImagePath!) // Fetch image from backend if available
                    : null, // If no image, it will be null
            child: (selectedImage == null && (profileImagePath == null || profileImagePath!.isEmpty))
                ? const Icon(Icons.person, size: 20, color: Colors.white) // Default icon if no image
                : null,
          ),

          title: RichText(
            text: TextSpan(
              text: 'Welcome back!\n',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
              children: [
                TextSpan(
                  text: widget.userName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          trailing: IconButton(
            icon: const Icon(Icons.notifications_none_outlined,
                size: 28, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const NotificationPage()),
              );
            },
          ),
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
        userName: widget.userName,
        taxAmount: getTaxAmount().toString(),
        authToken: widget.authToken, 
        citizenId: widget.citizenId,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(16, 16, 16, 80 + bottomPadding + 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Total Tax Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color.fromARGB(255, 9, 10, 46),
                      Color.fromARGB(255, 149, 152, 194),
                    ],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Total Tax',
                      style: TextStyle(color: Colors.white, fontSize: 15),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      isTaxLoading ? 'Loading...' : '\$${taxAmount?.toStringAsFixed(2) ?? '0.00'}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                  ],
                ),
              ),

              const SizedBox(height: 18),

              // Compliance & Calculation Section
              const Text(
                'Tax Compliance & Calculation',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Colors.black87,
                ),
              ),

              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CompliancePage(),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF121440),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.document_scanner,
                                color: Colors.white, size: 30),
                            SizedBox(height: 8),
                            Text(
                              'Compliance',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => TaxInfoPage(
                              authToken: authToken,
                              citizenId: citizenId,
                            ),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Color.fromARGB(255, 99, 153, 204),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.calculate,
                                color: Colors.white, size: 30),
                            SizedBox(height: 8),
                            Text(
                              'Calculate Tax',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              GestureDetector(
                onTap: _toggleTransactionsVisibility,
                child: Row(
                  children: [
                    Text(
                      'Transaction',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color:
                            _showTransactions ? Colors.black : Colors.grey[400],
                      ),
                    ),
                    const SizedBox(width: 6),
                    Icon(
                      _showTransactions
                          ? Icons.visibility
                          : Icons.visibility_off,
                      size: 16,
                      color: Colors.grey[400],
                    ),
                    const Spacer(),
                    const Text(
                      'More reports',
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 8),

              _showTransactions
                  ? transactions.isEmpty
                      ? const Center(child: Text('No transactions found.'))
                      : ListView.builder(
                          physics: const NeverScrollableScrollPhysics(),
                          shrinkWrap: true,
                          itemCount: transactions.length,
                          itemBuilder: (context, index) {
                            final tx = transactions[index];
                            return Card(
                              margin: const EdgeInsets.symmetric(vertical: 6),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                              child: ListTile(
                                leading: Container(
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF20124D),
                                    shape: BoxShape.circle,
                                  ),
                                  width: 28,
                                  height: 28,
                                  child: const Center(
                                    child: Icon(Icons.arrow_forward, color: Colors.white, size: 18),
                                  ),
                                ),
                                title: const Text(
                                  'wasaarada maaliyada',
                                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                                ),
                                subtitle: Text(
                                  'transfer ${_formatDateTime(tx['payment_date'])}',
                                  style: const TextStyle(color: Colors.grey, fontSize: 13),
                                ),
                                trailing: Text(
                                  '\$${tx['payment_amount'] ?? tx['amount'] ?? ''}',
                                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                                ),
                              ),
                            );
                          },
                        )
                  : Column(
                      children: List.generate(
                        6,
                        (index) => Container(
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          height: 50,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDateTime(dynamic dateTime) {
    if (dateTime == null) return '';
    try {
      final dt = DateTime.parse(dateTime.toString());
      return '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}.${dt.year.toString().substring(2)} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return dateTime.toString();
    }
  }
}
