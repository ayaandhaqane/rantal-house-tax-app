import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:path/path.dart';  
import 'package:http/http.dart' as http;

class ApiService {
  final String baseUrl = "http://192.168.18.8:5000/api";

  String? authToken;

  void setAuthToken(String token) {
    authToken = token;
  }

  Map<String, String> get headers {
    final defaultHeaders = {'Content-Type': 'application/json'};
    if (authToken != null) {
      defaultHeaders['Authorization'] = 'Bearer $authToken';
    }
    return defaultHeaders;
  }

  Future<Map<String, dynamic>> post({
    required String endpoint,
    required Map<String, dynamic> body,
    Map<String, String>? headers,
  }) async {
    final url = Uri.parse('$baseUrl$endpoint');

    final defaultHeaders = {
      'Authorization':
          'Bearer $authToken', // Make sure this is your valid JWT token
      'Content-Type': 'application/json',
    };

    final combinedHeaders = {
      ...defaultHeaders,
      if (headers != null) ...headers
    };

    final response = await http.post(
      url,
      headers: combinedHeaders,
      body: jsonEncode(body),
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception(
          'API request failed: ${response.statusCode} ${response.body}');
    }
  }

Future<Map<String, dynamic>> get(
  String endpoint, {
  Map<String, String>? headers,
  }) async {
    final url = Uri.parse('$baseUrl$endpoint');
    final response = await http.get(url, headers: headers);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception(
          'API GET failed: ${response.statusCode} ${response.body}');
    }
  }


  Future<Map<String, dynamic>> getPropertyByHouseNo(String houseNo) async {
    final url = Uri.parse('$baseUrl/properties/house/$houseNo');
    final response = await http.get(url, headers: headers);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;

      final citizenId = data['citizen_id']?.toString();

      String totalAmountText = '';

      if (citizenId != null && citizenId.isNotEmpty) {
        final taxSummary = await getTaxSummary(citizenId);
        if (taxSummary != null && taxSummary['total_due'] != null) {
          totalAmountText = '\$${taxSummary['total_due'].toString()}';
        }
      }

      data['total_amount_due'] = totalAmountText; // Add combined field

      return data;
    } else {
      throw Exception('Failed to fetch property info: ${response.statusCode}');
    }
  }

  Future<Map<String, dynamic>> getTaxSummary(String citizenId) async {
    final url = Uri.parse('$baseUrl/taxcollections/summary/$citizenId');
    final response = await http.get(url, headers: headers);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('Failed to fetch tax summary: ${response.statusCode}');
    }
  }

  

  Future<Map<String, dynamic>> validateHormuudNumber(String phoneNumber) async {
    try {
      final response =
          await http.get(Uri.parse('$baseUrl/validate-hormuud/$phoneNumber'));
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        return {'valid': true};
      }
    } catch (e) {
      return {'valid': false};
    }
  }

 

  Future<Map<String, dynamic>> getCitizenBasicProfile(String citizenId) async {
    final url = Uri.parse('$baseUrl/citizens/profile/$citizenId');

    final response = await http.get(url);

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('Failed to load citizen profile: ${response.statusCode}');
    }
  }

Future<Map<String, dynamic>> getPropertyByCitizenId(String citizenId) async {
  final url = Uri.parse('$baseUrl/properties/citizen/$citizenId');
  final response = await http.get(url, headers: headers);

  if (response.statusCode >= 200 && response.statusCode < 300) {
    var data = jsonDecode(response.body) as Map<String, dynamic>;

    // Fetch and embed branch details
    if (data.containsKey('branch_id')) {
      try {
        final branches = await getAllBranches();
        final branch = branches.firstWhere((b) => b['_id'] == data['branch_id'], orElse: () => {});
        data['branch'] = branch;
      } catch (e) {
        print('Error fetching branch details: $e');
        data['branch'] = {'name': 'N/A'};
      }
    }

    // Fetch and embed district details
    if (data.containsKey('district_id')) {
      try {
        final districts = await getAllDistricts();
        final district = districts.firstWhere((d) => d['_id'] == data['district_id'], orElse: () => {});
        data['district'] = district;
      } catch (e) {
        print('Error fetching district details: $e');
        data['district'] = {'name': 'N/A'};
      }
    }
    
    try {
      final taxSummaryResponse = await getTaxSummary(citizenId);
      log('Tax Summary Data: $taxSummaryResponse');

      Map<String, dynamic> taxSummary = {};
      if (taxSummaryResponse.containsKey('summary') && taxSummaryResponse['summary'] is Map<String, dynamic>) {
        taxSummary = taxSummaryResponse['summary'] as Map<String, dynamic>;
      } else {
        taxSummary = taxSummaryResponse;
      }

      if (taxSummary.containsKey('total_due')) {
        data['total_amount_due'] = taxSummary['total_due'];
      }
      if (taxSummary.containsKey('tax_amount')) {
        data['tax_amount'] = taxSummary['tax_amount'];
      }
    } catch (e) {
      print('Could not fetch tax summary for citizen $citizenId: $e');
    }
    return data;
  } else {
    throw Exception(
        'Failed to fetch property by citizen ID: ${response.statusCode} ${response.body}');
  }
}
  

  Future<Map<String, dynamic>> getPropertyByHouseNoForCitizen(String houseNo, String? citizenId) async {
  if (houseNo.isEmpty) {
    throw Exception("House number cannot be empty");
  }
  if (citizenId == null || citizenId.isEmpty) {
    throw Exception("Citizen ID cannot be empty");
  }

  final url = Uri.parse('$baseUrl/properties/house/$houseNo/citizen/$citizenId');

  final response = await http.get(url, headers: headers);

  if (response.statusCode == 200) {
    return jsonDecode(response.body) as Map<String, dynamic>;
  } else {
    throw Exception('Error fetching property: ${response.statusCode} ${response.body}');
  }
}

  

 Future<void> submitComplaint({ 
   required String citizenId,
  required String propertyId,
  required String complaintDescription
   }) async {
  final url = Uri.parse('$baseUrl/complaints/create');
  final response = await http.post(
    url,
    headers: {
      'Content-Type': 'application/json',
      if (authToken != null) 'Authorization': 'Bearer $authToken',
    },
    body: jsonEncode({
      "citizen_id": citizenId,
      "property_id": propertyId,
      "complaint_description": complaintDescription,
    }),
  );

  if (response.statusCode == 201) {
    // Success
    print("Complaint submitted successfully");
  } else {
    print("Failed to submit complaint: ${response.body}");
    throw Exception("Failed to submit complaint: ${response.statusCode}");
  }
}

Future<List<Map<String, dynamic>>> getComplaintsList({String? citizenId}) async {
  String url = '$baseUrl/complaints';
  if (citizenId != null) {
    url += '?citizenId=$citizenId';
  }
  final response = await http.get(Uri.parse(url), headers: headers);
  if (response.statusCode >= 200 && response.statusCode < 300) {
    final List<dynamic> jsonList = jsonDecode(response.body);
    return jsonList.cast<Map<String, dynamic>>();
  } else {
    throw Exception('Failed to load complaints list');
  }
}


  // New method to call your payment API
  Future<Map<String, dynamic>> makePayment({
    required String citizenId,
    required String propertyId,
    required String phone,
  }) async {
    final url = Uri.parse('$baseUrl/payments/make-payment');

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        if (authToken != null) 'Authorization': 'Bearer $authToken',
      },
      body: jsonEncode({
        'citizen_id': citizenId,
        'property_id': propertyId,
        'phone': phone, // asi waco kan kale badalkiisa xogtaasna u dhiib   maba islahan 2 methods wye 
      }),
    );
    print(response.body);
    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'Payment API call failed');
    }
  }

    Future<List<Map<String, dynamic>>> getAllDistricts() async {
    final response = await http.get(
      Uri.parse('$baseUrl/districts'),
      headers: headers,
    );
    return parseListResponse(response);
  }

  Future<List<Map<String, dynamic>>> getAllBranches() async {
    final response = await http.get(
      Uri.parse('$baseUrl/branches'),
      headers: headers,
    );
    return parseListResponse(response);
  }

  Future<List<Map<String, dynamic>>> getAllZones() async {
    final response = await http.get(
      Uri.parse('$baseUrl/zones'),
      headers: headers,
    );
    return parseListResponse(response);
  }


  List<Map<String, dynamic>> parseListResponse(http.Response response) {
  if (response.statusCode >= 200 && response.statusCode < 300) {
    final List<dynamic> jsonList = jsonDecode(response.body);
    return jsonList.cast<Map<String, dynamic>>();
  } else {
    throw Exception('Failed to fetch list: ${response.statusCode} ${response.body}');
  }
}

Future<Map<String, dynamic>> uploadProfileImage({
  required String citizenId,
  required File imageFile,
}) async {
  final uri = Uri.parse('$baseUrl/upload-profile-image/$citizenId');

  var request = http.MultipartRequest('POST', uri);

  if (authToken != null) {
    request.headers['Authorization'] = 'Bearer $authToken';
  }

  request.files.add(
    await http.MultipartFile.fromPath(
      'profile_image',  
      imageFile.path,
      filename: basename(imageFile.path),
    ),
  );

  var streamedResponse = await request.send();

  var response = await http.Response.fromStream(streamedResponse);

  if (response.statusCode == 200) {
    return jsonDecode(response.body);
  } else {
    throw Exception('Failed to upload image: ${response.body}');
  }
}


 Future<List<dynamic>> fetchMessages() async {
    final url = Uri.parse('$baseUrl/messages/allMessages');
    print('Fetching messages from: $url');
    final response = await http.get(url, headers: {'Content-Type': 'application/json'});

    if (response.statusCode == 200) {
      return json.decode(response.body) as List<dynamic>;
    } else {
      throw Exception('Failed to load messages: ${response.statusCode} ${response.body}');
    }
  }


  Future<List<Map<String, dynamic>>> getTransactions(String citizenId) async {
  final url = Uri.parse('$baseUrl/payments/payments/$citizenId');  // Use baseUrl here

  final response = await http.get(
    url,
    headers: {
      'Content-Type': 'application/json',
      if (authToken != null) 'Authorization': 'Bearer $authToken', 
    },
  );

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    return List<Map<String, dynamic>>.from(data['transactions']);
  } else {
    throw Exception('Failed to load transactions: ${response.statusCode}');
  }
}


  Future<List<Map<String, dynamic>>> getDetailedTransactions(String citizenId) async {
    final url = Uri.parse('$baseUrl/payments/detailed/$citizenId');  // Endpoint for getting detailed transactions by citizen ID

    final response = await http.get(url, headers: {
      'Content-Type': 'application/json',
    });

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['status'] == true) {
        return List<Map<String, dynamic>>.from(data['transactions']);
      } else {
        throw Exception('Failed to load transactions');
      }
    } else {
      throw Exception('Failed to load transactions: ${response.statusCode}');
    }
  }




}
