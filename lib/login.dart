import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart';
import 'home.dart';
import 'signup.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController usernamecontroller = TextEditingController();
  final TextEditingController passwordcontroller = TextEditingController();

  // State variable to toggle password visibility
  bool _obscureText = true;

  // Pattern for password validation
  final RegExp passwordPattern =
  RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&]).{8,}$');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      body: Stack(
        children: [
          /// 🔵 THEMED HEADER GRADIENT
          Container(
            height: MediaQuery.of(context).size.height * 0.45,
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
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  /// 🛡️ SECURITY ICON
                  Container(
                    height: 100,
                    width: 100,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.lock_person_rounded,
                      size: 50,
                      color: Color(0xFF2C5364),
                    ),
                  ),

                  const SizedBox(height: 25),

                  const Text(
                    "Welcome Back",
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 1.2,
                    ),
                  ),

                  const Text(
                    "Secure Login to System",
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white70,
                    ),
                  ),

                  const SizedBox(height: 40),

                  /// 🔑 LOGIN CARD
                  Container(
                    constraints: const BoxConstraints(maxWidth: 400),
                    padding: const EdgeInsets.all(30),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(35),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 25,
                          offset: const Offset(0, 15),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel("Username"),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: usernamecontroller,
                          decoration: _buildInputDecoration(
                            Icons.person_outline_rounded,
                            "Enter username",
                          ),
                        ),

                        const SizedBox(height: 20),

                        _buildLabel("Password"),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: passwordcontroller,
                          obscureText: _obscureText,
                          decoration: _buildInputDecoration(
                            Icons.lock_outline_rounded,
                            "Enter password",
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscureText ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                color: const Color(0xFF2C5364),
                                size: 20,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscureText = !_obscureText;
                                });
                              },
                            ),
                          ),
                        ),

                        /// 🆕 FORGOT PASSWORD LINK
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: _showForgotPasswordDialog,
                            child: const Text(
                              "Forgot Password?",
                              style: TextStyle(
                                color: Color(0xFF2C5364),
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        SizedBox(
                          width: double.infinity,
                          height: 55,
                          child: ElevatedButton(
                            onPressed: sent_data,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2C5364),
                              foregroundColor: Colors.white,
                              elevation: 4,
                              shadowColor: const Color(0xFF2C5364).withOpacity(0.4),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                            ),
                            child: const Text(
                              "ACCESS ACCOUNT",
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 15),

                        Center(
                          child: TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const SignUpPage()),
                              );
                            },
                            child: RichText(
                              text: const TextSpan(
                                text: "New user? ",
                                style: TextStyle(color: Colors.black54),
                                children: [
                                  TextSpan(
                                    text: "Create Account",
                                    style: TextStyle(
                                      color: Color(0xFF2C5364),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 🛠️ DIALOG UI FOR PASSWORD RESET
  void _showForgotPasswordDialog() {
    final TextEditingController userCtrl = TextEditingController();
    final TextEditingController emailCtrl = TextEditingController();
    final TextEditingController passCtrl = TextEditingController();
    final TextEditingController confirmPassCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        // StatefulBuilder so eye-icon toggles refresh only the dialog
        bool obscurePass    = true;
        bool obscureConfirm = true;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
              title: const Text(
                "Reset Password",
                style: TextStyle(color: Color(0xFF2C5364), fontWeight: FontWeight.bold),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text("Enter your details to reset password", style: TextStyle(fontSize: 12, color: Colors.grey)),
                    const SizedBox(height: 15),
                    _buildDialogField(userCtrl, "Username", Icons.person_outline),
                    const SizedBox(height: 12),
                    _buildDialogField(emailCtrl, "Email", Icons.email_outlined),
                    const SizedBox(height: 12),
                    // New Password with toggle
                    TextField(
                      controller: passCtrl,
                      obscureText: obscurePass,
                      style: const TextStyle(fontSize: 14),
                      decoration: _buildInputDecoration(
                        Icons.lock_outline,
                        "New Password",
                        suffixIcon: IconButton(
                          icon: Icon(
                            obscurePass ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                            color: const Color(0xFF2C5364),
                            size: 20,
                          ),
                          onPressed: () => setDialogState(() => obscurePass = !obscurePass),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Confirm Password with toggle
                    TextField(
                      controller: confirmPassCtrl,
                      obscureText: obscureConfirm,
                      style: const TextStyle(fontSize: 14),
                      decoration: _buildInputDecoration(
                        Icons.lock_reset,
                        "Confirm Password",
                        suffixIcon: IconButton(
                          icon: Icon(
                            obscureConfirm ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                            color: const Color(0xFF2C5364),
                            size: 20,
                          ),
                          onPressed: () => setDialogState(() => obscureConfirm = !obscureConfirm),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2C5364),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    _forgotPasswordLogic(
                      userCtrl.text.trim(),
                      emailCtrl.text.trim(),
                      passCtrl.text.trim(),
                      confirmPassCtrl.text.trim(),
                    );
                  },
                  child: const Text("Reset", style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  /// 🛠️ HELPER FOR DIALOG FIELDS
  Widget _buildDialogField(TextEditingController controller, String hint, IconData icon, {bool obscure = false}) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      decoration: _buildInputDecoration(icon, hint),
      style: const TextStyle(fontSize: 14),
    );
  }

  /// ⚙️ FORGOT PASSWORD API LOGIC
  void _forgotPasswordLogic(String username, String email, String password, String confirmPassword) async {
    if (username.isEmpty || email.isEmpty || password.isEmpty) {
      Fluttertoast.showToast(msg: "Please fill all fields");
      return;
    }
    if (password != confirmPassword) {
      Fluttertoast.showToast(msg: "Passwords do not match");
      return;
    }

    SharedPreferences sh = await SharedPreferences.getInstance();
    String? url = sh.getString('url');

    if (url == null || url.isEmpty) {
      Fluttertoast.showToast(msg: "Server URL not configured. Go back and set the IP.");
      return;
    }

    try {
      final response = await http.post(
        Uri.parse('$url/user_forgot_password/'),
        body: {
          'username': username,
          'email': email,
          'password': password,
          'confirm_password': confirmPassword,
        },
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'ok') {
          Fluttertoast.showToast(msg: "Password updated successfully");
          Navigator.pop(context); // Close dialog
        } else {
          Fluttertoast.showToast(msg: data['msg'] ?? "Failed to reset");
        }
      } else {
        Fluttertoast.showToast(msg: "Server error: ${response.statusCode}");
      }
    } catch (e) {
      Fluttertoast.showToast(msg: "Error: ${e.toString()}", toastLength: Toast.LENGTH_LONG);
    }
  }


  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontWeight: FontWeight.bold,
        color: Color(0xFF2C5364),
        fontSize: 14,
      ),
    );
  }

  InputDecoration _buildInputDecoration(IconData icon, String hint, {Widget? suffixIcon}) {
    return InputDecoration(
      prefixIcon: Icon(icon, color: const Color(0xFF2C5364)),
      suffixIcon: suffixIcon,
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
      filled: true,
      fillColor: const Color(0xFFF1F4F9),
      contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 10),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: Color(0xFF2C5364), width: 1.5),
      ),
    );
  }

  void sent_data() async {
    // ... existing login logic ...
    String username = usernamecontroller.text.trim();
    String password = passwordcontroller.text.trim();

    if (username.isEmpty || password.isEmpty) {
      Fluttertoast.showToast(msg: "Please fill all fields");
      return;
    }

    SharedPreferences sh = await SharedPreferences.getInstance();
    String? url = sh.getString('url');

    if (url == null) {
      Fluttertoast.showToast(msg: "Server configuration missing");
      return;
    }

    final urls = Uri.parse('$url/user_login/');

    try {
      final response = await http.post(urls, body: {
        'username': username,
        'password': password,
      });

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'ok') {
          await sh.setString("lid", data['lid'].toString());
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const HomePage()),
          );
        } else {
          Fluttertoast.showToast(msg: data['message'] ?? 'Invalid credentials');
        }
      } else {
        Fluttertoast.showToast(msg: 'Network Error');
      }
    } catch (e) {
      Fluttertoast.showToast(msg: "Connection error");
    }
  }
}