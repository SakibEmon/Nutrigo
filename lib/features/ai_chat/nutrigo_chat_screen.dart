import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/ai/gemini_api.dart';
import '../../services/nutrition_score_service.dart';

class NutrigoChatScreen extends StatefulWidget {
  const NutrigoChatScreen({super.key});

  @override
  State<NutrigoChatScreen> createState() => _NutrigoChatScreenState();
}

class _NutrigoChatScreenState extends State<NutrigoChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;
  File? _selectedImage;
  String? _selectedImageBase64;
  String _selectedLanguage = "English";

  User? get _currentUser => FirebaseAuth.instance.currentUser;

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: source,
        imageQuality: 50,
        maxWidth: 600,
        maxHeight: 600,
      );
      if (picked != null) {
        final bytes = await picked.readAsBytes();
        setState(() {
          _selectedImage = File(picked.path);
          _selectedImageBase64 = base64Encode(bytes);
        });
      }
    } catch (e) {
      debugPrint("Image Pick Error: $e");
    }
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty && _selectedImageBase64 == null) return;
    if (_currentUser == null) return;

    final String? base64Img = _selectedImageBase64;
    final userMessage = text.isEmpty ? "Analyze this food image." : text;

    _controller.clear();
    setState(() {
      _selectedImage = null;
      _selectedImageBase64 = null;
      _isLoading = true;
    });

    final chatCollection = FirebaseFirestore.instance
        .collection('users')
        .doc(_currentUser!.uid)
        .collection('ai_chats');

    await chatCollection.add({
      'text': userMessage,
      'isUser': true,
      'imageBase64': base64Img,
      'timestamp': FieldValue.serverTimestamp(),
    });

    _scrollToBottom();

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(_currentUser!.uid)
          .get();
      final userData = userDoc.data() ?? {};
      final name = userData['name'] ?? 'User';
      final weight = userData['weight']?.toString() ?? 'N/A';
      final height = userData['height']?.toString() ?? 'N/A';
      final bmi =
          userData['bmi']?.toString() ??
          userData['bmi_value']?.toString() ??
          'N/A';

      final systemPrompt =
          """
You are 'Nutrigo AI', a personal nutritionist for the Nutrigo App.
Language: Strictly reply in $_selectedLanguage.
${_selectedLanguage == "Bangla" ? "সম্পূর্ণ উত্তর স্পষ্ট বাংলায় দিন।" : "Provide the response completely in fluent English."}

USER HEALTH PROFILE:
- Name: $name
- Weight: $weight kg
- Height: $height cm
- BMI: $bmi

RULES:
1. Answer food, calories, nutrition, hydration queries.
2. If asked about user's BMI, weight, or height, answer using the profile above.
3. If an image is provided, analyze the food and its benefits.
4. Decline non-health queries politely.

USER QUERY:
$userMessage
""";

      final response = await GeminiApi.chatWithNutrigoAi(
        prompt: systemPrompt,
        base64Image: base64Img,
      );

      await chatCollection.add({
        'text': response,
        'isUser': false,
        'timestamp': FieldValue.serverTimestamp(),
      });

      // পয়েন্ট যোগ (+১ পয়েন্ট)
      await NutritionScoreService.addPoints(
        NutritionScoreService.pointsAiChat,
        "AI Chat Consultation",
      );
    } catch (e) {
      await chatCollection.add({
        'text': _selectedLanguage == "Bangla"
            ? "দুঃখিত, টাইমআউট অথবা ইন্টারনেট সমস্যা হয়েছে। আবার চেষ্টা করুন।"
            : "Request timed out or connection failed. Please try again.",
        'isUser': false,
        'timestamp': FieldValue.serverTimestamp(),
      });
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent + 120,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_currentUser == null) {
      return const Scaffold(body: Center(child: Text("Please login first")));
    }

    final chatQuery = FirebaseFirestore.instance
        .collection('users')
        .doc(_currentUser!.uid)
        .collection('ai_chats')
        .orderBy('timestamp', descending: false);

    return Scaffold(
      backgroundColor: const Color(0xffF8FBF8),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.black87,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: const BoxDecoration(
                color: Color(0xffE8F5E9),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.auto_awesome,
                color: Color(0xff4CAF50),
                size: 18,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Nutrigo AI",
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  Text(
                    "Diet & Health Guide",
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: const Color(0xff4CAF50),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: const Color(0xffE8F5E9),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xffC8E6C9)),
              ),
              child: Row(
                children: [
                  _buildLanguageButton("English", "ENG"),
                  _buildLanguageButton("Bangla", "বাং"),
                ],
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: chatQuery.snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting &&
                    !snapshot.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(color: Color(0xff4CAF50)),
                  );
                }

                final docs = snapshot.data?.docs ?? [];

                return ListView(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  children: [
                    _buildChatBubble(
                      text: _selectedLanguage == "Bangla"
                          ? "হ্যালো! আমি Nutrigo AI। আপনার BMI, খাবার, ডায়েট ও পানির হিসাব জানতে প্রশ্ন করুন! 🥗"
                          : "Hello! I am Nutrigo AI. Ask me about your BMI, meal plans, or send food photos! 🥗",
                      isUser: false,
                    ),
                    ...docs.map((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      return _buildChatBubble(
                        text: data['text'] ?? "",
                        isUser: data['isUser'] ?? false,
                        base64Image: data['imageBase64'],
                      );
                    }),
                  ],
                );
              },
            ),
          ),
          if (_isLoading)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Color(0xff4CAF50),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    _selectedLanguage == "Bangla"
                        ? "বিশ্লেষণ করছে..."
                        : "Thinking...",
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
          if (_selectedImage != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Colors.white,
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.file(
                      _selectedImage!,
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    _selectedLanguage == "Bangla"
                        ? "ছবি প্রস্তুত"
                        : "Image ready",
                    style: GoogleFonts.poppins(fontSize: 12),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(
                      Icons.close,
                      color: Colors.redAccent,
                      size: 20,
                    ),
                    onPressed: () => setState(() {
                      _selectedImage = null;
                      _selectedImageBase64 = null;
                    }),
                  ),
                ],
              ),
            ),
          _buildInputBar(),
        ],
      ),
    );
  }

  Widget _buildLanguageButton(String langKey, String label) {
    final isSelected = _selectedLanguage == langKey;
    return GestureDetector(
      onTap: () {
        if (_selectedLanguage != langKey) {
          setState(() => _selectedLanguage = langKey);
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xff4CAF50) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
            color: isSelected ? Colors.white : const Color(0xff2E7D32),
          ),
        ),
      ),
    );
  }

  Widget _buildChatBubble({
    required String text,
    required bool isUser,
    String? base64Image,
  }) {
    Uint8List? imageBytes;
    if (base64Image != null && base64Image.isNotEmpty) {
      try {
        imageBytes = base64Decode(base64Image);
      } catch (_) {}
    }
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.82,
        ),
        decoration: BoxDecoration(
          color: isUser ? const Color(0xff4CAF50) : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(isUser ? 18 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 18),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (imageBytes != null) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.memory(
                  imageBytes,
                  height: 140,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 8),
            ],
            Text(
              text,
              style: GoogleFonts.poppins(
                fontSize: 13.5,
                height: 1.45,
                color: isUser ? Colors.white : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            IconButton(
              icon: const Icon(
                Icons.photo_camera_rounded,
                color: Color(0xff4CAF50),
              ),
              onPressed: () => _pickImage(ImageSource.camera),
            ),
            IconButton(
              icon: const Icon(Icons.image_rounded, color: Color(0xff4CAF50)),
              onPressed: () => _pickImage(ImageSource.gallery),
            ),
            Expanded(
              child: TextField(
                controller: _controller,
                textCapitalization: TextCapitalization.sentences,
                style: GoogleFonts.poppins(fontSize: 14),
                decoration: InputDecoration(
                  hintText: _selectedLanguage == "Bangla"
                      ? "খাবার বা স্বাস্থ্য সম্পর্কে জিজ্ঞাসা করুন..."
                      : "Ask about meals or profile...",
                  hintStyle: GoogleFonts.poppins(
                    fontSize: 13,
                    color: Colors.grey.shade400,
                  ),
                  filled: true,
                  fillColor: const Color(0xffF4F8F4),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                ),
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
            const SizedBox(width: 8),
            CircleAvatar(
              backgroundColor: const Color(0xff4CAF50),
              radius: 22,
              child: IconButton(
                icon: const Icon(
                  Icons.send_rounded,
                  color: Colors.white,
                  size: 20,
                ),
                onPressed: _sendMessage,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
