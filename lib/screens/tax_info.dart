import 'package:flutter/material.dart';
import '../services/api_service.dart';

class TaxInfoPage extends StatefulWidget {
  final String authToken;
  final String citizenId;

  const TaxInfoPage({
    Key? key,
    required this.authToken,
    required this.citizenId,
  }) : super(key: key);

  @override
  State<TaxInfoPage> createState() => _TaxInfoPageState();
}

class _TaxInfoPageState extends State<TaxInfoPage> {
  late ApiService apiService;

  String? houseNo;
  String? districtId;
  String? branchId;
  String? zoneId;
  String? houseRent;
  final String taxRate = "5"; // fixed tax rate 5%

  String? districtName;
  String? branchName;
  String? zoneName;

  bool isLoading = true;
  String? errorMessage;

  List<Map<String, dynamic>> districts = [];
  List<Map<String, dynamic>> branches = [];
  List<Map<String, dynamic>> zones = [];

  @override
  void initState() {
    super.initState();
    apiService = ApiService();
    apiService.setAuthToken(widget.authToken);
    fetchPropertyInfo();
  }

  Future<void> fetchPropertyInfo() async {
    try {
      final property = await apiService.getPropertyByCitizenId(widget.citizenId);

      // Fetch all lists in parallel
      final results = await Future.wait([
        apiService.getAllDistricts(),
        apiService.getAllBranches(),
        apiService.getAllZones(),
      ]);

      districts = results[0];
      branches = results[1];
      zones = results[2];

      // Get IDs from property safely
      districtId = property['district_id']?.toString();
      branchId = property['branch_id']?.toString();
      zoneId = property['zone_id']?.toString();

      districtName = property['district'] ?? '';
      branchName = property['branch'] ?? '';
      zoneName = property['zone'] ?? '';

      // Parse house rent without dividing by 3
      double monthlyRent = 0.0;
      final rawRent = property['house_rent'];
      if (rawRent is Map && rawRent.containsKey(r'$numberDecimal')) {
        monthlyRent = double.tryParse(rawRent[r'$numberDecimal'].toString()) ?? 0.0;
      } else {
        monthlyRent = double.tryParse(rawRent?.toString() ?? '0') ?? 0.0;
      }
      houseRent = monthlyRent.toStringAsFixed(1);

      setState(() {
        houseNo = property['house_no']?.toString() ?? '';
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = 'Failed to load: $e';
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final monthlyRent = double.tryParse(houseRent ?? '0') ?? 0.0;
    final quarterlyRent = monthlyRent * 3;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tax Information'),
        backgroundColor: const Color.fromARGB(255, 19, 14, 59),
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 6,
      ),
      backgroundColor: Colors.white,
      body: SafeArea(
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : errorMessage != null
                ? Center(child: Text(errorMessage!))
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(18.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _infoRow('House No', houseNo ?? '', bold: true),
                        _infoRow('District', districtName ?? '', bold: true),
                        _infoRow('Branch', branchName ?? '', bold: true),
                        _infoRow('Zone', zoneName ?? '', bold: true),
                        _infoRow('House Rent', '${houseRent ?? ''} / month', bold: true),
                        _infoRow('Tax Rate', '$taxRate%', bold: true),
                        const SizedBox(height: 18),
                        const Divider(),
                        const SizedBox(height: 12),
                        const Text(
                          'Tax Calculation',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 19,
                            color: Color(0xFF2276BC),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            'House Rent: \$${houseRent ?? '0'} / month\n'
                            'Quarterly Calculation: \$${houseRent} × 3 months = \$${quarterlyRent.toStringAsFixed(2)}\n'
                            'Applied Tax Rate: $taxRate% of quarterly rent\n'
                            'Calculation: \$${_calculateQuarterly(houseRent ?? '0')} × $taxRate% = \$${_calculateTax(houseRent ?? '0')}\n'
                            'Total Quarterly Tax: \$${_calculateTax(houseRent ?? '0')}',
                            style: const TextStyle(
                              fontSize: 15,
                              letterSpacing: 1.5,
                              height: 1.7,
                              color: Colors.black,
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.yellow[100],
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 6,
                                height: 140,
                                decoration: const BoxDecoration(
                                  color: Color.fromARGB(255, 255, 226, 10),
                                  borderRadius: BorderRadius.only(
                                    topLeft: Radius.circular(4),
                                    bottomLeft: Radius.circular(4),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              const Expanded(
                                child: Text(
                                  'Note: Tax is calculated quarterly (every 3 months). \n'
                                  'If you begin renting in the middle of a quarter, tax will be calculated only for the remaining months of that quarter.\n'
                                  'Quarters: Q1 (Jan-Mar), Q2 (Apr-Jun), Q3 (Jul-Sep), Q4 (Oct-Dec)',
                                  style: TextStyle(
                                    fontSize: 14.2,
                                    color: Colors.black,
                                    height: 1.6,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
      ),
    );
  }

  String _calculateQuarterly(String rent) {
    final cleaned = rent.replaceAll(RegExp(r'[^\d.]'), '');
    final monthly = double.tryParse(cleaned) ?? 0.0;
    final quarterly = monthly * 3;
    return quarterly.toStringAsFixed(2);
  }

  String _calculateTax(String rent) {
    final cleanedRent = rent.replaceAll(RegExp(r'[^\d.]'), '');
    final monthly = double.tryParse(cleanedRent) ?? 0.0;
    final quarterly = monthly * 3;

    const taxRate = 5.0;
    final taxAmount = quarterly * (taxRate / 100);
    return taxAmount.toStringAsFixed(2);
  }

  Widget _infoRow(String label, String value, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 15,
                color: Colors.black54,
              ),
              textAlign: TextAlign.left,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              value,
              style: TextStyle(
                fontWeight: bold ? FontWeight.bold : FontWeight.normal,
                fontSize: 15,
                color: Colors.black,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}
