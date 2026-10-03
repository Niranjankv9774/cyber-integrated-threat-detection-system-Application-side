import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class PhishingDetectionPage extends StatefulWidget {
  const PhishingDetectionPage({super.key});

  @override
  State<PhishingDetectionPage> createState() => _PhishingDetectionPageState();
}

class _PhishingDetectionPageState extends State<PhishingDetectionPage> {
  final TextEditingController urlController = TextEditingController();
  bool loading = false;

  String? prediction;
  String? confidence;
  String? reason;

  Future<void> analyzeUrl() async {
    if (urlController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter a URL")),
      );
      return;
    }

    setState(() {
      loading = true;
      prediction = null;
      confidence = null;
      reason = null;
    });

    try {
      SharedPreferences sh = await SharedPreferences.getInstance();
      String urls = sh.getString('url').toString();
      String lid = sh.getString('lid').toString();

      final response = await http.post(
        Uri.parse('$urls/user_check_url/'),
        body: {"url_data": urlController.text, "lid": lid},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          setState(() {
            prediction = data['current_scan']['prediction'];
            confidence = data['current_scan']['confidence_score'].toString();
            reason = data['current_scan']['reason'];
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(data['message'] ?? "Error")),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Server Error")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Connection failed: $e")),
      );
    } finally {
      setState(() {
        loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      appBar: AppBar(
        title: const Text("URL Scan", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF2C5364),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            /// 🛡️ HEADER SECTION
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 25, horizontal: 20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF2C5364), Color(0xFF0F2027)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF2C5364).withOpacity(0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  )
                ],
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Phishing Shield",
                    style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 5),
                  Text(
                    "Analyze suspicious links to identify fraudulent websites before you click.",
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 25),

            /// 📝 INPUT SECTION
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 10)),
                ],
              ),
              child: Column(
                children: [
                  TextField(
                    controller: urlController,
                    style: const TextStyle(fontSize: 15),
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.search, color: Color(0xFF2C5364)),
                      hintText: "https://example.com",
                      labelText: "Website URL",
                      filled: true,
                      fillColor: const Color(0xFFF1F4F9),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: const BorderSide(color: Color(0xFF2C5364), width: 1),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                        elevation: 0,
                      ),
                      onPressed: loading ? null : analyzeUrl,
                      child: loading
                          ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                          : const Text("Check Authenticity", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 25),

            /// 📊 RESULT SECTION
            if (prediction != null) _buildResultDisplay(),
          ],
        ),
      ),
    );
  }

  Widget _buildResultDisplay() {
    bool isPhishing = prediction?.toUpperCase() == "PHISHING";
    double confVal = (double.tryParse(confidence ?? "0") ?? 0) / 100;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isPhishing ? const Color(0xFFFFEBEE) : const Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: isPhishing ? Colors.red.shade200 : Colors.green.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(isPhishing ? Icons.dangerous_rounded : Icons.verified_rounded,
                  color: isPhishing ? Colors.red : Colors.green, size: 30),
              const SizedBox(width: 10),
              Text(
                prediction!,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: isPhishing ? Colors.red : Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          Text("AI Confidence: $confidence%",
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: confVal,
              minHeight: 10,
              backgroundColor: Colors.white,
              valueColor: AlwaysStoppedAnimation<Color>(isPhishing ? Colors.red : Colors.green),
            ),
          ),

          const Padding(
            padding: EdgeInsets.symmetric(vertical: 15),
            child: Divider(),
          ),

          const Text("Detailed Reason:",
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black54, fontSize: 12)),
          const SizedBox(height: 5),
          Text(
            reason ?? "No details provided.",
            style: const TextStyle(fontSize: 14, height: 1.4, color: Colors.black87),
          ),
        ],
      ),
    );
  }
}