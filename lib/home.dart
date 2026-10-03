import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:cyberintegrated/notification_service.dart';
import 'package:cyberintegrated/complaint.dart';
import 'package:cyberintegrated/image_analysis.dart';
import 'package:cyberintegrated/login.dart';
import 'package:cyberintegrated/mail_analysis.dart';
import 'package:cyberintegrated/notification.dart';
import 'package:cyberintegrated/profile.dart';
import 'package:cyberintegrated/report.dart';
import 'package:cyberintegrated/url_analysis.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  String name_ = "";
  String photo_ = "";
  int unreadCount = 0;
  int _prevUnreadCount = -1;  // -1 = not yet loaded; avoids notification on first fetch
  Timer? timer;

  // Animation Controllers
  late AnimationController _waveController;
  late AnimationController _shimmerController;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    fetchProfile();
    fetchNotificationCount();

    // 1. Wave Background Loop
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();

    // 2. Shimmer Effect Loop (Glass streak across cards)
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();

    // 3. Notification Pulse
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    timer = Timer.periodic(
        const Duration(seconds: 10), (Timer t) => fetchNotificationCount());
  }

  @override
  void dispose() {
    timer?.cancel();
    _waveController.dispose();
    _shimmerController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void fetchProfile() async {
    SharedPreferences sh = await SharedPreferences.getInstance();
    String url = sh.getString('url') ?? "";
    String lid = sh.getString('lid') ?? "";
    final urls = Uri.parse('$url/user_view_profile/');
    try {
      final response = await http.post(urls, body: {'lid': lid});
      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        if (data['status'] == 'ok') {
          setState(() {
            name_ = data['data']['first_name'] ?? "";
            photo_ = data['data']['photo'] ?? "";
          });
        }
      }
    } catch (e) { print(e); }
  }

  Future<void> fetchNotificationCount() async {
    SharedPreferences sh = await SharedPreferences.getInstance();
    String url = sh.getString('url') ?? "";
    String lid = sh.getString('lid') ?? "";
    final urls = Uri.parse('$url/user_notification_count/');

    try {
      final response = await http.post(urls, body: {'lid': lid});
      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        if (data['status'] == 'ok') {
          int newCount = int.tryParse(data['count'].toString()) ?? 0;

          // If count increased, new notifications arrived — show popup
          if (newCount > _prevUnreadCount && _prevUnreadCount >= 0) {
            _fetchAndShowNewNotifications(url, lid, newCount - _prevUnreadCount);
          }

          setState(() {
            unreadCount = newCount;
            _prevUnreadCount = newCount;
          });
        }
      }
    } catch (e) {
      print("Error: $e");
    }
  }

  /// Fetch unread notifications and fire real system notifications
  Future<void> _fetchAndShowNewNotifications(String url, String lid, int newlyAdded) async {
    try {
      final response = await http.post(
        Uri.parse('$url/user_view_notifications/'),
        body: {'lid': lid},
      );
      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        if (data['status'] == 'ok') {
          List allNotifs = data['data'];
          // Show only unread ones
          List unread = allNotifs.where((n) => n['is_read'] == false || n['is_read'] == 0).toList();

          // 🔔 Fire REAL system notifications for each new unread notification
          final notifService = NotificationService();
          for (var n in unread.take(newlyAdded)) {
            await notifService.showNotification(
              id: int.tryParse(n['id'].toString()) ?? 0,
              title: n['title'] ?? 'New Notification',
              body: n['message'] ?? '',
            );
          }
        }
      }
    } catch (e) {
      print("Notification error: $e");
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F3F7),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2C5364),
        foregroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text("Dashboard", style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          _buildNotificationIcon(),
          _buildProfileAvatar(),
        ],
      ),
      body: Stack(
        children: [
          /// 🌊 LAYERED ANIMATED WAVES
          _buildAnimatedWaves(const Color(0x442C5364), 5, 0.5), // Back wave
          _buildAnimatedWaves(const Color(0xFF2C5364), 4, 0.0), // Front wave

          Column(
            children: [
              const SizedBox(height: 15),
              _buildGreetingText(),
              const SizedBox(height: 25),
              _buildMainGrid(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationIcon() {
    return ScaleTransition(
      scale: Tween(begin: 1.0, end: 1.1).animate(_pulseController),
      child: Stack(
        children: [
          IconButton(
            icon: const Icon(Icons.notifications_active),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationPage())).then((_) => fetchNotificationCount()),
          ),
          if (unreadCount > 0)
            Positioned(
              right: 8, top: 8,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                child: Text(unreadCount > 99 ? "99+" : unreadCount.toString(), style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildProfileAvatar() {
    return Padding(
      padding: const EdgeInsets.only(right: 15),
      child: GestureDetector(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfilePage())),
        child: CircleAvatar(
          radius: 18, backgroundColor: Colors.white,
          backgroundImage: photo_.isNotEmpty ? NetworkImage(photo_) : null,
          child: photo_.isEmpty ? const Icon(Icons.person, color: Color(0xFF2C5364), size: 20) : null,
        ),
      ),
    );
  }

  Widget _buildAnimatedWaves(Color color, int speed, double offset) {
    return AnimatedBuilder(
      animation: _waveController,
      builder: (context, child) {
        return ClipPath(
          clipper: ComplexWaveClipper(_waveController.value, offset),
          child: Container(height: 180, color: color),
        );
      },
    );
  }

  Widget _buildGreetingText() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Hello, ${name_.isEmpty ? 'User' : name_} 👋",
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
                  const Text("System Secure • All systems operational",
                      style: TextStyle(color: Colors.white70, fontSize: 11, letterSpacing: 0.5)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),

        // ✨ NEW: THE APPEALING IMAGE CARD
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Container(
            height: 140,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(25),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                )
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(25),
              child: Stack(
                children: [
                  // REPLACE THE URL BELOW WITH YOUR ACTUAL IMAGE ASSET OR NETWORK URL
                  Image.asset(
                    'assets/images/app_bg.png',
                    fit: BoxFit.cover,
                    width: double.infinity,
                  ),
                  // Dark overlay to make text readable
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.black.withOpacity(0.6), Colors.transparent],
                        begin: Alignment.bottomLeft,
                        end: Alignment.topRight,
                      ),
                    ),
                  ),
                  const Positioned(
                    bottom: 15,
                    left: 15,
                    child: Text(
                      "Cyber Security Dashboard",
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  )
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMainGrid() {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: GridView.count(
          crossAxisCount: 2,
          mainAxisSpacing: 20, crossAxisSpacing: 20,
          children: [
            _coolFeatureTile(Icons.image, "Image Scan", const ImageAnalysisPage()),
            _coolFeatureTile(Icons.security, "Phishing", const PhishingDetectionPage()),
            _coolFeatureTile(Icons.email, "Spam Check", const SpamMailPage()),
            _coolFeatureTile(Icons.assignment, "Reports", const ReportsPage()),
            _coolFeatureTile(Icons.report, "Complaint", const ComplaintPage()),
            _coolFeatureTile(Icons.exit_to_app, "Logout", const LoginPage(), isExit: true),
          ],
        ),
      ),
    );
  }

  Widget _coolFeatureTile(IconData icon, String title, Widget page, {bool isExit = false}) {
    return GestureDetector(
      onTap: () => isExit ? _handleLogout() : Navigator.push(context, MaterialPageRoute(builder: (_) => page)),
      child: Stack(
        children: [
          // Base Card
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 8))],
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: const Color(0xFFF0F4F8), shape: BoxShape.circle),
                    child: Icon(icon, color: const Color(0xFF2C5364), size: 30),
                  ),
                  const SizedBox(height: 12),
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2C5364))),
                ],
              ),
            ),
          ),

          // ✨ SHIMMER ANIMATION LAYER
          AnimatedBuilder(
            animation: _shimmerController,
            builder: (context, child) {
              return ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Transform.translate(
                  offset: Offset(_shimmerController.value * 400 - 200, 0),
                  child: Transform.rotate(
                    angle: 0.5,
                    child: Container(
                      width: 40,
                      height: 300,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.white.withOpacity(0),
                            Colors.white.withOpacity(0.4),
                            Colors.white.withOpacity(0),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  void _handleLogout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Logout"),
        content: const Text("Secure session termination?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {   
              Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const LoginPage()), (route) => false);
            },
            child: const Text("Logout", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

/// 🌊 COMPLEX SINE WAVE CLIPPER
class ComplexWaveClipper extends CustomClipper<Path> {
  final double value;
  final double offset;
  ComplexWaveClipper(this.value, this.offset);

  @override
  Path getClip(Size size) {
    Path path = Path();
    path.lineTo(0, size.height - 40);

    for (double i = 0; i <= size.width; i++) {
      path.lineTo(
        i,
        size.height - 40 + math.sin((i / size.width * 2 * math.pi) + (value * 2 * math.pi) + offset) * 12,
      );
    }

    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(ComplexWaveClipper oldClipper) => true;
}