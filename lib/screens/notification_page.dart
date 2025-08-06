import 'package:flutter/material.dart';
import 'package:rental_house_taxation_flutter/screens/notification_detail_page.dart';
import 'package:rental_house_taxation_flutter/services/api_service.dart';



class NotificationPage extends StatefulWidget {
  const NotificationPage({Key? key}) : super(key: key);

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  final ApiService apiService = ApiService();
  List<dynamic> notifications = [];
  bool isLoading = true;
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    fetchData();  
  }

  Future<void> fetchData() async {
  try {
    final response = await apiService.fetchMessages();
    print("Fetched messages: $response");

    setState(() {
      notifications = response;  // Assign the fetched data to notifications list
      isLoading = false;
    });
  } catch (e) {
    setState(() {
      errorMessage = "Failed to load messages: $e";
      isLoading = false;
    });
    print("Error: $e");
  }
}



  @override
 @override
Widget build(BuildContext context) {
  if (isLoading) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }

  if (errorMessage.isNotEmpty) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
      ),
      body: Center(child: Text(errorMessage)),
    );
  }

  return Scaffold(
    appBar: AppBar(
      backgroundColor: const Color(0xFF2D456D),
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      title: const Text(
        'Notifications',
        style: TextStyle(
          color: Colors.white,
          fontSize: 22,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
      centerTitle: true,
    ),
    body: ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: notifications.length,
      separatorBuilder: (_, __) => const Divider(
        color: Colors.grey,
        thickness: 0.4,
        height: 16,
      ),
      itemBuilder: (context, index) {
        final item = notifications[index];
        return ListTile(
          leading: CircleAvatar(
            backgroundColor:
                item['messageType'] == 'overdue' ? Colors.red : Colors.blue,
            child: Icon(
              item['messageType'] == 'overdue'
                  ? Icons.warning
                  : Icons.info,
              color: Colors.white,
            ),
          ),
          title: Text(item['title'] ?? 'No Title'),
          subtitle: GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => NotificationDetailPage(
                    title: item['title'] ?? 'No Title',
                    content: item['content'] ?? '',
                    date: formatDate(item['sentAt']),
                  ),
                ),
              );
            },
            child: Text(
              item['content'] ?? '',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.black87, fontSize: 14),
            ),
          ),
          trailing: Text(formatDate(item['sentAt'])),
        );
      },
    ),
  );
}


  String formatDate(String? dateStr) {
    if (dateStr == null) return '';
    try {
      final date = DateTime.parse(dateStr);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return '';
    }
  }
}


