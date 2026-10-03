import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ComplaintPage extends StatefulWidget {
  const ComplaintPage({super.key});

  @override
  State<ComplaintPage> createState() => _ComplaintPageState();
}

class _ComplaintPageState extends State<ComplaintPage> {
  final TextEditingController complaintController = TextEditingController();
  List complaints = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchComplaints();
  }

  /// 🔹 Fetch Complaints
  Future<void> fetchComplaints() async {
    SharedPreferences sh = await SharedPreferences.getInstance();
    String url = sh.getString('url') ?? "";
    String lid = sh.getString('lid') ?? "";

    final uri = Uri.parse("$url/user_view_complaint/");

    try {
      final response = await http.post(uri, body: {
        'lid': lid,
      });

      var data = jsonDecode(response.body);

      if (data['status'] == 'ok') {
        setState(() {
          complaints = data['data'];
          isLoading = false;
        });
      }
    } catch (e) {
      print(e);
    }
  }

  /// 🔹 Send Complaint
  Future<void> sendComplaint() async {
    if (complaintController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter complaint")),
      );
      return;
    }

    SharedPreferences sh = await SharedPreferences.getInstance();
    String url = sh.getString('url') ?? "";
    String lid = sh.getString('lid') ?? "";

    final uri = Uri.parse("$url/user_sent_complaint/");

    try {
      final response = await http.post(uri, body: {
        'lid': lid,
        'message': complaintController.text,
      });

      var data = jsonDecode(response.body);

      if (data['status'] == 'ok') {
        complaintController.clear();
        fetchComplaints();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Complaint Sent Successfully")),
        );
      }
    } catch (e) {
      print(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2C5364),
        foregroundColor: Colors.white,
        title: const Text(
          "Support Center",
          style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.1),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: Column(
        children: [
          /// 🔹 SEND SECTION (Modern Input Header)
          Container(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
            decoration: const BoxDecoration(
              color: Color(0xFF2C5364),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(35),
                bottomRight: Radius.circular(35),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(left: 5, bottom: 10),
                  child: Text(
                    "Submit a new ticket",
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ),
                TextField(
                  controller: complaintController,
                  maxLines: 3,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: "Describe the issue or feedback...",
                    hintStyle: const TextStyle(color: Colors.white38),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.08),
                    contentPadding: const EdgeInsets.all(20),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: const BorderSide(color: Colors.cyanAccent, width: 1),
                    ),
                  ),
                ),
                const SizedBox(height: 15),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.cyanAccent,
                      foregroundColor: const Color(0xFF2C5364),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    onPressed: sendComplaint,
                    child: const Text(
                      "Submit Complaint",
                      style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),

          /// 🔹 LIST HEADER
          Padding(
            padding: const EdgeInsets.fromLTRB(25, 20, 25, 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Recent Tickets",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2C5364),
                  ),
                ),
                IconButton(
                  onPressed: fetchComplaints,
                  icon: const Icon(Icons.refresh, color: Color(0xFF2C5364), size: 20),
                )
              ],
            ),
          ),

          /// 🔹 LIST SECTION
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF2C5364)))
                : complaints.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.mark_chat_read_outlined, size: 60, color: Colors.grey.withOpacity(0.5)),
                  const SizedBox(height: 10),
                  const Text("No active complaints", style: TextStyle(color: Colors.grey)),
                ],
              ),
            )
                : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: complaints.length,
              itemBuilder: (context, index) {
                var item = complaints[index];
                bool isPending = item['status'] == "Pending";

                return Container(
                  margin: const EdgeInsets.only(bottom: 15),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(25),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(25),
                    child: Theme(
                      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                      child: ExpansionTile(
                        tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        leading: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: isPending ? Colors.orange.withOpacity(0.1) : Colors.green.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isPending ? Icons.pending_actions : Icons.check_circle_outline,
                            color: isPending ? Colors.orange : Colors.green,
                            size: 20,
                          ),
                        ),
                        title: Text(
                          item['message'],
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                        subtitle: Text(
                          item['date'],
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Divider(),
                                const Text(
                                  "Your Message:",
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey),
                                ),
                                const SizedBox(height: 5),
                                Text(item['message'], style: const TextStyle(fontSize: 14)),
                                const SizedBox(height: 15),
                                const Text(
                                  "Admin Response:",
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey),
                                ),
                                const SizedBox(height: 5),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(15),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF1F4F9),
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                  child: Text(
                                    (item['reply'] != null && item['reply'].toString().isNotEmpty)
                                        ? item['reply']
                                        : "No response yet. Our team is looking into it.",
                                    style: TextStyle(
                                      color: const Color(0xFF2C5364),
                                      fontStyle: (item['reply'] == null) ? FontStyle.italic : FontStyle.normal,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )
                        ],
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