import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;

class MyComplaintsScreen extends StatelessWidget {
  const MyComplaintsScreen({super.key});

  // ============================================================
  // BACKGROUND EMAILJS TRIGGER FOR UNSOLVED ESCALATION
  // ============================================================
  Future<void> _sendUnsolvedEscalationEmail({
    required String userEmail,
    required String originalMessage,
  }) async {
    const serviceId = "service_8suz544";
    const templateId = "template_pdz9ec5";
    const publicKey = "D_mHA4Hb-IlwUZ1oV";

    final emailUrl = Uri.parse('https://api.emailjs.com/api/v1.0/email/send');
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
          'from_email': userEmail,
          'message':
              "[RE-OPENED: UNSOLVED]\n\nUser marked this complaint as Unsolved:\n\"$originalMessage\"",
        },
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text("My Complaints")),
        body: const Center(child: Text("Please log in to view complaints")),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "My Complaints",
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        iconTheme: IconThemeData(color: isDark ? Colors.white : Colors.black87),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('complaints')
            .where('userId', isEqualTo: user.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xff4CAF50)),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                "Error loading complaints: ${snapshot.error}",
                style: GoogleFonts.poppins(color: Colors.redAccent),
              ),
            );
          }

          final docs = snapshot.data?.docs ?? [];

          if (docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.mark_email_read_outlined,
                    size: 64,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "No complaints submitted yet.",
                    style: GoogleFonts.poppins(
                      color: Colors.grey.shade600,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            );
          }

          final sortedDocs = docs.toList()
            ..sort((a, b) {
              final Map<String, dynamic> dataA =
                  a.data() as Map<String, dynamic>;
              final Map<String, dynamic> dataB =
                  b.data() as Map<String, dynamic>;
              final tA = dataA['timestamp'] as Timestamp?;
              final tB = dataB['timestamp'] as Timestamp?;
              if (tA == null || tB == null) return 0;
              return tB.compareTo(tA);
            });

          return ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            itemCount: sortedDocs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final data = sortedDocs[index].data() as Map<String, dynamic>;
              final docId = sortedDocs[index].id;
              final message = data['message'] ?? "No message";
              final status = data['status'] ?? "Pending";
              final timestamp = (data['timestamp'] as Timestamp?)?.toDate();
              final lastUnsolvedPing = (data['lastUnsolvedPing'] as Timestamp?)
                  ?.toDate();

              Color statusColor = Colors.orange;
              if (status == "Solved") statusColor = const Color(0xff4CAF50);
              if (status == "Unsolved") statusColor = Colors.redAccent;

              return Container(
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xff1E1E1E) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  title: Text(
                    message,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Row(
                      children: [
                        Icon(
                          Icons.calendar_today_rounded,
                          size: 12,
                          color: Colors.grey.shade500,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          timestamp != null
                              ? "${timestamp.day}/${timestamp.month}/${timestamp.year}"
                              : "Recently",
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: Colors.grey.shade500,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            status,
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: statusColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  onTap: () => _showComplaintDetails(
                    context: context,
                    docId: docId,
                    message: message,
                    status: status,
                    userEmail: user.email ?? "User",
                    lastUnsolvedPing: lastUnsolvedPing,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showComplaintDetails({
    required BuildContext context,
    required String docId,
    required String message,
    required String status,
    required String userEmail,
    required DateTime? lastUnsolvedPing,
  }) {
    final bool isSolvedPermanently = status == "Solved";

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (bottomCtx) {
        bool isProcessing = false;

        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(bottomCtx).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Complaint Details",
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color:
                              (status == "Solved"
                                      ? const Color(0xff4CAF50)
                                      : (status == "Unsolved"
                                            ? Colors.redAccent
                                            : Colors.orange))
                                  .withOpacity(0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          status,
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: status == "Solved"
                                ? const Color(0xff4CAF50)
                                : (status == "Unsolved"
                                      ? Colors.redAccent
                                      : Colors.orange),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      message,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: Colors.black87,
                        height: 1.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Solved হলে চিরতরে লক থাকবে
                  if (isSolvedPermanently) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xffE8F5E9),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xffA5D6A7)),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.check_circle_rounded,
                            color: Color(0xff4CAF50),
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              "This complaint is resolved and completed.",
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xff2E7D32),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    Text(
                      "Is your issue resolved?",
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        // Solved Button
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xff4CAF50),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                            onPressed: isProcessing
                                ? null
                                : () async {
                                    setModalState(() => isProcessing = true);
                                    await FirebaseFirestore.instance
                                        .collection('complaints')
                                        .doc(docId)
                                        .update({'status': 'Solved'});
                                    if (context.mounted)
                                      Navigator.pop(bottomCtx);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          "Complaint marked as Solved! ✅",
                                        ),
                                        backgroundColor: Color(0xff4CAF50),
                                      ),
                                    );
                                  },
                            icon: const Icon(
                              Icons.check_circle_outline_rounded,
                              size: 18,
                            ),
                            label: Text(
                              "Solved",
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),

                        // Unsolved Button
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Colors.redAccent),
                              foregroundColor: Colors.redAccent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: isProcessing
                                ? null
                                : () async {
                                    // ২৪ ঘণ্টা লিমিট ভেরিফিকেশন
                                    if (lastUnsolvedPing != null) {
                                      final diff = DateTime.now().difference(
                                        lastUnsolvedPing,
                                      );
                                      if (diff.inHours < 24) {
                                        final remaining = (24 - diff.inHours)
                                            .clamp(1, 24);
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              "You can notify again as unsolved in $remaining hours.",
                                            ),
                                            backgroundColor: Colors.orange,
                                          ),
                                        );
                                        return;
                                      }
                                    }

                                    setModalState(() => isProcessing = true);

                                    try {
                                      // ১. EmailJS দিয়ে নোটিফিকেশন মেল পাঠানো
                                      await _sendUnsolvedEscalationEmail(
                                        userEmail: userEmail,
                                        originalMessage: message,
                                      );

                                      // ২. Firestore আপডেট (স্ট্যাটাস এবং ২৪ ঘণ্টার টাইমার)
                                      await FirebaseFirestore.instance
                                          .collection('complaints')
                                          .doc(docId)
                                          .update({
                                            'status': 'Unsolved',
                                            'lastUnsolvedPing': Timestamp.now(),
                                          });

                                      if (context.mounted)
                                        Navigator.pop(bottomCtx);
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            "Support notified again as Unsolved! ✉️",
                                          ),
                                          backgroundColor: Colors.redAccent,
                                        ),
                                      );
                                    } catch (e) {
                                      setModalState(() => isProcessing = false);
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text("Error: $e"),
                                          backgroundColor: Colors.redAccent,
                                        ),
                                      );
                                    }
                                  },
                            icon: const Icon(
                              Icons.highlight_off_rounded,
                              size: 18,
                            ),
                            label: Text(
                              "Unsolved",
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 8),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
