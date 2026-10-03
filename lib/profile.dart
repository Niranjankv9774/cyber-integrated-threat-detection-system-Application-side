import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io' show File;

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool isLoading = true;
  bool isEditing = false;

  XFile? _image;
  final picker = ImagePicker();

  final firstName = TextEditingController();
  final lastName = TextEditingController();
  final gender = TextEditingController();
  final email = TextEditingController();
  final address = TextEditingController();
  final place = TextEditingController();
  final phone = TextEditingController();

  String photoUrl = "";
  String baseUrl = "";

  @override
  void initState() {
    super.initState();
    fetchProfile();
  }

  Future<void> fetchProfile() async {
    SharedPreferences sh = await SharedPreferences.getInstance();
    baseUrl = sh.getString("url") ?? "";
    String lid = sh.getString("lid") ?? "";

    var url = Uri.parse("$baseUrl/user_view_profile/");
    try {
      var response = await http.post(url, body: {"lid": lid});
      var jsonData = json.decode(response.body);

      if (jsonData['status'] == "ok") {
        var data = jsonData['data'];
        setState(() {
          firstName.text = data['first_name'] ?? "";
          lastName.text = data['last_name'] ?? "";
          gender.text = data['gender'] ?? "";
          email.text = data['email'] ?? "";
          address.text = data['address'] ?? "";
          place.text = data['place'] ?? "";
          phone.text = data['phone'] ?? "";
          photoUrl = data['photo'] ?? "";
          isLoading = false;
        });
      }
    } catch (e) {
      print(e);
    }
  }

  Future<void> pickImage() async {
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        _image = picked;
      });
    }
  }

  Future<void> updateProfile() async {
    var uri = Uri.parse("$baseUrl/user_edit_profile/");
    var request = http.MultipartRequest("POST", uri);
    SharedPreferences sh = await SharedPreferences.getInstance();
    String lid = sh.getString("lid") ?? "";

    request.fields['lid'] = lid;
    request.fields['first_name'] = firstName.text;
    request.fields['last_name'] = lastName.text;
    request.fields['gender'] = gender.text;
    request.fields['email'] = email.text;
    request.fields['address'] = address.text;
    request.fields['place'] = place.text;
    request.fields['phone'] = phone.text;

    if (_image != null) {
      request.files.add(
        await http.MultipartFile.fromPath(
          'photo',
          _image!.path,
        ),
      );
    }

    var response = await request.send();
    if (response.statusCode == 200) {
      setState(() {
        isEditing = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Profile Updated Successfully")),
      );
      fetchProfile();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2C5364),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text("My Profile", style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 1.1)),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF2C5364)))
          : SingleChildScrollView(
        child: Column(
          children: [
            /// 🔵 HEADER OVERLAP SECTION
            Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                Container(
                  height: 100,
                  decoration: const BoxDecoration(
                    color: Color(0xFF2C5364),
                    borderRadius: BorderRadius.vertical(bottom: Radius.circular(40)),
                  ),
                ),
                Positioned(
                  top: 20,
                  child: _buildProfileImageContainer(),
                ),
              ],
            ),

            const SizedBox(height: 80),

            /// 📝 FORM SECTION
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(left: 10, bottom: 12),
                    child: Text("Personal Information",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2C5364))),
                  ),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20, offset: const Offset(0, 10)),
                      ],
                    ),
                    child: Column(
                      children: [
                        buildStyledField("First Name", firstName, Icons.person_outline),
                        buildStyledField("Last Name", lastName, Icons.person_outline),
                        buildStyledField("Gender", gender, Icons.wc_outlined),
                        buildStyledField("Email", email, Icons.email_outlined),
                        buildStyledField("Phone", phone, Icons.phone_android_outlined),
                        buildStyledField("Place", place, Icons.location_on_outlined),
                        buildStyledField("Address", address, Icons.home_outlined),

                        if (isEditing) ...[
                          const SizedBox(height: 25),
                          _buildSaveButton(),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: isEditing ? Colors.redAccent : const Color(0xFF2C5364),
        onPressed: () => setState(() => isEditing = !isEditing),
        label: Text(isEditing ? "Cancel" : "Edit Profile", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        icon: Icon(isEditing ? Icons.close : Icons.edit_note, color: Colors.white),
      ),
    );
  }

  Widget _buildProfileImageContainer() {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
      child: Stack(
        alignment: Alignment.bottomRight,
        children: [
          GestureDetector(
            onTap: isEditing ? pickImage : null,
            child: CircleAvatar(
              radius: 65,
              backgroundColor: Colors.grey.shade100,
              backgroundImage: _image != null
                  ? FileImage(File(_image!.path))
                  : (photoUrl.isNotEmpty
                  ? NetworkImage(photoUrl)
                  : null),
              child: (_image == null && photoUrl.isEmpty)
                  ? const Icon(
                Icons.person,
                size: 70,
                color: Color(0xFF2C5364),
              )
                  : null,
            ),
          ),          if (isEditing)
            GestureDetector(
              onTap: pickImage,
              child: const CircleAvatar(
                radius: 18,
                backgroundColor: Color(0xFF2C5364),
                child: Icon(Icons.camera_alt, color: Colors.white, size: 16),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF2C5364),
          elevation: 4,
          shadowColor: const Color(0xFF2C5364).withOpacity(0.4),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        ),
        onPressed: updateProfile,
        child: const Text("SAVE CHANGES",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white, letterSpacing: 1.1)),
      ),
    );
  }

  Widget buildStyledField(String label, TextEditingController controller, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
        controller: controller,
        readOnly: !isEditing,
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
        decoration: InputDecoration(
          prefixIcon: Icon(icon, size: 20, color: const Color(0xFF2C5364).withOpacity(0.6)),
          labelText: label,
          labelStyle: TextStyle(color: Colors.grey.shade600, fontSize: 13),
          filled: true,
          fillColor: isEditing ? const Color(0xFFF8FAFF) : Colors.white,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide(color: Colors.grey.shade200),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: const BorderSide(color: Color(0xFF2C5364), width: 1.5),
          ),
        ),
      ),
    );
  }
}