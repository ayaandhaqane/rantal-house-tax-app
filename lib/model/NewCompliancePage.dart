import 'dart:ui'; // <-- Import for BackdropFilter
import 'package:flutter/material.dart';
import '../services/api_service.dart';

class NewComplianceDialog extends StatefulWidget {
  final String citizenId;
  final String propertyId;

  const NewComplianceDialog({
    Key? key,
    required this.citizenId,
    required this.propertyId,
  }) : super(key: key);

  @override
  State<NewComplianceDialog> createState() => _NewComplianceDialogState();
}

class _NewComplianceDialogState extends State<NewComplianceDialog> {
  final TextEditingController descriptionController = TextEditingController();
  final ApiService apiService = ApiService();

  bool isSubmitting = false;

  Future<void> submitCompliance() async {
    if (descriptionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter compliance description.',)),
      );
      return;
    }

    setState(() {
      isSubmitting = true;
    });

    try {
      await apiService.submitComplaint(
        citizenId: widget.citizenId,
        propertyId: widget.propertyId,
        complaintDescription: descriptionController.text.trim(),
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Compliance submitted successfully!')),
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to submit compliance: $e')),
      );
    } finally {
      setState(() {
        isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // The blur effect behind the dialog
        BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 2.5, sigmaY: 2.0),
          child: Container(
            color: Colors.black.withOpacity(0.3), // semi-transparent overlay
          ),
        ),
        Center(
          child: AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: const Text('New Compliance'),
            content: TextField(
              controller: descriptionController,
              maxLines: 6,
              decoration: const InputDecoration(
                hintText: 'Enter your compliance...',
                hintStyle: TextStyle(color: Colors.grey),
                border: OutlineInputBorder(),
              ),
            ),
            actions: [
              TextButton(
                onPressed: isSubmitting ? null : () => Navigator.of(context).pop(false),
                 style: TextButton.styleFrom(
                    foregroundColor: Color.fromARGB(255, 161, 46, 46), // Purple color for Cancel text
                  ),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: isSubmitting ? null : submitCompliance,
                 style: ElevatedButton.styleFrom(
                    backgroundColor: Color.fromARGB(255, 19, 11, 54), 
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                child: isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2,color: Colors.indigo,),
                      )
                    : const Text('Submit',),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
