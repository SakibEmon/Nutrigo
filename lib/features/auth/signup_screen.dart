import 'dart:convert';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../login/login_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  // ============================================================
  // Controllers
  // ============================================================

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final TextEditingController _otpController = TextEditingController();

  DateTime? _selectedDob;
  String? _selectedGender;

  bool _loading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  String? _generatedOtp;

  // ============================================================
  // EmailJS Credentials
  // ============================================================
  final String _serviceId = "service_8suz544";
  final String _templateId = "template_knwbp3m";
  final String _publicKey = "D_mHA4Hb-IlwUZ1oV";

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  // ============================================================
  // Helper Functions
  // ============================================================

  String _formatDate(DateTime date) {
    const List<String> months = [
      "January",
      "February",
      "March",
      "April",
      "May",
      "June",
      "July",
      "August",
      "September",
      "October",
      "November",
      "December",
    ];
    return "${date.day} ${months[date.month - 1]} ${date.year}";
  }

  Future<void> _pickDateOfBirth() async {
    final now = DateTime.now();
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime(2001, 1, 1),
      firstDate: DateTime(1940),
      lastDate: DateTime(now.year, now.month, now.day),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xff4CAF50),
              onPrimary: Colors.white,
              onSurface: Colors.black87,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null) {
      setState(() {
        _selectedDob = pickedDate;
      });
    }
  }

  int _calculateAge(DateTime dob) {
    final today = DateTime.now();
    int age = today.year - dob.year;
    if (today.month < dob.month ||
        (today.month == dob.month && today.day < dob.day)) {
      age--;
    }
    return age;
  }

  String _generateOtpCode() {
    final random = Random();
    return (100000 + random.nextInt(900000)).toString();
  }

  // ============================================================
  // Send 6-digit Code via EmailJS
  // ============================================================

  Future<bool> _sendOtpToEmail({
    required String userEmail,
    required String userName,
    required String otp,
  }) async {
    final url = Uri.parse('https://api.emailjs.com/api/v1.0/email/send');
    try {
      final response = await http.post(
        url,
        headers: {
          'origin': 'http://localhost',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'service_id': _serviceId,
          'template_id': _templateId,
          'user_id': _publicKey,
          'template_params': {
            'to_email': userEmail,
            'to_name': userName,
            'passcode': otp,
          },
        }),
      );
      return response.statusCode == 200;
    } catch (e) {
      debugPrint("Email sending error: $e");
      return false;
    }
  }

  // ============================================================
  // Initiate Signup
  // ============================================================

  Future<void> _initiateSignup() async {
    if (_loading) return;

    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (name.isEmpty) {
      _showMessage("Please enter your full name.");
      return;
    }

    if (email.isEmpty) {
      _showMessage("Please enter your email.");
      return;
    }

    if (_selectedDob == null) {
      _showMessage("Please select your date of birth from calendar.");
      return;
    }

    if (_selectedGender == null) {
      _showMessage("Please select your gender.");
      return;
    }

    if (password.isEmpty) {
      _showMessage("Please enter a password.");
      return;
    }

    if (password.length < 6) {
      _showMessage("Password must be at least 6 characters.");
      return;
    }

    if (!password.contains(RegExp(r'[A-Z]'))) {
      _showMessage("Password must contain at least one capital letter (A-Z).");
      return;
    }

    if (!password.contains(RegExp(r'[0-9]'))) {
      _showMessage("Password must contain at least one number (0-9).");
      return;
    }

    if (confirmPassword.isEmpty) {
      _showMessage("Please confirm your password.");
      return;
    }

    if (password != confirmPassword) {
      _showMessage("Passwords do not match.");
      return;
    }

    setState(() => _loading = true);

    try {
      final otp = _generateOtpCode();
      _generatedOtp = otp;

      final isSent = await _sendOtpToEmail(
        userEmail: email,
        userName: name,
        otp: otp,
      );

      setState(() => _loading = false);

      if (!isSent) {
        _showMessage(
          "Failed to send verification code. Please check your internet connection.",
        );
        return;
      }

      if (!mounted) return;

      _showOtpVerificationDialog(name: name, email: email, password: password);
    } catch (e) {
      setState(() => _loading = false);
      _showMessage("Something went wrong. Please try again.");
    }
  }

  // ============================================================
  // OTP Verification Dialog (Navigation Crash Fixed)
  // ============================================================

  void _showOtpVerificationDialog({
    required String name,
    required String email,
    required String password,
  }) {
    _otpController.clear();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        bool isVerifying = false;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              title: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: const BoxDecoration(
                      color: Color(0xffE8F5E9),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.mark_email_read_outlined,
                      color: Color(0xff4CAF50),
                      size: 34,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "Enter Verification Code",
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "We've sent a 6-digit code to:\n$email",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _otpController,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    maxLength: 6,
                    style: GoogleFonts.poppins(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 8,
                    ),
                    decoration: InputDecoration(
                      hintText: "• • • • • •",
                      counterText: "",
                      hintStyle: GoogleFonts.poppins(
                        fontSize: 20,
                        letterSpacing: 4,
                        color: Colors.grey.shade400,
                      ),
                      filled: true,
                      fillColor: const Color(0xffF9FBF9),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(
                          color: Color(0xff4CAF50),
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              actions: [
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: isVerifying
                            ? null
                            : () => Navigator.of(dialogContext).pop(),
                        child: Text(
                          "Cancel",
                          style: GoogleFonts.poppins(
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xff4CAF50),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: isVerifying
                            ? null
                            : () async {
                                final enteredCode = _otpController.text.trim();

                                if (enteredCode != _generatedOtp) {
                                  _showMessage(
                                    "Incorrect code! Please check your email.",
                                  );
                                  return;
                                }

                                setDialogState(() => isVerifying = true);

                                // প্রথমে ডায়ালগ বন্ধ করা হলো
                                Navigator.of(dialogContext).pop();

                                // এরপর মূল পেজ থেকে একাউন্ট ক্রিয়েট করা হলো
                                await _createFirebaseAccount(
                                  name: name,
                                  email: email,
                                  password: password,
                                );
                              },
                        child: isVerifying
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                "Verify & Create",
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ============================================================
  // Create Account on Firebase
  // ============================================================

  Future<void> _createFirebaseAccount({
    required String name,
    required String email,
    required String password,
  }) async {
    setState(() => _loading = true);

    try {
      final age = _calculateAge(_selectedDob!);
      final formattedDob = _formatDate(_selectedDob!);

      final userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);

      final user = userCredential.user;
      if (user != null) {
        await user.updateDisplayName(name);

        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'uid': user.uid,
          'name': name,
          'email': email,
          'dateOfBirth': formattedDob,
          'age': age,
          'gender': _selectedGender,
          'createdAt': FieldValue.serverTimestamp(),
        });

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString("user_name", name);
        await prefs.setString("user_dob", formattedDob);
        await prefs.setInt("user_age", age);
        await prefs.setString("user_gender", _selectedGender!);
        await prefs.setString("user_email", email);

        await FirebaseAuth.instance.signOut();

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Account verified & created successfully! 🎉",
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: const Color(0xff4CAF50),
            duration: const Duration(seconds: 2),
          ),
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        _showMessage("Account creation failed: $e");
      }
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message, style: GoogleFonts.poppins())),
    );
  }

  // ============================================================
  // UI Build
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final String dobDisplay = _selectedDob == null
        ? "Date of Birth"
        : _formatDate(_selectedDob!);

    return Scaffold(
      backgroundColor: const Color(0xffFFFDF8),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),

              const Center(
                child: CircleAvatar(
                  radius: 45,
                  backgroundColor: Color(0xffE8F5E9),
                  child: Icon(
                    Icons.restaurant_menu,
                    size: 50,
                    color: Color(0xff4CAF50),
                  ),
                ),
              ),

              const SizedBox(height: 30),

              Text(
                "Create Account 👋",
                style: GoogleFonts.poppins(
                  fontSize: 30,
                  fontWeight: FontWeight.w700,
                ),
              ),

              const SizedBox(height: 8),

              Text(
                "Join Nutrigo and start your healthy journey.",
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  color: Colors.grey.shade600,
                ),
              ),

              const SizedBox(height: 30),

              _buildTextField(
                controller: _nameController,
                hint: "Full Name",
                icon: Icons.person_outline,
              ),

              const SizedBox(height: 18),

              _buildTextField(
                controller: _emailController,
                hint: "Email",
                icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
              ),

              const SizedBox(height: 18),

              InkWell(
                onTap: _loading ? null : _pickDateOfBirth,
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 18,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.calendar_month_outlined,
                        color: Colors.grey.shade700,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          dobDisplay,
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            color: _selectedDob == null
                                ? Colors.grey.shade600
                                : Colors.black87,
                            fontWeight: _selectedDob == null
                                ? FontWeight.normal
                                : FontWeight.w500,
                          ),
                        ),
                      ),
                      Icon(Icons.arrow_drop_down, color: Colors.grey.shade600),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 18),

              DropdownButtonFormField<String>(
                value: _selectedGender,
                decoration: InputDecoration(
                  hintText: "Gender",
                  prefixIcon: const Icon(Icons.people_outline),
                  filled: true,
                  fillColor: Colors.white,
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(
                      color: Color(0xff4CAF50),
                      width: 2,
                    ),
                  ),
                ),
                items: const [
                  DropdownMenuItem(value: "Male", child: Text("Male")),
                  DropdownMenuItem(value: "Female", child: Text("Female")),
                  DropdownMenuItem(value: "Other", child: Text("Other")),
                ],
                onChanged: _loading
                    ? null
                    : (value) {
                        setState(() {
                          _selectedGender = value;
                        });
                      },
              ),

              const SizedBox(height: 18),

              _buildPasswordField(
                controller: _passwordController,
                hint: "Password (e.g. Pass123)",
                obscureText: _obscurePassword,
                onToggle: () {
                  setState(() {
                    _obscurePassword = !_obscurePassword;
                  });
                },
              ),

              const SizedBox(height: 18),

              _buildPasswordField(
                controller: _confirmPasswordController,
                hint: "Confirm Password",
                obscureText: _obscureConfirmPassword,
                onToggle: () {
                  setState(() {
                    _obscureConfirmPassword = !_obscureConfirmPassword;
                  });
                },
              ),

              const SizedBox(height: 30),

              SizedBox(
                width: double.infinity,
                height: 58,
                child: ElevatedButton(
                  onPressed: _loading ? null : _initiateSignup,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xff4CAF50),
                    disabledBackgroundColor: Colors.grey.shade300,
                    foregroundColor: Colors.white,
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _loading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          "Create Account",
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 35),

              Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Already have an account? ",
                      style: GoogleFonts.poppins(
                        color: Colors.grey.shade700,
                        fontSize: 15,
                      ),
                    ),
                    GestureDetector(
                      onTap: _loading
                          ? null
                          : () {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const LoginScreen(),
                                ),
                              );
                            },
                      child: Text(
                        "Login",
                        style: GoogleFonts.poppins(
                          color: const Color(0xff4CAF50),
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
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
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      enabled: !_loading,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(vertical: 18),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xff4CAF50), width: 2),
        ),
      ),
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String hint,
    required bool obscureText,
    required VoidCallback onToggle,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      enabled: !_loading,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: const Icon(Icons.lock_outline),
        suffixIcon: IconButton(
          onPressed: _loading ? null : onToggle,
          icon: Icon(
            obscureText
                ? Icons.visibility_off_outlined
                : Icons.visibility_outlined,
          ),
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(vertical: 18),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xff4CAF50), width: 2),
        ),
      ),
    );
  }
}
