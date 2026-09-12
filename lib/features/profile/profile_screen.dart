import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../login/login_screen.dart';
import '../settings/settings_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  final _bioController = TextEditingController();
  final _feetController = TextEditingController();
  final _inchController = TextEditingController();
  final _weightController = TextEditingController();

  bool _loading = true;
  bool _saving = false;
  File? _profileImage;
  String? _base64Image;

  // Profile data
  String _name = "";
  String _email = "";
  int _age = 0;
  String _gender = "";
  String _bio = "";
  double _heightFeet = 0;
  double _heightInch = 0;
  double _weightKg = 0;
  DateTime? _lastMetricsUpdate;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  @override
  void dispose() {
    _bioController.dispose();
    _feetController.dispose();
    _inchController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  // ============================================================
  // LOAD PROFILE FROM FIRESTORE
  // ============================================================

  Future<void> _loadUserProfile() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        setState(() {
          _name = data['name'] ?? user.displayName ?? "User";
          _email = data['email'] ?? user.email ?? "";
          _age = data['age'] ?? 0;
          _gender = data['gender'] ?? "Not specified";
          _bio = data['bio'] ?? "";
          _base64Image = data['profileImageBase64'];
          _heightFeet = (data['heightFeet'] ?? 0).toDouble();
          _heightInch = (data['heightInch'] ?? 0).toDouble();
          _weightKg = (data['weightKg'] ?? 0).toDouble();

          if (data['lastMetricsUpdate'] != null) {
            _lastMetricsUpdate = (data['lastMetricsUpdate'] as Timestamp)
                .toDate();
          }

          _bioController.text = _bio;
          if (_heightFeet > 0) {
            _feetController.text = _heightFeet.toInt().toString();
          }
          if (_heightInch > 0) {
            _inchController.text = _heightInch.toInt().toString();
          }
          if (_weightKg > 0) _weightController.text = _weightKg.toString();
        });
      }
    } catch (e) {
      debugPrint("Error loading profile: $e");
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ============================================================
  // BMI CALCULATION & HEALTH CONDITION
  // ============================================================

  double get _bmi {
    final feet = double.tryParse(_feetController.text) ?? _heightFeet;
    final inch = double.tryParse(_inchController.text) ?? _heightInch;
    final weight = double.tryParse(_weightController.text) ?? _weightKg;

    final totalInches = (feet * 12) + inch;
    if (totalInches <= 0 || weight <= 0) return 0.0;

    final meters = totalInches * 0.0254;
    return weight / (meters * meters);
  }

  Map<String, dynamic> _getBmiStatus(double bmi) {
    if (bmi <= 0) {
      return {
        "label": "N/A",
        "color": Colors.grey,
        "desc": "Add height & weight to see your health condition",
      };
    } else if (bmi < 18.5) {
      return {
        "label": "Underweight",
        "color": Colors.orange,
        "desc": "Consider a nutrient-dense diet",
      };
    } else if (bmi < 24.9) {
      return {
        "label": "Normal Weight",
        "color": const Color(0xff4CAF50),
        "desc": "Great job! Keep maintaining it",
      };
    } else if (bmi < 29.9) {
      return {
        "label": "Overweight",
        "color": Colors.amber.shade800,
        "desc": "Focus on balanced meals & activity",
      };
    } else {
      return {
        "label": "Obese",
        "color": Colors.redAccent,
        "desc": "Consult a healthcare specialist",
      };
    }
  }

  // ============================================================
  // MONTHLY UPDATE RESTRICTION CHECK
  // ============================================================

  bool get _canUpdateMetrics {
    if (_lastMetricsUpdate == null) return true;
    final difference = DateTime.now().difference(_lastMetricsUpdate!);
    return difference.inDays >= 30; // ৩০ দিন পর পরিবর্তন করা যাবে
  }

  int get _daysRemainingForNextUpdate {
    if (_lastMetricsUpdate == null) return 0;
    final difference = DateTime.now().difference(_lastMetricsUpdate!);
    return (30 - difference.inDays).clamp(0, 30);
  }

  // ============================================================
  // PICK IMAGE & CONVERT TO BASE64
  // ============================================================

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 400,
      maxHeight: 400,
      imageQuality: 70,
    );
    if (pickedFile != null) {
      final file = File(pickedFile.path);
      final bytes = await file.readAsBytes();
      final base64Str = base64Encode(bytes);

      setState(() {
        _profileImage = file;
        _base64Image = base64Str;
      });
    }
  }

  // ============================================================
  // SAVE PROFILE
  // ============================================================

  Future<void> _saveProfile() async {
    final user = _auth.currentUser;
    if (user == null) return;

    setState(() => _saving = true);

    try {
      final feet = double.tryParse(_feetController.text) ?? _heightFeet;
      final inch = double.tryParse(_inchController.text) ?? _heightInch;
      final weight = double.tryParse(_weightController.text) ?? _weightKg;

      final bool isMetricsChanged =
          (feet != _heightFeet || inch != _heightInch || weight != _weightKg);

      final Map<String, dynamic> updateData = {
        'bio': _bioController.text.trim(),
      };

      if (_base64Image != null) {
        updateData['profileImageBase64'] = _base64Image;
      }

      if (isMetricsChanged) {
        if (!_canUpdateMetrics) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                "Height/Weight can only be updated once a month. Wait $_daysRemainingForNextUpdate days.",
              ),
              backgroundColor: Colors.orange,
            ),
          );
          setState(() => _saving = false);
          return;
        }
        updateData['heightFeet'] = feet;
        updateData['heightInch'] = inch;
        updateData['weightKg'] = weight;
        updateData['lastMetricsUpdate'] = Timestamp.now();
      }

      await _firestore
          .collection('users')
          .doc(user.uid)
          .set(updateData, SetOptions(merge: true));

      await _loadUserProfile();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Profile updated successfully! ✅"),
          backgroundColor: Color(0xff4CAF50),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed to update profile: $e"),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  // ============================================================
  // LOGOUT METHOD
  // ============================================================

  Future<void> _logout(BuildContext context) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(
            "Logout?",
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
          ),
          content: Text(
            "Are you sure you want to logout from Nutrigo?",
            style: GoogleFonts.poppins(fontSize: 14),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(
                "Cancel",
                style: GoogleFonts.poppins(color: Colors.grey),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: Text(
                "Logout",
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    try {
      await FirebaseAuth.instance.signOut();

      if (!context.mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Logout failed. Please try again."),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  // ============================================================
  // BUILD
  // ============================================================

  ImageProvider? _getAvatarImage() {
    if (_profileImage != null) {
      return FileImage(_profileImage!);
    } else if (_base64Image != null && _base64Image!.isNotEmpty) {
      try {
        final Uint8List bytes = base64Decode(_base64Image!);
        return MemoryImage(bytes);
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: Color(0xff4CAF50)),
        ),
      );
    }

    final bmiValue = _bmi;
    final bmiStatus = _getBmiStatus(bmiValue);
    final statusColor = bmiStatus["color"] as Color;
    final avatarImage = _getAvatarImage();

    return Scaffold(
      backgroundColor: const Color(0xffF8FBF8),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black87,
        title: Text(
          "My Health Profile",
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 19),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: Colors.black87),
            tooltip: "Settings",
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              ).then((_) => _loadUserProfile());
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Column(
          children: [
            // =========================
            // AVATAR & BASIC DETAILS
            // =========================
            Center(
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  CircleAvatar(
                    radius: 48,
                    backgroundColor: const Color(0xffE8F5E9),
                    backgroundImage: avatarImage,
                    child: avatarImage == null
                        ? Text(
                            _name.isNotEmpty ? _name[0].toUpperCase() : "U",
                            style: GoogleFonts.poppins(
                              fontSize: 34,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xff4CAF50),
                            ),
                          )
                        : null,
                  ),
                  Positioned(
                    bottom: -2,
                    right: -2,
                    child: InkWell(
                      onTap: _pickImage,
                      child: Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: const Color(0xff4CAF50),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(
                          Icons.camera_alt_rounded,
                          size: 16,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _name,
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              _email,
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),

            // Age & Gender Tags
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _chipTag(icon: Icons.cake_rounded, label: "$_age Years"),
                const SizedBox(width: 8),
                _chipTag(icon: Icons.person_rounded, label: _gender),
              ],
            ),
            const SizedBox(height: 20),

            // =========================
            // BIO / DESCRIPTION
            // =========================
            _cardContainer(
              title: "About Me",
              icon: Icons.notes_rounded,
              child: TextField(
                controller: _bioController,
                maxLines: 2,
                style: GoogleFonts.poppins(fontSize: 13),
                decoration: InputDecoration(
                  hintText: "Add your nutrition goal or personal bio...",
                  hintStyle: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey.shade400,
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // =========================
            // BODY METRICS (HEIGHT & WEIGHT)
            // =========================
            _cardContainer(
              title: "Body Metrics",
              icon: Icons.accessibility_new_rounded,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!_canUpdateMetrics) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.orange.shade200),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.lock_clock,
                            size: 15,
                            color: Colors.orange,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              "Locked. Next update in $_daysRemainingForNextUpdate days (Monthly 1x limit).",
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                color: Colors.orange.shade900,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  Row(
                    children: [
                      // Height Feet
                      Expanded(
                        child: _metricBox(
                          title: "Feet",
                          suffix: "ft",
                          controller: _feetController,
                          enabled: _canUpdateMetrics,
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                      const SizedBox(width: 10),
                      // Height Inch
                      Expanded(
                        child: _metricBox(
                          title: "Inch",
                          suffix: "in",
                          controller: _inchController,
                          enabled: _canUpdateMetrics,
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                      const SizedBox(width: 10),
                      // Weight KG
                      Expanded(
                        child: _metricBox(
                          title: "Weight",
                          suffix: "kg",
                          controller: _weightController,
                          enabled: _canUpdateMetrics,
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // =========================
            // BMI & HEALTH CONDITION CARD
            // =========================
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: statusColor.withOpacity(0.3),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: statusColor.withOpacity(0.08),
                    blurRadius: 14,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.favorite_rounded,
                          color: statusColor,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          "Body Mass Index (BMI)",
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          bmiStatus["label"],
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: statusColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    bmiValue > 0 ? bmiValue.toStringAsFixed(1) : "--",
                    style: GoogleFonts.poppins(
                      fontSize: 38,
                      fontWeight: FontWeight.w800,
                      color: statusColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    bmiStatus["desc"],
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Save Button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xff4CAF50),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                onPressed: _saving ? null : _saveProfile,
                icon: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.save_rounded, size: 20),
                label: Text(
                  _saving ? "Saving..." : "Save Profile",
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // =========================
            // LOGOUT BUTTON
            // =========================
            SizedBox(
              width: double.infinity,
              height: 52,
              child: OutlinedButton.icon(
                onPressed: () => _logout(context),
                icon: const Icon(
                  Icons.logout_rounded,
                  color: Colors.redAccent,
                  size: 20,
                ),
                label: Text(
                  "Logout",
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.redAccent,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xffFFCDD2), width: 1.5),
                  backgroundColor: const Color(0xffFFEBEE),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // =========================
  // HELPER WIDGETS
  // =========================

  Widget _chipTag({required IconData icon, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xffE8F5E9),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: const Color(0xff4CAF50)),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: const Color(0xff388E3C),
            ),
          ),
        ],
      ),
    );
  }

  Widget _cardContainer({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 17, color: const Color(0xff4CAF50)),
              const SizedBox(width: 8),
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }

  Widget _metricBox({
    required String title,
    required String suffix,
    required TextEditingController controller,
    required bool enabled,
    required ValueChanged<String> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: enabled ? const Color(0xffF9FBF9) : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 11,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  enabled: enabled,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  onChanged: onChanged,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  decoration: const InputDecoration(
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                    border: InputBorder.none,
                  ),
                ),
              ),
              Text(
                suffix,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
