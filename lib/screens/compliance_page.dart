import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Add intl for date formatting
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
    // Same day
    return 'Today';
  } else if (difference.inDays == 1 || 
             (difference.inDays == 0 && now.day != date.day)) {
    // Yesterday (handles day boundary)
    return 'Yesterday';
  } else {
    // Else show day and month only, e.g. 30 May
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
        // Show time like "10:42 AM"
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
        backgroundColor: const Color.fromARGB(255, 9, 16, 53),
        foregroundColor: Colors.white,
        centerTitle: true,
        toolbarHeight: 65, 

      ),
      body: isLoading
    ? const Center(child: CircularProgressIndicator())
    : errorMessage != null
        ? Center(child: Text(errorMessage!))
        : complianceList.isEmpty
            ? const Center(child: Text('No compliance records found.'))
            : Padding(
                padding: const EdgeInsets.only(top: 16.0), // Add top padding here
                child: ListView.separated(
                  itemCount: complianceList.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final compliance = complianceList[index];
                    return ListTile(
                      title: Text(
                        compliance['complaint_description'] ?? 'No description',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: compliance['createdAt'] != null
                          ? Text(formatComplianceDate(compliance['createdAt']))
                          : null,
                      onTap: () => onComplianceTap(compliance),
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
