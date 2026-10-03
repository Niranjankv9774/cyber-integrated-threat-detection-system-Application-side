import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'login.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final firstnameController = TextEditingController();
  final lastnameController = TextEditingController();
  final usernameController = TextEditingController();
  final phoneController = TextEditingController();
  final emailController = TextEditingController();
  final addressController = TextEditingController();
  final placeController = TextEditingController();
  final passwordController = TextEditingController();

  String? gender;
  bool _obscurePassword = true;
  XFile? photo;
  final ImagePicker picker = ImagePicker();

  Future pickPhoto() async {
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() => photo = image);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      body: Stack(
        children: [
          /// 🔵 TOP DESIGN SECTION
          Container(
            height: MediaQuery.of(context).size.height * 0.35,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF2C5364), Color(0xFF0F2027)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(50)),
            ),
          ),

          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(25),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    const SizedBox(height: 50),
                    const Text(
                      "Create Account",
                      style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 1.2),
                    ),
                    const Text("Join the Cyber-Integrated System", style: TextStyle(color: Colors.white70)),

                    const SizedBox(height: 30),

                    /// 🔌 REGISTRATION CARD
                    Container(
                      constraints: const BoxConstraints(maxWidth: 500),
                      padding: const EdgeInsets.all(30),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(35),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 25, offset: const Offset(0, 15))],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          /// PROFILE PHOTO PICKER
                          Center(
                            child: Stack(
                              children: [
                                CircleAvatar(
                                  radius: 50,
                                  backgroundColor: const Color(0xFFF1F4F9),
                                  backgroundImage: photo != null
                                      ? (kIsWeb ? NetworkImage(photo!.path) : FileImage(File(photo!.path)) as ImageProvider)
                                      : null,
                                  child: photo == null ? const Icon(Icons.person, size: 50, color: Color(0xFF2C5364)) : null,
                                ),
                                PositionByPadding(
                                  padding: const EdgeInsets.only(top: 65, left: 65),
                                  child: FloatingActionButton.small(
                                    heroTag: "btn1",
                                    backgroundColor: const Color(0xFF2C5364),
                                    onPressed: pickPhoto,
                                    child: const Icon(Icons.camera_alt, color: Colors.white, size: 18),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 30),

                          _buildInput(firstnameController, "First Name", Icons.person),
                          const SizedBox(height: 15),
                          _buildInput(lastnameController, "Last Name", Icons.person_outline),
                          const SizedBox(height: 20),

                          const Text("Gender", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2C5364))),
                          Column(
                            children: [
                              Row(
                                children: [
                                  Radio<String>(value: 'male', groupValue: gender, onChanged: (v) => setState(() => gender = v)),
                                  const Text("Male"),
                                ],
                              ),
                              Row(
                                children: [
                                  Radio<String>(value: 'female', groupValue: gender, onChanged: (v) => setState(() => gender = v)),
                                  const Text("Female"),
                                ],
                              ),
                              Row(
                                children: [
                                  Radio<String>(value: 'other', groupValue: gender, onChanged: (v) => setState(() => gender = v)),
                                  const Text("Other"),
                                ],
                              ),
                            ],
                          ),

                          const SizedBox(height: 15),
                          _buildInput(usernameController, "Username", Icons.account_circle),
                          const SizedBox(height: 15),
                          _buildInput(phoneController, "Phone", Icons.phone, type: TextInputType.phone),
                          const SizedBox(height: 15),
                          _buildInput(emailController, "Email", Icons.email, type: TextInputType.emailAddress),
                          const SizedBox(height: 15),
                          _buildInput(addressController, "Address", Icons.home),
                          const SizedBox(height: 15),
                          _buildInput(placeController, "Place", Icons.location_on),
                          const SizedBox(height: 15),
                          _buildInput(
                              passwordController,
                              "Password",
                              Icons.lock,
                              obscure: _obscurePassword,
                              suffix: IconButton(
                                icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, size: 20),
                                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                              )
                          ),

                          const SizedBox(height: 30),

                          SizedBox(
                            width: double.infinity,
                            height: 55,
                            child: ElevatedButton(
                              onPressed: sendData,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF2C5364),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                                elevation: 4,
                              ),
                              child: const Text("REGISTER NOW", style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.2)),
                            ),
                          ),

                          Center(
                            child: TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text("Already have an account? Login", style: TextStyle(color: Color(0xFF2C5364), fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInput(TextEditingController controller, String label, IconData icon,
      {TextInputType type = TextInputType.text, bool obscure = false, Widget? suffix}) {
    return TextFormField(
      controller: controller,
      keyboardType: type,
      obscureText: obscure,
      validator: (value) {
        if (value == null || value.trim().isEmpty) return "Please enter $label";
        if (label == "Email" && !RegExp(r'\S+@\S+\.\S+').hasMatch(value)) return "Enter a valid email";
        if (label == "Phone" && value.length < 10) return "Enter valid phone number";
        return null;
      },
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: const Color(0xFF2C5364)),
        suffixIcon: suffix,
        labelText: label,
        labelStyle: const TextStyle(fontSize: 14, color: Colors.grey),
        filled: true,
        fillColor: const Color(0xFFF1F4F9),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: const BorderSide(color: Color(0xFF2C5364))),
      ),
    );
  }

  void sendData() async {
    if (photo == null) {
      Fluttertoast.showToast(msg: 'Please pick a profile photo');
      return;
    }
    if (gender == null) {
      Fluttertoast.showToast(msg: 'Please select gender');
      return;
    }

    if (_formKey.currentState!.validate()) {
      SharedPreferences sh = await SharedPreferences.getInstance();
      String url = sh.getString('url') ?? '';
      final uri = Uri.parse('$url/user_register/');

      var request = http.MultipartRequest('POST', uri);
      request.fields['firstname'] = firstnameController.text;
      request.fields['lastname'] = lastnameController.text;
      request.fields['gender'] = gender!;
      request.fields['email'] = emailController.text;
      request.fields['address'] = addressController.text;
      request.fields['phone'] = phoneController.text;
      request.fields['place'] = placeController.text;
      request.fields['username'] = usernameController.text;
      request.fields['password'] = passwordController.text;

      if (kIsWeb) {
        var bytes = await photo!.readAsBytes();
        request.files.add(http.MultipartFile.fromBytes('photo', bytes, filename: photo!.name));
      } else {
        request.files.add(await http.MultipartFile.fromPath('photo', photo!.path));
      }

      try {
        final streamedResponse = await request.send();
        final response = await http.Response.fromStream(streamedResponse);

        if (response.statusCode == 200) {
          var data = jsonDecode(response.body);
          if (data['status'] == 'ok') {
            Fluttertoast.showToast(msg: 'Registration successful');
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LoginPage()));
          } else {
            Fluttertoast.showToast(msg: data['message'] ?? 'Error');
          }
        }
      } catch (e) {
        Fluttertoast.showToast(msg: "Connection error");
      }
    }
  }
}

/// Simple helper to position the camera icon on the avatar
class PositionByPadding extends StatelessWidget {
  final EdgeInsets padding;
  final Widget child;
  const PositionByPadding({super.key, required this.padding, required this.child});
  @override
  Widget build(BuildContext context) => Padding(padding: padding, child: child);
}