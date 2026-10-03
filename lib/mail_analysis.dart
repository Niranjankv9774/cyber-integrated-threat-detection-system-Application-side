import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class SpamMailPage extends StatefulWidget {
  const SpamMailPage({super.key});

  @override
  State<SpamMailPage> createState() => _SpamMailPageState();
}

class _SpamMailPageState extends State<SpamMailPage> {
  final TextEditingController _emailController = TextEditingController();
  String? prediction;
  bool loading = false;

  Future<void> checkSpam() async {
    final emailText = _emailController.text.trim();
    if (emailText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please paste some email content')),
      );
      return;
    }

    setState(() {
      loading = true;
      prediction = null;
    });

    try {
      SharedPreferences sh = await SharedPreferences.getInstance();
      String urls = sh.getString('url').toString();
      String lid = sh.getString('lid').toString();
      final url = Uri.parse('$urls/user_email_spam_predict/');

      final response = await http.post(url, body: {
        'lid': lid,
        'email_text': emailText,
      });

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'ok') {
          setState(() {
            prediction = data['prediction'];
          });
        } else {
          _showError(data['message'] ?? 'Analysis failed');
        }
      } else {
        _showError('Server connection error');
      }
    } catch (e) {
      _showError('Connection refused: Check Server');
    } finally {
      setState(() => loading = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.redAccent),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      appBar: AppBar(
        title: const Text("Spam Analysis", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF2C5364),
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            /// 🛡️ HEADER SECTION
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(25),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF2C5364), Color(0xFF0F2027)],
                ),
                borderRadius: BorderRadius.circular(25),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10)],
              ),
              child: const Column(
                children: [
                  Text(
                    "Spam Detector AI",
                    style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900),
                  ),
                  Text(
                    "Analyze email text for phishing or spam patterns",
                    textAlign: TextAlign.center,
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
                borderRadius: BorderRadius.circular(25),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20)],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Email Content", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2C5364))),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _emailController,
                    maxLines: 8,
                    style: const TextStyle(fontSize: 14),
                    decoration: InputDecoration(
                      hintText: "Paste the email body text here...",
                      hintStyle: TextStyle(color: Colors.grey.shade400),
                      filled: true,
                      fillColor: const Color(0xFFF1F4F9),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: const BorderSide(color: Color(0xFF2C5364), width: 1.5),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: loading ? null : checkSpam,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2C5364),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                        elevation: 4,
                      ),
                      child: loading
                          ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
                      )
                          : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.analytics_outlined, size: 20),
                          SizedBox(width: 10),
                          Text("SCAN CONTENT", style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.1)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 25),

            /// 📊 RESULT SECTION
            if (prediction != null)
              TweenAnimationBuilder(
                duration: const Duration(milliseconds: 500),
                tween: Tween<double>(begin: 0, end: 1),
                builder: (context, double value, child) {
                  return Opacity(
                    opacity: value,
                    child: Transform.translate(
                      offset: Offset(0, 20 * (1 - value)),
                      child: child,
                    ),
                  );
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(25),
                  decoration: BoxDecoration(
                    color: prediction?.toLowerCase() == "spam"
                        ? const Color(0xFFFFEBEE)
                        : const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(25),
                    border: Border.all(
                      color: prediction?.toLowerCase() == "spam" ? Colors.redAccent : Colors.green,
                      width: 2,
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        prediction?.toLowerCase() == "spam"
                            ? Icons.report_problem_rounded
                            : Icons.check_circle_rounded,
                        size: 48,
                        color: prediction?.toLowerCase() == "spam" ? Colors.red : Colors.green,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        "RESULT: ${prediction?.toUpperCase()}",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: prediction?.toLowerCase() == "spam" ? Colors.red.shade900 : Colors.green.shade900,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        prediction?.toLowerCase() == "spam"
                            ? "Warning: This content matches spam signatures."
                            : "Analysis suggests this email is safe.",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: prediction?.toLowerCase() == "spam" ? Colors.red.shade700 : Colors.green.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}