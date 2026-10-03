import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  List notifications = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    fetchNotifications();
  }

  Future<void> fetchNotifications() async {
    SharedPreferences sh = await SharedPreferences.getInstance();
    String url = sh.getString('url') ?? "";
    String lid = sh.getString('lid') ?? "";

    final urls = Uri.parse('$url/user_view_notifications/');

    try {
      final response = await http.post(urls, body: {'lid': lid});
      var data = jsonDecode(response.body);

      if (data['status'] == 'ok') {
        setState(() {
          notifications = data['data'];
          loading = false;
        });
      }
    } catch (e) {
      debugPrint("Fetch Error: $e");
      setState(() => loading = false);
    }
  }

  Future<void> markAsRead(String nid, int index) async {
    // Optimistic Update: Change UI immediately for better feel
    setState(() {
      notifications[index]['is_read'] = true;
    });

    SharedPreferences sh = await SharedPreferences.getInstance();
    String url = sh.getString('url') ?? "";
    String lid = sh.getString('lid') ?? "";

    final urls = Uri.parse('$url/user_mark_notification_read/');

    try {
      await http.post(urls, body: {'nid': nid, 'lid': lid});
    } catch (e) {
      debugPrint("Mark Read Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      appBar: AppBar(
        title: const Text(
          "Notifications",
          style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.1),
        ),
        elevation: 0,
        foregroundColor: Colors.white,
        backgroundColor: const Color(0xFF2C5364),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() => loading = true);
              fetchNotifications();
            },
          )
        ],
      ),
      body: loading
          ? const Center(
        child: CircularProgressIndicator(
          color: Color(0xFF2C5364),
        ),
      )
          : RefreshIndicator(
        onRefresh: fetchNotifications,
        color: const Color(0xFF2C5364),
        child: notifications.isEmpty
            ? _buildEmptyState()
            : ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          itemCount: notifications.length,
          itemBuilder: (context, index) {
            var item = notifications[index];
            bool isRead = item['is_read'] == true || item['is_read'] == 1;

            return _buildNotificationCard(item, isRead, index);
          },
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return ListView( // Wrap in ListView to allow RefreshIndicator to work
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.3),
        const Center(
          child: Column(
            children: [
              Icon(Icons.notifications_none_rounded, size: 80, color: Colors.grey),
              SizedBox(height: 15),
              Text(
                "Inbox is clean!",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey),
              ),
              Text("We'll notify you when something happens.", style: TextStyle(color: Colors.grey)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNotificationCard(var item, bool isRead, int index) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isRead ? Colors.white : const Color(0xFFE8F0FE).withOpacity(0.5),
        borderRadius: BorderRadius.circular(20),
        border: isRead ? null : Border.all(color: const Color(0xFF2C5364).withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => markAsRead(item['id'].toString(), index),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// STATUS ICON
                Container(
                  height: 48,
                  width: 48,
                  decoration: BoxDecoration(
                    color: isRead ? const Color(0xFFF1F4F9) : const Color(0xFF2C5364),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isRead ? Icons.notifications_none_rounded : Icons.notifications_active_rounded,
                    color: isRead ? Colors.grey : Colors.white,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 16),

                /// CONTENT
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              item['title'],
                              style: TextStyle(
                                fontWeight: isRead ? FontWeight.w600 : FontWeight.w900,
                                fontSize: 16,
                                color: isRead ? Colors.black87 : const Color(0xFF2C5364),
                              ),
                            ),
                          ),
                          if (!isRead)
                            Container(
                              height: 10,
                              width: 10,
                              decoration: const BoxDecoration(
                                color: Colors.orangeAccent,
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item['message'],
                        style: TextStyle(
                          color: isRead ? Colors.black54 : Colors.black,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          const Icon(Icons.access_time, size: 12, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text(
                            item['created_at'],
                            style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}