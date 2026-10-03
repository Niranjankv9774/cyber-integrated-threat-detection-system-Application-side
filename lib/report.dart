import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class ReportsPage extends StatefulWidget {
  const ReportsPage({super.key});

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage>
    with SingleTickerProviderStateMixin {
  List imageReports = [];
  List phishingReports = [];
  List spamReports = [];
  bool loading = true;

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    fetchReports();
  }

  Future<void> fetchReports() async {
    SharedPreferences sh = await SharedPreferences.getInstance();
    String? baseUrl = sh.getString('url');
    String? lid = sh.getString('lid');

    final response = await http.post(
      Uri.parse("$baseUrl/user_view_report/"),
      body: {'lid': lid},
    );

    final data = json.decode(response.body);

    if (data['status'] == 'ok') {
      setState(() {
        imageReports = data['image_reports'];
        phishingReports = data['phishing_reports'];
        spamReports = data['spam_reports'];
        loading = false;
      });
    } else {
      setState(() => loading = false);
    }
  }

  // ---------------- IMAGE REPORTS ----------------

  Widget buildImageReports() {
    if (imageReports.isEmpty) {
      return const Center(child: Text("No Image Reports"));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(15),
      itemCount: imageReports.length,
      itemBuilder: (context, index) {
        var item = imageReports[index];
        bool forged = item['prediction'].toString().contains("Forged") ||
            item['prediction'].toString().contains("Fake");
        int forgedCount = item['forged_count'] ?? 0;
        int totalCount = item['total_count'] ?? 0;
        List individualResults = item['individual_results'] ?? [];

        return Container(
          margin: const EdgeInsets.only(bottom: 18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: const [
              BoxShadow(color: Colors.black12, blurRadius: 10)
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image thumbnail
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                child: Image.network(
                  item['image_url'],
                  height: 180,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    height: 100,
                    color: Colors.grey.shade200,
                    child: const Center(child: Icon(Icons.broken_image, color: Colors.grey)),
                  ),
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(15),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Prediction badge + score
                    Row(
                      children: [
                        Icon(
                          forged ? Icons.gpp_maybe_rounded : Icons.verified_user_rounded,
                          color: forged ? Colors.red : Colors.green,
                          size: 22,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          item['prediction'],
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: forged ? Colors.red : Colors.green,
                          ),
                        ),
                        const Spacer(),
                        if (totalCount > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: forged ? Colors.red.withOpacity(0.08) : Colors.green.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: forged ? Colors.red.withOpacity(0.25) : Colors.green.withOpacity(0.25),
                              ),
                            ),
                            child: Text(
                              "$forgedCount/$totalCount models",
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: forged ? Colors.red.shade700 : Colors.green.shade700,
                              ),
                            ),
                          ),
                      ],
                    ),

                    const SizedBox(height: 6),
                    Text("Date: ${item['date']}", style: const TextStyle(color: Colors.grey, fontSize: 12)),

                    // Expandable model breakdown
                    if (individualResults.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Theme(
                        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                        child: ExpansionTile(
                          tilePadding: EdgeInsets.zero,
                          childrenPadding: const EdgeInsets.only(top: 6, bottom: 4),
                          title: Row(
                            children: [
                              const Icon(Icons.analytics_outlined, size: 16, color: Color(0xFF2C5364)),
                              const SizedBox(width: 6),
                              Text(
                                "View Model Breakdown (${individualResults.length})",
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF2C5364),
                                ),
                              ),
                            ],
                          ),
                          children: individualResults.map<Widget>((m) {
                            bool isForged = m['prediction'] == 'Forged';
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 3),
                              child: Row(
                                children: [
                                  Container(
                                    width: 7,
                                    height: 7,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: isForged ? Colors.red : Colors.green,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      m['model_name'] ?? 'Unknown',
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  ),
                                  if ((m['confidence'] ?? '').isNotEmpty)
                                    Text(
                                      m['confidence'],
                                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                                    ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: isForged ? Colors.red.withOpacity(0.1) : Colors.green.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      m['prediction'] ?? '',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: isForged ? Colors.red : Colors.green,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ---------------- PHISHING REPORTS ----------------

  Widget buildPhishingReports() {
    if (phishingReports.isEmpty) {
      return const Center(child: Text("No Phishing Reports"));
    }

    return ListView.builder(
      itemCount: phishingReports.length,
      itemBuilder: (context, index) {
        var item = phishingReports[index];
        String url = item['url'] ?? "";
        String pred = item['prediction'] ?? "";
        String explanation = item['explanation'] ?? "";
        String date = item['date'] ?? "";

        return Card(
          margin: const EdgeInsets.all(10),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(url, style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 5),
                Text(
                  pred,
                  style: TextStyle(
                    color: pred.toLowerCase().contains("phishing") ? Colors.red : Colors.green,
                  ),
                ),
                if (explanation.isNotEmpty) ...[
                  const SizedBox(height: 5),
                  Text(explanation),
                ],
                const SizedBox(height: 5),
                Text("Date: $date"),
              ],
            ),
          ),
        );
      },
    );
  }

  // ---------------- SPAM REPORTS ----------------

  Widget buildSpamReports() {
    if (spamReports.isEmpty) {
      return const Center(child: Text("No Spam Reports"));
    }

    return ListView.builder(
      itemCount: spamReports.length,
      itemBuilder: (context, index) {
        var item = spamReports[index];
        String emailText = item['email_text'] ?? "";
        String pred = item['prediction'] ?? "";
        String date = item['date'] ?? "";

        return Card(
          margin: const EdgeInsets.all(10),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(emailText, maxLines: 3, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 5),
                Text(
                  pred,
                  style: TextStyle(color: pred == "Spam" ? Colors.red : Colors.green),
                ),
                const SizedBox(height: 5),
                Text("Date: $date"),
              ],
            ),
          ),
        );
      },
    );
  }

  // ---------------- MAIN BUILD ----------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F3F7),
      appBar: AppBar(
        title: const Text("My Reports"),
        backgroundColor: const Color(0xFF2C5364),
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold),
          tabs: const [
            Tab(text: "Images"),
            Tab(text: "URLs"),
            Tab(text: "Emails"),
          ],
        ),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                buildImageReports(),
                buildPhishingReports(),
                buildSpamReports(),
              ],
            ),
    );
  }
}