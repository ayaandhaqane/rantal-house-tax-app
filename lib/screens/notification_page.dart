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
  String propertyId = '';
  List<dynamic> overdueNotifications = [];
  List<dynamic> upcomingNotifications = [];
  List<Map<String, dynamic>> replies = [];
  int unreadRepliesCount = 0;
  String selectedFilter = 'All'; // Default filter

  @override
  void initState() {
    super.initState();
    fetchOverdueMessages();
    fetchUpcomingMessages();
    fetchReplies();
  }

  // Fetch overdue messages
  Future<void> fetchOverdueMessages() async {
    try {
      final allMessages = await apiService.fetchMessagesForProperty();
      final overdueMessages = allMessages.where((msg) =>
          msg['messageType'] == 'overdue').toList();
      setState(() {
        overdueNotifications = overdueMessages;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = "Failed to load overdue messages: $e";
        isLoading = false;
      });
    }
  }

  // Fetch upcoming messages
  Future<void> fetchUpcomingMessages() async {
    try {
      final allMessages = await apiService.fetchMessagesForProperty();
      final upcomingMessages = allMessages.where((msg) =>
          msg['messageType'] == 'upcoming').toList();
      setState(() {
        upcomingNotifications = upcomingMessages;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = "Failed to load upcoming messages: $e";
        isLoading = false;
      });
    }
  }

  // Fetch replies for the citizen
  Future<void> fetchReplies() async {
    try {
      const String citizenId = '687b8b1fcf94b2ea8888b1fa'; // Placeholder
      final repliesData = await apiService.getRepliesForCitizen(citizenId);
      final unreadCount = await apiService.countUnreadRepliesForCitizen(citizenId);
      setState(() {
        replies = repliesData;
        unreadRepliesCount = unreadCount;
      });
    } catch (e) {
      print('Error fetching replies: $e');
    }
  }

  // Combine all notifications including replies
  List<dynamic> get filteredNotifications {
    if (selectedFilter == 'All') {
      return allNotifications;
    }
    return allNotifications.where((notification) {
      if (selectedFilter == 'Due') {
        return notification['messageType'] == 'overdue';
      } else if (selectedFilter == 'Replies') {
        return notification['type'] == 'reply';
      } else if (selectedFilter == 'News') {
        return notification['messageType'] == 'upcoming';
      }
      return false;
    }).toList();
  }

  List<dynamic> get allNotifications {
    final List<dynamic> allNotifications = [];

    // Add replies first (to make them more prominent)
    if (replies.isNotEmpty) {
      allNotifications.addAll(replies.map((reply) => {
        'type': 'reply',
        'title': 'Reply to Your Complaint',
        'content': reply['reply'] ?? 'No reply content',
        'sentAt': reply['createdAt'],
        'reply': reply,
        'isRead': false,
        'priority': 1, // Higher priority for replies
      }));
    }

    // Add overdue notifications
    allNotifications.addAll(overdueNotifications.map((notification) => {
      ...notification,
      'priority': 2, // Medium priority for overdue
    }));

    // Add upcoming notifications
    allNotifications.addAll(upcomingNotifications.map((notification) => {
      ...notification,
      'priority': 3, // Lower priority for upcoming
    }));

    // Sort by priority and then by date
    allNotifications.sort((a, b) {
      final priorityA = a['priority'] ?? 4;
      final priorityB = b['priority'] ?? 4;
      if (priorityA != priorityB) {
        return priorityA.compareTo(priorityB);
      }
      final dateA = a['sentAt'] ?? '';
      final dateB = b['sentAt'] ?? '';
      return dateB.compareTo(dateA);
    });

    return allNotifications;
  }

  Widget _buildFilterBar() {
    return Padding(
      padding: const EdgeInsets.only(top: 16.0), // Add space at the top
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround, // Space buttons evenly
        children: [
          FilterButton(
            text: 'All',
            selectedFilter: selectedFilter,
            onPressed: () {
              setState(() {
                selectedFilter = 'All';
              });
            },
          ),
          FilterButton(
            text: 'Due',
            selectedFilter: selectedFilter,
            onPressed: () {
              setState(() {
                selectedFilter = 'Due';
              });
            },
          ),
          FilterButton(
            text: 'Replies',
            selectedFilter: selectedFilter,
            onPressed: () {
              setState(() {
                selectedFilter = 'Replies';
              });
            },
          ),
          FilterButton(
            text: 'News',
            selectedFilter: selectedFilter,
            onPressed: () {
              setState(() {
                selectedFilter = 'News';
              });
            },
          ),
        ],
      ),
    );
  }

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
          elevation: 6,
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
        backgroundColor: const Color.fromARGB(255, 8, 4, 41),
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
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () {
              fetchOverdueMessages();
              fetchUpcomingMessages();
              fetchReplies();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilterBar(), // Add filter buttons in one row
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: filteredNotifications.length,
              separatorBuilder: (_, __) => const Divider(
                color: Colors.grey,
                thickness: 0.4,
                height: 16,
              ),
              itemBuilder: (context, index) {
                final item = filteredNotifications[index];
                final isReply = item['type'] == 'reply';
                final isOverdue = item['messageType'] == 'overdue';
                
                 return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.transparent,  // Set background transparent to remove the background

                    child: Image.asset(
                      isOverdue 
                        ? 'images/warning.png' // Path to warning image
                        : (isReply 
                          ? 'images/speech-bubble.png' // Path to reply image
                          : 'images/info.png'), // Path to info image
                      width: 34,  // Adjust width as needed
                      height: 100, // Adjust height as needed
                          fit: BoxFit.contain, // Ensure the image fits well inside the circle

                    ),
                  ),
                  title: Row(
                    children: [
                      Expanded(
                        child: Text(
                          item['title'] ?? 'No Title',
                          style: TextStyle(
                            fontWeight: isReply ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ),
                    ],
                  ),
                  subtitle: GestureDetector(
                    onTap: () {
                      // Navigate to the detail page and pass the notification details
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
                    child: Text(item['content'] ?? ''),
                  ),
                  trailing: Text(formatDate(item['sentAt'])),
                );
              },
            ),
          ),
        ],
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

class FilterButton extends StatelessWidget {
  final String text;
  final String selectedFilter;
  final Function onPressed;

  FilterButton({
    required this.text,
    required this.selectedFilter,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () => onPressed(),
      style: ButtonStyle(
        backgroundColor: MaterialStateProperty.all(
          selectedFilter == text ? const Color.fromARGB(255, 14, 12, 60) : Colors.grey, // Color for selected and unselected
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: selectedFilter == text ? Colors.white :  Colors.black, // Text color changes
        ),
      ),
    );
  }
}
