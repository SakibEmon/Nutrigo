import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;

import '../../core/theme/theme_provider.dart';
import '../login/login_screen.dart';
import '../reports/health_report_screen.dart';
import 'my_complaints_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  DateTime? _birthDate;
  DateTime? _lastBirthDateUpdate;
  DateTime? _lastComplaintTime;
  bool _loadingData = true;

  @override
  void initState() {
    super.initState();
    _loadUserSettings();
  }

  Future<void> _loadUserSettings() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        if (data['birthDate'] != null) {
          _birthDate = (data['birthDate'] as Timestamp).toDate();
        }
        if (data['lastBirthDateUpdate'] != null) {
          _lastBirthDateUpdate = (data['lastBirthDateUpdate'] as Timestamp)
              .toDate();
        }
        if (data['lastComplaintTime'] != null) {
          _lastComplaintTime = (data['lastComplaintTime'] as Timestamp)
              .toDate();
        }
      }
    } catch (e) {
      debugPrint("Error loading settings: $e");
    } finally {
      if (mounted) setState(() => _loadingData = false);
    }
  }

  // ============================================================
  // BIRTH DATE LOGIC (1 update per 6 months / 180 days)
  // ============================================================
  bool get _canUpdateBirthDate {
    if (_lastBirthDateUpdate == null) return true;
    final diff = DateTime.now().difference(_lastBirthDateUpdate!);
    return diff.inDays >= 180;
  }

  int get _daysRemainingForBirthDate {
    if (_lastBirthDateUpdate == null) return 0;
    final diff = DateTime.now().difference(_lastBirthDateUpdate!);
    return (180 - diff.inDays).clamp(0, 180);
  }

  Future<void> _editBirthDate() async {
    if (!_canUpdateBirthDate) {
      _showSnackbar(
        "Birth date can only be changed once every 6 months. Wait $_daysRemainingForBirthDate days.",
        Colors.orange,
      );
      return;
    }

    final initialDate = _birthDate ?? DateTime(2000, 1, 1);
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1940),
      lastDate: DateTime.now(),
    );

    if (pickedDate != null) {
      final user = _auth.currentUser;
      if (user == null) return;

      final age = DateTime.now().year - pickedDate.year;

      await _firestore.collection('users').doc(user.uid).set({
        'birthDate': Timestamp.fromDate(pickedDate),
        'age': age,
        'lastBirthDateUpdate': Timestamp.now(),
      }, SetOptions(merge: true));

      setState(() {
        _birthDate = pickedDate;
        _lastBirthDateUpdate = DateTime.now();
      });

      _showSnackbar(
        "Birth date updated successfully!",
        const Color(0xff4CAF50),
      );
    }
  }

  // ============================================================
  // CONTACT US / COMPLAINT
  // ============================================================
  bool get _canSubmitComplaint {
    if (_lastComplaintTime == null) return true;
    final diff = DateTime.now().difference(_lastComplaintTime!);
    return diff.inHours >= 24;
  }

  int get _hoursRemainingForComplaint {
    if (_lastComplaintTime == null) return 0;
    final diff = DateTime.now().difference(_lastComplaintTime!);
    return (24 - diff.inHours).clamp(1, 24);
  }

  void _openContactDialog() {
    if (!_canSubmitComplaint) {
      _showSnackbar(
        "Daily complaint limit reached. Next complaint available in $_hoursRemainingForComplaint hours.",
        Colors.orange,
      );
      return;
    }

    final messageController = TextEditingController();
    bool isSending = false;

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          final isDark = Theme.of(context).brightness == Brightness.dark;

          return AlertDialog(
            backgroundColor: isDark ? const Color(0xff1E1E1E) : Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Text(
              "Contact NutriGo",
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "From: ${_auth.currentUser?.email ?? 'User'}",
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.grey.shade400 : Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "To: nutrigoservice@gmail.com",
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xff4CAF50),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: messageController,
                  maxLines: 4,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                  decoration: InputDecoration(
                    hintText: "Write your complaint or message here...",
                    hintStyle: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: isSending ? null : () => Navigator.pop(dialogCtx),
                child: Text(
                  "Cancel",
                  style: GoogleFonts.poppins(color: Colors.grey),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xff4CAF50),
                  foregroundColor: Colors.white,
                ),
                onPressed: isSending
                    ? null
                    : () async {
                        final body = messageController.text.trim();
                        if (body.isEmpty) return;

                        final user = _auth.currentUser;
                        if (user == null) return;

                        setDialogState(() => isSending = true);

                        try {
                          const serviceId = "service_8suz544";
                          const templateId = "template_pdz9ec5";
                          const publicKey = "D_mHA4Hb-IlwUZ1oV";

                          final emailUrl = Uri.parse(
                            'https://api.emailjs.com/api/v1.0/email/send',
                          );
                          await http.post(
                            emailUrl,
                            headers: {
                              'origin': 'http://localhost',
                              'Content-Type': 'application/json',
                            },
                            body: jsonEncode({
                              'service_id': serviceId,
                              'template_id': templateId,
                              'user_id': publicKey,
                              'template_params': {
                                'from_email': user.email ?? 'Unknown User',
                                'message': body,
                              },
                            }),
                          );

                          await _firestore.collection('complaints').add({
                            'userId': user.uid,
                            'userEmail': user.email ?? "",
                            'message': body,
                            'status': 'Pending',
                            'timestamp': Timestamp.now(),
                          });

                          await _firestore
                              .collection('users')
                              .doc(user.uid)
                              .set({
                                'lastComplaintTime': Timestamp.now(),
                              }, SetOptions(merge: true));

                          setState(() {
                            _lastComplaintTime = DateTime.now();
                          });

                          if (!context.mounted) return;
                          Navigator.pop(dialogCtx);
                          _showSnackbar(
                            "Complaint sent successfully! ✅",
                            const Color(0xff4CAF50),
                          );
                        } catch (e) {
                          setDialogState(() => isSending = false);
                          _showSnackbar("Failed to send: $e", Colors.redAccent);
                        }
                      },
                child: isSending
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        "Submit",
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showAppVersionDialog() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xff1E1E1E) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          "About App",
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "NutriGo Health Companion",
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: isDark ? Colors.white70 : Colors.black87,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              "Version: 1.0.0+1",
              style: GoogleFonts.poppins(
                color: Colors.grey.shade600,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 6),
            Text(
              "Developed by: Team NutriGo",
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: const Color(0xff4CAF50),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              "OK",
              style: GoogleFonts.poppins(color: const Color(0xff4CAF50)),
            ),
          ),
        ],
      ),
    );
  }

  void _openDeleteAccountFlow() {
    String? selectedReason;
    final reasons = [
      "I don't use this app anymore",
      "I found a better alternative",
      "Experiencing technical issues",
      "Privacy concerns",
      "Other",
    ];
    final suggestionController = TextEditingController();
    final passwordController = TextEditingController();
    bool isProcessing = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (bottomSheetCtx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(bottomSheetCtx).viewInsets.bottom + 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Delete Account",
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.redAccent,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "This action is permanent and cannot be undone.",
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "Why are you leaving?",
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      isExpanded: true,
                      value: selectedReason,
                      hint: Text(
                        "Select a reason",
                        style: GoogleFonts.poppins(fontSize: 12),
                      ),
                      items: reasons
                          .map(
                            (r) => DropdownMenuItem(
                              value: r,
                              child: Text(
                                r,
                                style: GoogleFonts.poppins(fontSize: 12),
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (val) =>
                          setModalState(() => selectedReason = val),
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      "Any suggestions for NutriGo?",
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: suggestionController,
                      maxLines: 2,
                      style: GoogleFonts.poppins(fontSize: 12),
                      decoration: InputDecoration(
                        hintText: "Tell us how we can improve...",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      "Enter password to confirm",
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: passwordController,
                      obscureText: true,
                      style: GoogleFonts.poppins(fontSize: 13),
                      decoration: InputDecoration(
                        hintText: "Your current password",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: isProcessing
                            ? null
                            : () async {
                                final user = _auth.currentUser;
                                final email = user?.email;
                                final password = passwordController.text.trim();

                                if (selectedReason == null) {
                                  _showSnackbar(
                                    "Please select a reason",
                                    Colors.orange,
                                  );
                                  return;
                                }
                                if (password.isEmpty) {
                                  _showSnackbar(
                                    "Password is required to delete",
                                    Colors.orange,
                                  );
                                  return;
                                }

                                setModalState(() => isProcessing = true);

                                try {
                                  final cred = EmailAuthProvider.credential(
                                    email: email!,
                                    password: password,
                                  );
                                  await user?.reauthenticateWithCredential(
                                    cred,
                                  );

                                  await _firestore
                                      .collection('deleted_accounts_feedback')
                                      .add({
                                        'reason': selectedReason,
                                        'suggestion': suggestionController.text
                                            .trim(),
                                        'email': email,
                                        'timestamp': Timestamp.now(),
                                      });

                                  await _firestore
                                      .collection('users')
                                      .doc(user!.uid)
                                      .delete();
                                  await user.delete();

                                  if (!context.mounted) return;
                                  Navigator.pop(bottomSheetCtx);
                                  Navigator.pushAndRemoveUntil(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const LoginScreen(),
                                    ),
                                    (route) => false,
                                  );
                                } on FirebaseAuthException catch (e) {
                                  setModalState(() => isProcessing = false);
                                  _showSnackbar(
                                    "Error: ${e.message}",
                                    Colors.redAccent,
                                  );
                                } catch (e) {
                                  setModalState(() => isProcessing = false);
                                  _showSnackbar("Failed: $e", Colors.redAccent);
                                }
                              },
                        child: isProcessing
                            ? const CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              )
                            : Text(
                                "Confirm & Delete Account",
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showSnackbar(String msg, Color color) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(msg), backgroundColor: color));
  }

  // ============================================================
  // UI BUILD
  // ============================================================
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Settings",
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: _loadingData
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xff4CAF50)),
            )
          : ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              children: [
                // 1. THEME SWITCH
                _settingTile(
                  icon: Icons.dark_mode_rounded,
                  title: "App Theme",
                  subtitle: isDark ? "Dark Mode" : "Light Mode",
                  trailing: Switch(
                    activeColor: const Color(0xff4CAF50),
                    value: isDark,
                    onChanged: (val) {
                      ThemeProvider.toggleTheme(val);
                      setState(() {});
                    },
                  ),
                ),
                const SizedBox(height: 12),

                // 2. BIRTH DATE EDIT
                _settingTile(
                  icon: Icons.cake_rounded,
                  title: "Edit Birth Date",
                  subtitle: _birthDate != null
                      ? "${_birthDate!.day}/${_birthDate!.month}/${_birthDate!.year} (${_canUpdateBirthDate ? "Eligible to change" : "Locked for $_daysRemainingForBirthDate days"})"
                      : "Set your birth date (1 update / 6 mo)",
                  onTap: _editBirthDate,
                ),
                const SizedBox(height: 12),

                // 3. MONTHLY HEALTH REPORT (PDF)
                _settingTile(
                  icon: Icons.picture_as_pdf_rounded,
                  title: "Health Report (Monthly)",
                  subtitle:
                      "Download & view monthly nutrition, BMI & habit logs",
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const HealthReportScreen(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 12),

                // 4. CONTACT US (COMPLAINT)
                _settingTile(
                  icon: Icons.mail_outline_rounded,
                  title: "Contact Us",
                  subtitle: _canSubmitComplaint
                      ? "Submit feedback or issue (1 per day)"
                      : "Locked for next $_hoursRemainingForComplaint hours (Daily limit)",
                  onTap: _openContactDialog,
                ),
                const SizedBox(height: 12),

                // 5. MY COMPLAINTS
                _settingTile(
                  icon: Icons.history_edu_rounded,
                  title: "My Complaints",
                  subtitle: "View your submitted complaints & status",
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const MyComplaintsScreen(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 12),

                // 6. APP VERSION
                _settingTile(
                  icon: Icons.info_outline_rounded,
                  title: "App Version",
                  subtitle: "v1.0.0+1 • Team NutriGo",
                  onTap: _showAppVersionDialog,
                ),
                const SizedBox(height: 24),

                // 7. DELETE ACCOUNT
                ListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: const BorderSide(color: Color(0xffFFCDD2)),
                  ),
                  tileColor: const Color(0xffFFEBEE),
                  leading: const Icon(
                    Icons.delete_forever_rounded,
                    color: Colors.redAccent,
                  ),
                  title: Text(
                    "Delete Account",
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      color: Colors.redAccent,
                      fontSize: 14,
                    ),
                  ),
                  subtitle: Text(
                    "Remove your account and health data",
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: Colors.red.shade400,
                    ),
                  ),
                  onTap: _openDeleteAccountFlow,
                ),
              ],
            ),
    );
  }

  Widget _settingTile({
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xff1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
        ),
      ),
      child: ListTile(
        leading: Icon(icon, color: const Color(0xff4CAF50)),
        title: Text(
          title,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey.shade600),
        ),
        trailing:
            trailing ??
            const Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: Colors.grey,
            ),
        onTap: onTap,
      ),
    );
  }
}
