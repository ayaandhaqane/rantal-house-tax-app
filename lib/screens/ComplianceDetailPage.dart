import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ComplianceDetailPage extends StatelessWidget {
  final Map<String, dynamic> compliance;

  const ComplianceDetailPage({Key? key, required this.compliance}) : super(key: key);

  String formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('MMM d, yyyy h:mm a').format(date);
    } catch (e) {
      return dateStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    final description = compliance['complaint_description'] ?? 'No description';
    final rawDate = compliance['createdAt'] ?? '';
    final formattedDate = rawDate.isNotEmpty ? formatDate(rawDate) : 'No date';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Compliance Details'),
        centerTitle: true,
        backgroundColor: const Color.fromARGB(255, 74, 61, 133), // purple color
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Date:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 4),
            Text(
              formattedDate,
              style: const TextStyle(color: Color.fromARGB(255, 6, 6, 7), fontSize: 15),
            ),
            const SizedBox(height: 24),
            const Text(
              'Description:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: Colors.grey.shade200,
                border: const Border(
                  left: BorderSide(width: 5, color: Color.fromARGB(255, 24, 0, 238)), // left purple border
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              child: Text(
                description,
                style: const TextStyle(fontSize: 15, color: Colors.black87),
              ),
            ),
          ],
        ),
      ),
      backgroundColor: Colors.white,
    );
  }
}
