import 'dart:developer';
import 'package:flutter/material.dart';
import '../services/api_service.dart';

class PaymentScreen extends StatefulWidget {
  final String authToken;
  final String citizenId;

  const PaymentScreen({
    super.key,
    required this.authToken,
    required this.citizenId,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final TextEditingController branchController = TextEditingController();
  final TextEditingController districtController = TextEditingController();
  final TextEditingController houseController = TextEditingController();
  final TextEditingController rentController = TextEditingController();
  final TextEditingController taxController = TextEditingController();
  final TextEditingController totalAmountController = TextEditingController();

  bool isFetching = true; // Start in fetching state to show loading indicator
  bool isLoading = false; // For payment submission

  late String? citizenId;
  String? propertyId;
  String? _phoneNumber;

  late ApiService apiService;

  @override
  void initState() {
    super.initState();
    citizenId = widget.citizenId;

    apiService = ApiService();
    apiService.setAuthToken(widget.authToken);
    _fetchPropertyForCitizen(); // Automatically fetch data on screen load
  }

  @override
  void dispose() {
    branchController.dispose();
    districtController.dispose();
    houseController.dispose();
    rentController.dispose();
    taxController.dispose();
    totalAmountController.dispose();
    super.dispose();
  }

  Future<void> _fetchPropertyForCitizen() async {
    if (citizenId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Could not identify user. Please log in again.')),
        );
        setState(() => isFetching = false);
      }
      return;
    }

    try {
      final data = await apiService.getPropertyByCitizenId(citizenId!);
      log('Property Data: $data');

      if (mounted) {
        setState(() {
          houseController.text = data['house_no']?.toString() ?? '';
          
          dynamic branchData = data['branch'];
          if (branchData is Map && branchData.containsKey('branch_name')) {
            branchController.text = branchData['branch_name']?.toString() ?? '';
          } else {
            branchController.text = branchData?.toString() ?? '';
          }

          dynamic districtData = data['district'];
          if (districtData is Map && districtData.containsKey('district_name')) {
            districtController.text = districtData['district_name']?.toString() ?? '';
          } else {
            districtController.text = districtData?.toString() ?? '';
          }

          dynamic rent = data['house_rent'];
          if (rent is Map && rent.containsKey('\$numberDecimal')) {
            rentController.text = rent['\$numberDecimal']?.toString() ?? '';
          } else {
            rentController.text = rent?.toString() ?? '';
          }

          // Tax Amount - trying multiple keys
            dynamic taxValue = data['tax_amount'] ?? data['tax'];
          if (taxValue is Map && taxValue.containsKey('\$numberDecimal')) {
              final finalTaxAmount = double.tryParse(taxValue['\$numberDecimal'].toString()) ?? 0.0;
              taxController.text = finalTaxAmount.toStringAsFixed(2); // Display tax amount with two decimal places
          } else {
            taxController.text = taxValue?.toString() ?? '0';
          }

          /// Total Amount - trying multiple keys
          dynamic totalValue = data['total_amount_due'] ?? data['total_due'];
          if (totalValue is Map && totalValue.containsKey('\$numberDecimal')) {
            final finalTotalAmount = double.tryParse(totalValue['\$numberDecimal'].toString()) ?? 0.0;
            totalAmountController.text = finalTotalAmount.toStringAsFixed(2);
          } else {
            totalAmountController.text = totalValue?.toString() ?? '0';
          }

          propertyId = data['property_id']?.toString();
          _phoneNumber = data['phone_number']?.toString();
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to fetch property details: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isFetching = false;
        });
      }
    }
  }

  Future<void> submitPayment() async {
    if (propertyId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'Property information not loaded. Cannot proceed with payment.')),
      );
      return;
    }

    final paymentAmountText =
        totalAmountController.text.replaceAll(RegExp(r'[^\d.]'), '').trim();

    if (paymentAmountText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Total amount is empty')),
      );
      return;
    }

    final paymentAmount = double.tryParse(paymentAmountText);
    if (paymentAmount == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid total amount')),
      );
      return;
    }

    if (paymentAmount == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You have no payment due at this time.')),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      if (_phoneNumber == null || _phoneNumber!.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Phone number not found for this property')),
        );
        setState(() => isLoading = false);
        return;
      }

      final validationResult =
          await ApiService().validateHormuudNumber(_phoneNumber!);
      final bool isValidNumber = validationResult['valid'] ?? true;

      if (!isValidNumber) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Phone number is not a valid Hormuud number')),
        );
        setState(() => isLoading = false);
        return;
      }

      await apiService.makePayment(
        citizenId: widget.citizenId,
        propertyId: propertyId!,
        phone: _phoneNumber!,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'Payment successful! Please complete the USSD prompt on your phone.')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Payment failed: $e')),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(color: Colors.white),
        title: const Text(
          'Payment',
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: const Color.fromARGB(255, 7, 16, 69),
        foregroundColor: Colors.white,
        elevation: 0,
        toolbarHeight: 80,
      ),
      body: isFetching
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(20),
              child: ListView(
                children: [
                  // All fields are now read-only and loaded automatically.
                  _buildReadOnlyField('House-no:', houseController),
                  const SizedBox(height: 12),
                  _buildReadOnlyField('Branch:', branchController),
                  const SizedBox(height: 12),
                  _buildReadOnlyField('District:', districtController),
                  const SizedBox(height: 12),
                  _buildReadOnlyField('Rent:', rentController),
                  const SizedBox(height: 12),
                  _buildReadOnlyField('Tax:', taxController),
                  const SizedBox(height: 12),
                  _buildReadOnlyField('Total Amount:', totalAmountController),

                  const SizedBox(height: 32),

                  SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      onPressed: isLoading ? null : submitPayment,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromARGB(255, 18, 20, 68),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              'Submit Payment',
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
    );
  }

  Widget _buildReadOnlyField(String label, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.grey,
            fontWeight: FontWeight.w400,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          width: 500,
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            controller.text,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.black87,
            ),
          ),
        ),
      ],
    );
  }
}
