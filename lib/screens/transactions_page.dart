// import 'package:flutter/material.dart';
// import 'package:path_provider/path_provider.dart';
// import 'dart:io';
// import 'package:rental_house_taxation_flutter/services/api_service.dart';
// import 'package:screenshot/screenshot.dart';
// import 'package:share_plus/share_plus.dart';

// class TransactionsPage extends StatefulWidget {
//   final String citizenId;

//   const TransactionsPage({Key? key, required this.citizenId}) : super(key: key);

//   @override
//   _TransactionsPageState createState() => _TransactionsPageState();
// }

// class _TransactionsPageState extends State<TransactionsPage> {
//   String selectedFilter = "All";
//   DateTime? selectedDate;
//   bool isLoading = true;
//   String errorMessage = '';
//   List<Map<String, dynamic>> transactions = [];

//   final ScreenshotController screenshotController = ScreenshotController();

//   @override
//   void initState() {
//     super.initState();
//     fetchTransactions();
//   }

//    // Modify the fetch function to ensure payment_amount is correctly fetched
//   Future<void> fetchTransactions() async {
//     try {
//       final rawResponse = await ApiService().getTransactions(widget.citizenId);

//       // Check if we got an empty list (no transactions)
//       if (rawResponse.isEmpty) {
//         setState(() {
//           transactions = [];
//           isLoading = false;
//           errorMessage = ''; // Clear any error message
//         });
//         return;
//       }

//       List<Map<String, dynamic>> mappedTransactions = (rawResponse as List).map((tx) {
//         DateTime? paymentDate;
//         String dateStr = '';
//         String timeStr = '';
//         if (tx['payment_date'] != null) {
//           paymentDate = DateTime.tryParse(tx['payment_date']);
//           if (paymentDate != null) {
//             dateStr =
//                 "${paymentDate.day.toString().padLeft(2, '0')}.${paymentDate.month.toString().padLeft(2, '0')}.${paymentDate.year.toString().substring(2)}";
//             timeStr =
//                 "${paymentDate.hour.toString().padLeft(2, '0')}:${paymentDate.minute.toString().padLeft(2, '0')}";
//           }
//         }

//         // Ensure payment_amount is used here directly
//         return {
//           'id': tx['id'],
//           'date': dateStr,
//           'time': timeStr,
//           'payment_amount': tx['payment_amount'] ?? 0, // Using payment_amount directly
//         };
//       }).toList();

//       setState(() {
//         transactions = mappedTransactions;
//         isLoading = false;
//         errorMessage = ''; // Clear any error message
//       });
//     } catch (e) {
//       setState(() {
//         errorMessage = 'Error fetching transactions: $e';
//         isLoading = false;
//       });
//     }
//   }

//   Future<void> _pickDate(BuildContext context) async {
//     final DateTime today = DateTime.now();
//     final DateTime? picked = await showDatePicker(
//       context: context,
//       initialDate: selectedDate ?? today,
//       firstDate: DateTime(2000),
//       lastDate: DateTime(today.year + 5),
//     );
//     if (picked != null) {
//       setState(() {
//         selectedDate = picked;
//         selectedFilter = "Select Date";
//       });
//     }
//   }

//   Widget _buildCircleFilterButton(String text, {bool hasArrow = false}) {
//     final bool isSelected = selectedFilter == text;
//     return GestureDetector(
//       onTap: () {
//         if (text == "Select Date") {
//           _pickDate(context);
//         } else {
//           setState(() {
//             selectedFilter = text;
//             selectedDate = null;
//           });
//         }
//       },
//       child: Container(
//         height: 36,
//         padding: EdgeInsets.symmetric(horizontal: hasArrow ? 8 : 20),
//         decoration: BoxDecoration(
//           color: isSelected ? const Color(0xFF20124D) : const Color(0xFFEAEAF2),
//           borderRadius: BorderRadius.circular(18),
//         ),
//         child: Row(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             Text(
//               text == "Select Date" && selectedDate != null
//                   ? "${selectedDate!.day.toString().padLeft(2, '0')}/${selectedDate!.month.toString().padLeft(2, '0')}/${selectedDate!.year}"
//                   : text,
//               style: TextStyle(
//                 color: isSelected ? Colors.white : Colors.black87,
//                 fontWeight: FontWeight.w600,
//                 fontSize: 14,
//               ),
//             ),
//             if (hasArrow)
//               Padding(
//                 padding: const EdgeInsets.only(left: 4.0),
//                 child: Icon(
//                   Icons.keyboard_arrow_down,
//                   size: 20,
//                   color: isSelected ? Colors.white : const Color(0xFF20124D),
//                 ),
//               ),
//           ],
//         ),
//       ),
//     );
//   }

//   void _showTransactionDetails(Map<String, dynamic> transaction) async {
//     try {
//       showDialog(
//         context: context,
//         barrierDismissible: false,
//         builder: (context) => const Center(child: CircularProgressIndicator()),
//       );

//       final detailedTransactions = await ApiService().getDetailedTransactions(widget.citizenId);
//       final detailedTx = detailedTransactions.firstWhere(
//         (tx) => tx['id'] == transaction['id'],
//         orElse: () => transaction,
//       );

//       String formattedDate = '';
//       String formattedTime = '';
//       if (detailedTx['payment_date'] != null) {
//         DateTime? paymentDate = DateTime.tryParse(detailedTx['payment_date']);
//         if (paymentDate != null) {
//           formattedDate =
//               "${paymentDate.day.toString().padLeft(2, '0')}.${paymentDate.month.toString().padLeft(2, '0')}.${paymentDate.year.toString().substring(2)}";
//           formattedTime =
//               "${paymentDate.hour.toString().padLeft(2, '0')}:${paymentDate.minute.toString().padLeft(2, '0')}";
//         }
//       }

//       final mappedTx = {
//         'id': detailedTx['id'],
//         'name': detailedTx['name'] ?? 'N/A',
//         'date': formattedDate,
//         'time': formattedTime,
//         'amount': "\$${_convertDecimalToString(detailedTx['payment_amount'])}",
//         'payment_amount': _convertDecimalToString(detailedTx['payment_amount']),
//         'sender_number': detailedTx['sender_number'] ?? 'N/A',
//         'sender_name': detailedTx['sender_name'] ?? 'N/A',
//         'house_rent': _convertDecimalToString(detailedTx['house_rent']),
//         'tax': _convertDecimalToString(detailedTx['tax']),
//         'total': _convertDecimalToString(detailedTx['payment_amount']),
//       };

//       Navigator.of(context).pop();

//       showModalBottomSheet(
//         context: context,
//         isScrollControlled: true,
//         backgroundColor: Colors.transparent,
//         builder: (BuildContext context) {
//           return Center(
//             child: Container(
//               margin: const EdgeInsets.symmetric(horizontal: 20),
//               padding: const EdgeInsets.all(16.0),
//               height: MediaQuery.of(context).size.height * 0.7,
//               decoration: BoxDecoration(
//                 color: Colors.white,
//                 borderRadius: BorderRadius.circular(20),
//                 boxShadow: [
//                   BoxShadow(
//                     color: Colors.black.withOpacity(0.2),
//                     blurRadius: 10,
//                     spreadRadius: 5,
//                   ),
//                 ],
//               ),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   Screenshot(
//                     controller: screenshotController,
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         const SizedBox(height: 10),
//                         Center(
//                           child: Container(
//                             width: 50,
//                             height: 5,
//                             decoration: BoxDecoration(
//                               color: Colors.grey[300],
//                               borderRadius: BorderRadius.circular(10),
//                             ),
//                           ),
//                         ),
//                         const SizedBox(height: 20),
//                         const Center(
//                           child: Text(
//                             'RHT',
//                             style: TextStyle(
//                               fontSize: 24,
//                               fontWeight: FontWeight.bold,
//                               color: Colors.black,
//                             ),
//                           ),
//                         ),
//                         const Center(
//                           child: Text(
//                             'Rental House Taxation',
//                             style: TextStyle(
//                               fontSize: 16,
//                               color: Colors.black,
//                             ),
//                           ),
//                         ),
//                         const SizedBox(height: 20),
//                         const Center(
//                           child: Text(
//                             'Transfer Successful',
//                             style: TextStyle(
//                               fontSize: 18,
//                               fontWeight: FontWeight.bold,
//                               color: Colors.black,
//                             ),
//                           ),
//                         ),
//                         Center(
//                           child: Text(
//                             mappedTx['amount'],
//                             style: const TextStyle(
//                               fontSize: 24,
//                               fontWeight: FontWeight.bold,
//                               color: Colors.black,
//                             ),
//                           ),
//                         ),
//                         const SizedBox(height: 20),
//                         const Divider(color: Colors.black),
//                         const SizedBox(height: 10),
//                         Text(
//                           'Transaction date: ${mappedTx['date']} ${mappedTx['time']}',
//                           style: const TextStyle(fontSize: 16, color: Colors.black),
//                         ),
//                         const SizedBox(height: 10),
//                         Text(
//                           'Sender number: ${mappedTx['sender_number']}',
//                           style: const TextStyle(fontSize: 16, color: Colors.black),
//                         ),
//                         const SizedBox(height: 10),
//                         Text(
//                           'Sender name: ${mappedTx['sender_name']}',
//                           style: const TextStyle(fontSize: 16, color: Colors.black),
//                         ),
//                         const SizedBox(height: 10),
//                         Text(
//                           'House Rent: \$${mappedTx['house_rent']}',
//                           style: const TextStyle(fontSize: 16, color: Colors.black),
//                         ),
//                         const SizedBox(height: 10),
//                         Text(
//                           'Tax: \$${mappedTx['tax']}',
//                           style: const TextStyle(fontSize: 16, color: Colors.black),
//                         ),
//                         const SizedBox(height: 10),
//                         Text(
//                           'Total Amount: \$${mappedTx['payment_amount']}',
//                           style: const TextStyle(fontSize: 16, color: Colors.black),
//                         ),
//                         const SizedBox(height: 20),
//                       ],
//                     ),
//                   ),
//                   // --- Share button is OUTSIDE the Screenshot! ---
//                   Center(
//                     child: ElevatedButton.icon(
//                       icon: Icon(Icons.share, color: Colors.white),
//                       label: Text('Share Receipt', style: TextStyle(color: const Color.fromARGB(255, 213, 214, 218))),
//                       style: ElevatedButton.styleFrom(
//                         backgroundColor: Color(0xFF20124D),
//                         padding: EdgeInsets.symmetric(horizontal: 30, vertical: 12),
//                       ),
//                       onPressed: () async {
//                         try {
//                           final image = await screenshotController.capture();
//                           if (image == null) return;
//                           final directory = await getTemporaryDirectory();
//                           final imagePath = await File('${directory.path}/receipt.png').create();
//                           await imagePath.writeAsBytes(image);
//                           await Share.shareXFiles(
//                             [XFile(imagePath.path)],
//                             text: 'Check my tax payment receipt from RHT app!',
//                             subject: 'Payment Receipt',
//                           );
//                         } catch (e) {
//                           ScaffoldMessenger.of(context).showSnackBar(
//                             SnackBar(content: Text('Error sharing: $e')),
//                           );
//                         }
//                       },
//                     ),
//                   ),
//                   const Spacer(),
//                   Center(
//                     child: ElevatedButton(
//                       onPressed: () {
//                         Navigator.pop(context);
//                       },
//                       style: ElevatedButton.styleFrom(
//                         backgroundColor: const Color(0xFF20124D),
//                         padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
//                       ),
//                       child: const Text(
//                         'Close',
//                         style: TextStyle(color: Colors.white),
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           );
//         },
//       );
//     } catch (e) {
//       Navigator.of(context).pop();
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Error loading details: $e')),
//       );
//     }
//   }

//   String _convertDecimalToString(dynamic value) {
//     if (value == null) return '0';
//     if (value is int || value is double) return value.toString();
//     if (value is Map && value.containsKey(r'$numberDecimal')) {
//       return value[r'$numberDecimal'].toString();
//     }
//     final match = RegExp(r'(\d+(\.\d+)?)').firstMatch(value.toString());
//     if (match != null) return match.group(0)!;
//     return value.toString();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: const Color(0xFFF8F8F8),
//       appBar: AppBar(
//         elevation: 0,
//         backgroundColor: const Color.fromARGB(255, 22, 13, 43),
//         leading: IconButton(
//           icon: const Icon(Icons.arrow_back, color: Colors.white),
//           onPressed: () {
//             Navigator.of(context).pop();
//           },
//         ),
//         centerTitle: true,
//         title: const Text(
//           "My Transactions",
//           style: TextStyle(
//             color: Colors.white,
//             fontWeight: FontWeight.w600,
//             fontSize: 20,
//           ),
//         ),
//       ),
//       body: Column(
//         children: [
//           Padding(
//             padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16),
//             child: Row(
//               children: [
//                 _buildCircleFilterButton("All"),
//                 const SizedBox(width: 10),
//                 _buildCircleFilterButton("Last Month"),
//                 const SizedBox(width: 10),
//                 _buildCircleFilterButton("Select Date", hasArrow: true),
//               ],
//             ),
//           ),
//           if (isLoading)
//             const Center(child: CircularProgressIndicator())
//           else if (errorMessage.isNotEmpty)
//             Center(child: Text(errorMessage, style: const TextStyle(color: Colors.red)))
//           else if (transactions.isEmpty)
//             Expanded(
//               child: Center(
//                 child: Column(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: [
//                     Container(
//                       padding: const EdgeInsets.all(20),
//                       decoration: BoxDecoration(
//                         color: Colors.grey[100],
//                         shape: BoxShape.circle,
//                       ),
//                       child: Icon(
//                         Icons.receipt_long_outlined,
//                         size: 80,
//                         color: Colors.grey[400],
//                       ),
//                     ),
//                     const SizedBox(height: 24),
//                     Text(
//                       "No transactions found",
//                       style: TextStyle(
//                         fontSize: 20,
//                         fontWeight: FontWeight.w600,
//                         color: Colors.grey[700],
//                       ),
//                     ),
//                     const SizedBox(height: 8),
//                     Text(
//                       "You haven't made any transactions yet",
//                       style: TextStyle(
//                         fontSize: 16,
//                         color: Colors.grey[500],
//                       ),
//                       textAlign: TextAlign.center,
//                     ),
//                     const SizedBox(height: 32),
//                     Container(
//                       padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
//                       decoration: BoxDecoration(
//                         color: const Color(0xFF20124D),
//                         borderRadius: BorderRadius.circular(25),
//                       ),
//                       child: const Text(
//                         "Make your first payment",
//                         style: TextStyle(
//                           color: Colors.white,
//                           fontSize: 16,
//                           fontWeight: FontWeight.w500,
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             )
//           else
//             Expanded(
//               child: ListView.builder(
//                 padding: const EdgeInsets.symmetric(horizontal: 16),
//                 itemCount: transactions.length,
//                 itemBuilder: (context, index) {
//                   final tx = transactions[index];
//                   return GestureDetector(
//                     onTap: () {
//                       _showTransactionDetails(tx);
//                     },
//                     child: Padding(
//                       padding: const EdgeInsets.only(bottom: 12),
//                       child: Container(
//                         decoration: BoxDecoration(
//                           color: Colors.white,
//                           borderRadius: BorderRadius.circular(14),
//                           boxShadow: [
//                             BoxShadow(
//                               color: Colors.black.withOpacity(0.03),
//                               blurRadius: 4,
//                               offset: const Offset(0, 2),
//                             ),
//                           ],
//                         ),
//                         child: ListTile(
//                           contentPadding:
//                               const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
//                           leading: Container(
//                             decoration: const BoxDecoration(
//                               color: Color(0xFF20124D),
//                               shape: BoxShape.circle,
//                             ),
//                             width: 28,
//                             height: 28,
//                             child: const Center(
//                               child: Icon(
//                                 Icons.arrow_forward,
//                                 color: Colors.white,
//                                 size: 18,
//                               ),
//                             ),
//                           ),
//                           title: const Text(
//                             'wasaarada maaliyada',
//                             style: TextStyle(
//                               fontWeight: FontWeight.w600,
//                               fontSize: 16,
//                             ),
//                           ),
//                           subtitle: Row(
//                             children: [
//                               const Text(
//                                 "transfer ",
//                                 style: TextStyle(
//                                   color: Colors.grey,
//                                   fontSize: 13,
//                                 ),
//                               ),
//                               Text(
//                                 "${tx['date'] ?? 'N/A'} ${tx['time'] ?? 'N/A'}",
//                                 style: const TextStyle(
//                                   color: Colors.grey,
//                                   fontSize: 13,
//                                 ),
//                               ),
//                             ],
//                           ),
//                           trailing: Column(
//                             crossAxisAlignment:
//                                 CrossAxisAlignment.end,
//                             mainAxisAlignment: MainAxisAlignment.center,
//                             children: [
//                              Text(
//                               '\$${tx['payment_amount'].toString()}',
//                               style: const TextStyle(
//                                 fontWeight: FontWeight.w600,
//                                 fontSize: 15,
//                               ),
//                               ),
//                               const SizedBox(height: 3),
//                             ],
//                           ),
//                         ),
//                       ),
//                     ),
//                   );
//                 },
//               ),
//             ),



//         ],
//       ),
//     );
//   }
// }




import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:rental_house_taxation_flutter/services/api_service.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';

class TransactionsPage extends StatefulWidget {
  final String citizenId;

  const TransactionsPage({Key? key, required this.citizenId}) : super(key: key);

  @override
  _TransactionsPageState createState() => _TransactionsPageState();
}

class _TransactionsPageState extends State<TransactionsPage> {
  String selectedFilter = "All"; // Only "All" will remain
  DateTime? selectedDate;
  bool isLoading = true;
  String errorMessage = '';
  List<Map<String, dynamic>> transactions = [];

  final ScreenshotController screenshotController = ScreenshotController();

  @override
  void initState() {
    super.initState();
    fetchTransactions();
  }

  // Modify the fetch function to ensure payment_amount is correctly fetched
  Future<void> fetchTransactions() async {
    try {
      final rawResponse = await ApiService().getTransactions(widget.citizenId);

      // Check if we got an empty list (no transactions)
      if (rawResponse.isEmpty) {
        setState(() {
          transactions = [];
          isLoading = false;
          errorMessage = ''; // Clear any error message
        });
        return;
      }

      List<Map<String, dynamic>> mappedTransactions = (rawResponse as List).map((tx) {
        DateTime? paymentDate;
        String dateStr = '';
        String timeStr = '';
        if (tx['payment_date'] != null) {
          paymentDate = DateTime.tryParse(tx['payment_date']);
          if (paymentDate != null) {
            dateStr =
                "${paymentDate.day.toString().padLeft(2, '0')}.${paymentDate.month.toString().padLeft(2, '0')}.${paymentDate.year.toString().substring(2)}";
            timeStr =
                "${paymentDate.hour.toString().padLeft(2, '0')}:${paymentDate.minute.toString().padLeft(2, '0')}";
          }
        }

        // Ensure payment_amount is used here directly
        return {
          'id': tx['id'],
          'date': dateStr,
          'time': timeStr,
          'payment_amount': tx['payment_amount'] ?? 0, // Using payment_amount directly
        };
      }).toList();

      setState(() {
        transactions = mappedTransactions;
        isLoading = false;
        errorMessage = ''; // Clear any error message
      });
    } catch (e) {
      setState(() {
        errorMessage = 'Error fetching transactions: $e';
        isLoading = false;
      });
    }
  }

  Future<void> _pickDate(BuildContext context) async {
    final DateTime today = DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? today,
      firstDate: DateTime(2000),
      lastDate: DateTime(today.year + 5),
    );
    if (picked != null) {
      setState(() {
        selectedDate = picked;
        selectedFilter = "Select Date";
      });
    }
  }

  Widget _buildCircleFilterButton(String text, {bool hasArrow = false}) {
    final bool isSelected = selectedFilter == text;
    return GestureDetector(
      onTap: () {
        if (text == "Select Date") {
          _pickDate(context);
        } else {
          setState(() {
            selectedFilter = text;
            selectedDate = null;
          });
        }
      },
      child: Container(
        height: 36,
        padding: EdgeInsets.symmetric(horizontal: hasArrow ? 8 : 20),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF20124D) : const Color(0xFFEAEAF2),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              text == "Select Date" && selectedDate != null
                  ? "${selectedDate!.day.toString().padLeft(2, '0')}/${selectedDate!.month.toString().padLeft(2, '0')}/${selectedDate!.year}"
                  : text,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.black87,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
            if (hasArrow)
              Padding(
                padding: const EdgeInsets.only(left: 4.0),
                child: Icon(
                  Icons.keyboard_arrow_down,
                  size: 20,
                  color: isSelected ? Colors.white : const Color(0xFF20124D),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showTransactionDetails(Map<String, dynamic> transaction) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      final detailedTransactions = await ApiService().getDetailedTransactions(widget.citizenId);
      final detailedTx = detailedTransactions.firstWhere(
        (tx) => tx['id'] == transaction['id'],
        orElse: () => transaction,
      );

      String formattedDate = '';
      String formattedTime = '';
      if (detailedTx['payment_date'] != null) {
        DateTime? paymentDate = DateTime.tryParse(detailedTx['payment_date']);
        if (paymentDate != null) {
          formattedDate =
              "${paymentDate.day.toString().padLeft(2, '0')}.${paymentDate.month.toString().padLeft(2, '0')}.${paymentDate.year.toString().substring(2)}";
          formattedTime =
              "${paymentDate.hour.toString().padLeft(2, '0')}:${paymentDate.minute.toString().padLeft(2, '0')}";
        }
      }

      final mappedTx = {
        'id': detailedTx['id'],
        'name': detailedTx['name'] ?? 'N/A',
        'date': formattedDate,
        'time': formattedTime,
        'amount': "\$${_convertDecimalToString(detailedTx['payment_amount'])}",
        'payment_amount': _convertDecimalToString(detailedTx['payment_amount']),
        'sender_number': detailedTx['sender_number'] ?? 'N/A',
        'sender_name': detailedTx['sender_name'] ?? 'N/A',
        'house_rent': _convertDecimalToString(detailedTx['house_rent']),
        'tax': _convertDecimalToString(detailedTx['tax']),
        'total': _convertDecimalToString(detailedTx['payment_amount']),
      };

      Navigator.of(context).pop();

      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (BuildContext context) {
          return Center(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.all(16.0),
              height: MediaQuery.of(context).size.height * 0.7,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 10,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Screenshot(
                    controller: screenshotController,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 10),
                        Center(
                          child: Container(
                            width: 50,
                            height: 5,
                            decoration: BoxDecoration(
                              color: Colors.grey[300],
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Center(
                          child: Text(
                            'RHT',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                        ),
                        const Center(
                          child: Text(
                            'Rental House Taxation',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.black,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Center(
                          child: Text(
                            'Transfer Successful',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                        ),
                        Center(
                          child: Text(
                            mappedTx['amount'],
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Divider(color: Colors.black),
                        const SizedBox(height: 10),
                        Text(
                          'Transaction date: ${mappedTx['date']} ${mappedTx['time']}',
                          style: const TextStyle(fontSize: 16, color: Colors.black),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Sender number: ${mappedTx['sender_number']}',
                          style: const TextStyle(fontSize: 16, color: Colors.black),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Sender name: ${mappedTx['sender_name']}',
                          style: const TextStyle(fontSize: 16, color: Colors.black),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'House Rent: \$${mappedTx['house_rent']}',
                          style: const TextStyle(fontSize: 16, color: Colors.black),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Tax: \$${mappedTx['tax']}',
                          style: const TextStyle(fontSize: 16, color: Colors.black),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Total Amount: \$${mappedTx['payment_amount']}',
                          style: const TextStyle(fontSize: 16, color: Colors.black),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                  // --- Share button is OUTSIDE the Screenshot! ---
                  Center(
                    child: ElevatedButton.icon(
                      icon: Icon(Icons.share, color: Colors.white),
                      label: Text('Share Receipt', style: TextStyle(color: const Color.fromARGB(255, 213, 214, 218))),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF20124D),
                        padding: EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                      ),
                      onPressed: () async {
                        try {
                          final image = await screenshotController.capture();
                          if (image == null) return;
                          final directory = await getTemporaryDirectory();
                          final imagePath = await File('${directory.path}/receipt.png').create();
                          await imagePath.writeAsBytes(image);
                          await Share.shareXFiles(
                            [XFile(imagePath.path)],
                            text: 'Check my tax payment receipt from RHT app!',
                            subject: 'Payment Receipt',
                          );
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error sharing: $e')),
                          );
                        }
                      },
                    ),
                  ),
                  const Spacer(),
                  Center(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF20124D),
                        padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                      ),
                      child: const Text(
                        'Close',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    } catch (e) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading details: $e')),
      );
    }
  }

  String _convertDecimalToString(dynamic value) {
    if (value == null) return '0';
    if (value is int || value is double) return value.toString();
    if (value is Map && value.containsKey(r'$numberDecimal')) {
      return value[r'$numberDecimal'].toString();
    }
    final match = RegExp(r'(\d+(\.\d+)?)').firstMatch(value.toString());
    if (match != null) return match.group(0)!;
    return value.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color.fromARGB(255, 18, 20, 68),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        toolbarHeight: 70,
        centerTitle: true,
        title: const Text(
          "My Transactions",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16),
            child: Row(
              children: [
                _buildCircleFilterButton("All"), // Only "All" filter remains
              ],
            ),
          ),
          if (isLoading)
            const Center(child: CircularProgressIndicator())
          else if (errorMessage.isNotEmpty)
            Center(child: Text(errorMessage, style: const TextStyle(color: Colors.red)))
          else if (transactions.isEmpty)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.receipt_long_outlined,
                        size: 80,
                        color: Colors.grey[400],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      "No transactions found",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "You haven't made any transactions yet",
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[500],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF20124D),
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: const Text(
                        "Make your first payment",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: transactions.length,
                itemBuilder: (context, index) {
                  final tx = transactions[index];
                  return GestureDetector(
                    onTap: () {
                      _showTransactionDetails(tx);
                    },
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.03),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: ListTile(
                          contentPadding:
                              const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                          leading: Container(
                            decoration: const BoxDecoration(
                              color: Color.fromARGB(255, 9, 100, 33),
                              shape: BoxShape.circle,
                            ),
                            width: 28,
                            height: 28,
                            child: const Center(
                              child: Icon(
                                Icons.arrow_forward,
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
                          ),
                          title: const Text(
                            'wasaarada maaliyada',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                          subtitle: Row(
                            children: [
                              const Text(
                                "transfer ",
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 13,
                                ),
                              ),
                              Text(
                                "${tx['date'] ?? 'N/A'} ${tx['time'] ?? 'N/A'}",
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                          trailing: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.end,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                             Text(
                              '\$${tx['payment_amount'].toString()}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                              ),
                              ),
                              const SizedBox(height: 3),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
