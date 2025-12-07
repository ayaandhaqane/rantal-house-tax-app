import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // For date formatting
import 'package:rental_house_taxation_flutter/model/NewCompliancePage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import 'ComplianceDetailPage.dart';

class CompliancePage extends StatefulWidget {
  const CompliancePage({super.key});

  @override
  State<CompliancePage> createState() => _ComplianceListPageState();
}

class _ComplianceListPageState extends State<CompliancePage> {
  final ApiService apiService = ApiService();
  bool isLoading = true;
  String? errorMessage;
  List<Map<String, dynamic>> complianceList = [];
  String? citizenId;
  String? propertyId;

  @override
  void initState() {
    super.initState();
    loadIdsAndFetchCompliance();
  }

  String formatComplianceDate(String dateStr) {
    final date = DateTime.parse(dateStr);
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0 && now.day == date.day) {
      return 'Today';
    } else if (difference.inDays == 1 || 
               (difference.inDays == 0 && now.day != date.day)) {
      return 'Yesterday';
    } else {
      return DateFormat('d MMM').format(date);
    }
  }

  Future<void> loadIdsAndFetchCompliance() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    citizenId = prefs.getString('citizenId');
    propertyId = prefs.getString('propertyId');
    print('Fetched Citizen ID: $citizenId, Property ID: $propertyId');

    if (citizenId == null || propertyId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Citizen or Property ID missing!')),
      );
      setState(() {
        isLoading = true;
        complianceList = [];
      });
      return;
    }

    await fetchComplianceList();
  }

  Future<void> fetchComplianceList() async {
    try {
      if (citizenId == null) {
        throw Exception('Citizen ID is null');
      }
      final list = await apiService.getComplaintsList(citizenId: citizenId);
      setState(() {
        complianceList = list;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = 'Failed to load compliance list: $e';
        isLoading = false;
      });
    }
  }

  String formatDateTime(String rawDate) {
    try {
      final date = DateTime.parse(rawDate);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays == 0) {
        return DateFormat.jm().format(date);
      } else if (difference.inDays == 1) {
        return 'Yesterday';
      } else {
        return DateFormat.yMMMd().format(date);
      }
    } catch (e) {
      return rawDate;
    }
  }

  void onComplianceTap(Map<String, dynamic> compliance) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ComplianceDetailPage(compliance: compliance),
      ),
    );
  }

  void onAddNewCompliance() async {
    if (citizenId == null || propertyId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Citizen or Property ID missing!')),
      );
      return;
    }

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (context) => NewComplianceDialog(
        citizenId: citizenId!,
        propertyId: propertyId!,
      ),
    );
    if (result == true) {
      fetchComplianceList();
    }
  }

@override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      title: const Text('Compliance'),
      backgroundColor: const Color.fromARGB(255, 18, 20, 68),
      foregroundColor: Colors.white,
      centerTitle: true,
      toolbarHeight: 80,
    ),
    body: isLoading
        ? const Center(child: CircularProgressIndicator())
        : errorMessage != null
            ? Center(child: Text(errorMessage!))
            : complianceList.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.warning_amber_outlined,  // Use any icon you prefer
                          size: 80,  // Adjust icon size as needed
                          color: Colors.grey,  // Adjust icon color
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'No compliance records found.',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  )
                : Padding(
                    padding: const EdgeInsets.only(top: 16.0),
                    child: ListView.separated(
                      itemCount: complianceList.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final compliance = complianceList[index];
                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          leading: CircleAvatar(
                            radius: 25,
                            backgroundColor: Colors.blue,
                            child: const Icon(
                              Icons.person,
                              color: Colors.white,
                            ),
                          ),
                          title: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'Wasaarada Maaliyada', // Title for each message
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Color.fromARGB(255, 65, 64, 64),
                                  ),
                                ),
                              ),
                              Text(
                                formatComplianceDate(compliance['createdAt']),
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                          subtitle: Text(
                            compliance['complaint_description'] ?? 'No description',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Color.fromARGB(255, 108, 105, 105),
                            ),
                          ),
                          trailing: IconButton(
                            icon: const Icon(
                              Icons.arrow_forward_ios,
                              size: 16,
                              color: Color.fromARGB(255, 0, 0, 0),
                            ),
                            onPressed: () => onComplianceTap(compliance),
                          ),
                        );
                      },
                    ),
                  ),
    floatingActionButton: FloatingActionButton(
      onPressed: onAddNewCompliance,
      child: const Icon(Icons.add),
      tooltip: 'New Compliance',
    ),
  );
}


}