import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';

class ImageAnalysisPage extends StatefulWidget {
  const ImageAnalysisPage({super.key});

  @override
  State<ImageAnalysisPage> createState() => _ImageAnalysisPageState();
}

class _ImageAnalysisPageState extends State<ImageAnalysisPage> {
  File? _image;
  String? prediction;
  int forgedCount = 0;
  int totalCount = 0;
  List individualResults = [];
  bool loading = false;

  final picker = ImagePicker();

  Future<void> pickImage() async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
        prediction = null;
        individualResults = [];
        forgedCount = 0;
        totalCount = 0;
      });
    }
  }

  Future<void> analyzeImage() async {
    if (_image == null) return;

    setState(() {
      loading = true;
      prediction = null;
      individualResults = [];
      forgedCount = 0;
      totalCount = 0;
    });

    try {
      SharedPreferences sh = await SharedPreferences.getInstance();
      String urls = sh.getString('url').toString();
      String lid = sh.getString('lid').toString();
      final url = Uri.parse('$urls/user_image_check/');

      final request = http.MultipartRequest('POST', url);
      request.fields['lid'] = lid;
      request.files.add(await http.MultipartFile.fromPath('photo', _image!.path));

      final response = await request.send();
      final resBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final data = json.decode(resBody);
        if (data['status'] == 'ok') {
          setState(() {
            prediction = data['prediction'];
            forgedCount = data['forged_count'] ?? 0;
            totalCount = data['total_count'] ?? 0;
            individualResults = data['individual_results'] ?? [];
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(data['message'] ?? 'Error')),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Server error')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Connection failed: $e')),
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
        title: const Text("Image Scan", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF2C5364),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            /// 🛡️ HEADER
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
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Deep Scan Analysis",
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 4),
                  Text(
                    "Upload any digital image to verify its authenticity using 19 detection models.",
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 25),

            /// 🖼️ UPLOAD CARD
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 10)),
                ],
              ),
              child: Column(
                children: [
                  GestureDetector(
                    onTap: pickImage,
                    child: _image != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: Image.file(_image!, height: 250, width: double.infinity, fit: BoxFit.cover),
                          )
                        : Container(
                            height: 200,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F4F9),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.grey.shade300, width: 1.5),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add_photo_alternate_outlined, size: 50, color: Colors.grey.shade400),
                                const SizedBox(height: 10),
                                Text("Select image for verification", style: TextStyle(color: Colors.grey.shade600)),
                              ],
                            ),
                          ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: pickImage,
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                            side: const BorderSide(color: Color(0xFF2C5364)),
                            foregroundColor: const Color(0xFF2C5364),
                          ),
                          child: const Text("Change Image"),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: loading ? null : analyzeImage,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                          ),
                          child: loading
                              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : const Text("Run Scan"),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 25),

            /// 📊 RESULT SECTION
            if (prediction != null) ...[
              _buildVerdictCard(),
              if (individualResults.isNotEmpty) ...[
                const SizedBox(height: 20),
                _buildModelBreakdownCard(),
              ],
            ],
          ],
        ),
      ),
    );
  }

  /// Main verdict card with score
  Widget _buildVerdictCard() {
    bool isFake = prediction?.toLowerCase() == "forged" || prediction?.toLowerCase() == "fake";
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isFake ? const Color(0xFFFFEBEE) : const Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: (isFake ? Colors.red : Colors.green).withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
          )
        ],
      ),
      child: Column(
        children: [
          Icon(
            isFake ? Icons.gpp_maybe_rounded : Icons.verified_user_rounded,
            color: isFake ? Colors.red : Colors.green,
            size: 54,
          ),
          const SizedBox(height: 8),
          Text(
            "Detection Status",
            style: TextStyle(
              color: isFake ? Colors.red.shade800 : Colors.green.shade800,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            prediction!.toUpperCase(),
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: isFake ? Colors.red : Colors.green,
            ),
          ),
          if (totalCount > 0) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
              decoration: BoxDecoration(
                color: isFake ? Colors.red.withOpacity(0.1) : Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isFake ? Colors.red.withOpacity(0.3) : Colors.green.withOpacity(0.3),
                ),
              ),
              child: Text(
                "$forgedCount / $totalCount models say Forged",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: isFake ? Colors.red.shade700 : Colors.green.shade700,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Per-model breakdown card
  Widget _buildModelBreakdownCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 6)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.analytics_outlined, size: 20, color: Color(0xFF2C5364)),
              const SizedBox(width: 8),
              const Text(
                "Model-by-Model Breakdown",
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF2C5364)),
              ),
              const Spacer(),
              Text(
                "${individualResults.length} models",
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1),
          const SizedBox(height: 10),
          ...individualResults.map((m) {
            bool isForged = m['prediction'] == 'Forged';
            String modelName = m['model_name'] ?? 'Unknown';
            String confidence = m['confidence'] ?? '';
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isForged ? Colors.red : Colors.green,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      modelName,
                      style: const TextStyle(fontSize: 13, color: Colors.black87),
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (confidence.isNotEmpty)
                    Text(
                      confidence,
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: isForged ? Colors.red.withOpacity(0.1) : Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isForged ? Colors.red.withOpacity(0.3) : Colors.green.withOpacity(0.3),
                      ),
                    ),
                    child: Text(
                      m['prediction'] ?? '',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: isForged ? Colors.red : Colors.green,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}