import 'dart:convert';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  String _selectedFilter = "All Time";
  int _selectedMonthIndex = DateTime.now().month; // 1-12
  int _selectedYear = DateTime.now().year;

  final List<String> _months = [
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

  // XP Tier
  Map<String, dynamic> _getUserTier(int xp) {
    if (xp >= 1000) {
      return {
        "title": "Master",
        "badge": "👑",
        "color": const Color(0xffFF8F00),
      };
    } else if (xp >= 500) {
      return {"title": "Elite", "badge": "⚡", "color": const Color(0xff7B1FA2)};
    } else if (xp >= 200) {
      return {"title": "Pro", "badge": "🔥", "color": const Color(0xff1565C0)};
    } else {
      return {
        "title": "Member",
        "badge": "✨",
        "color": const Color(0xff2E7D32),
      };
    }
  }

  // Month-wise account existence check
  bool _isUserActiveInSelectedMonth(Map<String, dynamic> data) {
    if (_selectedFilter != "Monthly") return true;

    final createdAt = data['createdAt'];
    if (createdAt == null) return true;

    DateTime accountCreatedDate;
    if (createdAt is Timestamp) {
      accountCreatedDate = createdAt.toDate();
    } else if (createdAt is String) {
      accountCreatedDate = DateTime.tryParse(createdAt) ?? DateTime.now();
    } else {
      return true;
    }

    // Selected month end date
    final endOfSelectedMonth = DateTime(
      _selectedYear,
      _selectedMonthIndex + 1,
      0,
      23,
      59,
      59,
    );

    // Selected মাসের শেষের আগে একাউন্ট খোলা থাকলে কেবল প্রদর্শিত হবে
    return accountCreatedDate.isBefore(endOfSelectedMonth);
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: const Color(0xffF4F8F4),
      appBar: AppBar(
        title: Text(
          "Community League 🏅",
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w700,
            fontSize: 20,
            color: const Color(0xff1B3A1E),
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.black87,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('users').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xff4CAF50)),
            );
          }

          final List<DocumentSnapshot> rawDocs = snapshot.data?.docs ?? [];

          // Filter by Month & Sort by XP
          final List<DocumentSnapshot> filteredUsers = rawDocs.where((doc) {
            final data = doc.data() as Map<String, dynamic>? ?? {};
            return _isUserActiveInSelectedMonth(data);
          }).toList();

          filteredUsers.sort((a, b) {
            final aData = a.data() as Map<String, dynamic>? ?? {};
            final bData = b.data() as Map<String, dynamic>? ?? {};
            final aXp = (aData['xp'] is num) ? (aData['xp'] as num).toInt() : 0;
            final bXp = (bData['xp'] is num) ? (bData['xp'] as num).toInt() : 0;
            return bXp.compareTo(aXp);
          });

          // Current User Rank in filtered list
          int myRank = -1;
          Map<String, dynamic>? myData;
          for (int i = 0; i < filteredUsers.length; i++) {
            if (filteredUsers[i].id == currentUserId) {
              myRank = i + 1;
              myData = filteredUsers[i].data() as Map<String, dynamic>?;
              break;
            }
          }

          final topThree = filteredUsers.take(3).toList();
          final remainingUsers = filteredUsers.skip(3).toList();

          return Stack(
            children: [
              CustomScrollView(
                slivers: [
                  // ==================================================
                  // 1. FILTER TABS
                  // ==================================================
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 10, 20, 15),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.04),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Row(
                              children: ["All Time", "Weekly", "Monthly"].map((
                                filter,
                              ) {
                                final isSelected = _selectedFilter == filter;
                                return Expanded(
                                  child: GestureDetector(
                                    onTap: () => setState(
                                      () => _selectedFilter = filter,
                                    ),
                                    child: AnimatedContainer(
                                      duration: const Duration(
                                        milliseconds: 220,
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 10,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? const Color(0xff2E7D32)
                                            : Colors.transparent,
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: Center(
                                        child: Text(
                                          filter,
                                          style: GoogleFonts.poppins(
                                            fontSize: 13,
                                            fontWeight: isSelected
                                                ? FontWeight.bold
                                                : FontWeight.w500,
                                            color: isSelected
                                                ? Colors.white
                                                : Colors.grey.shade600,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),

                          if (_selectedFilter == "Monthly") ...[
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.grey.shade200),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<int>(
                                  value: _selectedMonthIndex,
                                  isExpanded: true,
                                  icon: const Icon(
                                    Icons.event_note_rounded,
                                    color: Color(0xff2E7D32),
                                  ),
                                  items: List.generate(12, (index) {
                                    return DropdownMenuItem(
                                      value: index + 1,
                                      child: Text(
                                        "${_months[index]} $_selectedYear",
                                        style: GoogleFonts.poppins(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.black87,
                                        ),
                                      ),
                                    );
                                  }),
                                  onChanged: (val) {
                                    if (val != null) {
                                      setState(() => _selectedMonthIndex = val);
                                    }
                                  },
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),

                  // ==================================================
                  // EMPTY STATE IF NO USERS IN SELECTED MONTH
                  // ==================================================
                  if (filteredUsers.isEmpty)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 60),
                        child: Center(
                          child: Column(
                            children: [
                              const Icon(
                                Icons.person_off_outlined,
                                size: 45,
                                color: Colors.grey,
                              ),
                              const SizedBox(height: 10),
                              Text(
                                "No active members found in ${_months[_selectedMonthIndex - 1]}.",
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                  // ==================================================
                  // 2. PODIUM STAGE (TOP 3)
                  // ==================================================
                  if (topThree.isNotEmpty)
                    SliverToBoxAdapter(
                      child: _buildPodiumArena(topThree, currentUserId),
                    ),

                  // ==================================================
                  // 3. REMAINING MEMBERS LIST
                  // ==================================================
                  if (remainingUsers.isNotEmpty)
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate((context, index) {
                          final doc = remainingUsers[index];
                          final data =
                              doc.data() as Map<String, dynamic>? ?? {};
                          final rank = index + 4;
                          final isMe = doc.id == currentUserId;

                          return _buildRankTile(
                            rank: rank,
                            data: data,
                            isMe: isMe,
                          );
                        }, childCount: remainingUsers.length),
                      ),
                    ),

                  const SliverToBoxAdapter(child: SizedBox(height: 110)),
                ],
              ),

              // ==================================================
              // 4. FLOATING STICKY "MY RANK" CARD
              // ==================================================
              if (myRank != -1 && myData != null)
                Positioned(
                  bottom: 20,
                  left: 20,
                  right: 20,
                  child: _buildMyPositionBanner(myRank, myData),
                ),
            ],
          );
        },
      ),
    );
  }

  // ============================================================
  // Top 3 Podium Builder
  // ============================================================
  Widget _buildPodiumArena(
    List<DocumentSnapshot> topThree,
    String? currentUserId,
  ) {
    DocumentSnapshot? first = topThree.isNotEmpty ? topThree[0] : null;
    DocumentSnapshot? second = topThree.length > 1 ? topThree[1] : null;
    DocumentSnapshot? third = topThree.length > 2 ? topThree[2] : null;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: const EdgeInsets.fromLTRB(14, 20, 14, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: const Color(0xff4CAF50).withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // 2nd Place
          if (second != null)
            _buildPodiumColumn(
              doc: second,
              rank: 2,
              height: 100,
              medal: "🥈",
              accentColor: const Color(0xff9E9E9E),
              isMe: second.id == currentUserId,
            )
          else
            const Spacer(),

          const SizedBox(width: 8),

          // 1st Place (Winner)
          if (first != null)
            _buildPodiumColumn(
              doc: first,
              rank: 1,
              height: 130,
              medal: "👑",
              accentColor: const Color(0xffFFA000),
              isMe: first.id == currentUserId,
            ),

          const SizedBox(width: 8),

          // 3rd Place
          if (third != null)
            _buildPodiumColumn(
              doc: third,
              rank: 3,
              height: 85,
              medal: "🥉",
              accentColor: const Color(0xff8D6E63),
              isMe: third.id == currentUserId,
            )
          else
            const Spacer(),
        ],
      ),
    );
  }

  Widget _buildPodiumColumn({
    required DocumentSnapshot doc,
    required int rank,
    required double height,
    required String medal,
    required Color accentColor,
    required bool isMe,
  }) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    final name = data['name'] ?? "User";
    final age = data['age'] ?? 0;
    final xp = (data['xp'] is num) ? (data['xp'] as num).toInt() : 0;
    final base64Image = data['profileImageBase64'];
    final tier = _getUserTier(xp);

    return Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(medal, style: const TextStyle(fontSize: 24)),
          const SizedBox(height: 4),

          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: rank == 1
                        ? const Color(0xffFFB300)
                        : accentColor.withOpacity(0.5),
                    width: rank == 1 ? 2.5 : 1.5,
                  ),
                ),
                child: CircleAvatar(
                  radius: rank == 1 ? 30 : 24,
                  backgroundColor: const Color(0xffE8F5E9),
                  backgroundImage: _getImageProvider(base64Image),
                  child: base64Image == null
                      ? Text(
                          name.isNotEmpty ? name[0].toUpperCase() : "U",
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.bold,
                            fontSize: rank == 1 ? 16 : 13,
                          ),
                        )
                      : null,
                ),
              ),
              Positioned(
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 1,
                  ),
                  decoration: BoxDecoration(
                    color: tier['color'],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    tier['title'],
                    style: GoogleFonts.poppins(
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          Text(
            "$name${age > 0 ? ' ($age)' : ''}",
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: isMe ? FontWeight.bold : FontWeight.w600,
              color: isMe ? const Color(0xff2E7D32) : Colors.black87,
            ),
          ),

          Text(
            "$xp XP",
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: accentColor,
            ),
          ),

          const SizedBox(height: 8),

          Container(
            height: height,
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  accentColor.withOpacity(0.18),
                  accentColor.withOpacity(0.04),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
              border: Border.all(color: accentColor.withOpacity(0.3), width: 1),
            ),
            child: Center(
              child: Text(
                "#$rank",
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: accentColor,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // Standard User List Tile (Rank 4+)
  // ============================================================
  Widget _buildRankTile({
    required int rank,
    required Map<String, dynamic> data,
    required bool isMe,
  }) {
    final name = data['name'] ?? "User";
    final age = data['age'] ?? 0;
    final xp = (data['xp'] is num) ? (data['xp'] as num).toInt() : 0;
    final base64Image = data['profileImageBase64'];
    final tier = _getUserTier(xp);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isMe ? const Color(0xffEBF7EB) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isMe ? const Color(0xff4CAF50) : Colors.transparent,
          width: isMe ? 1.5 : 0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                "$rank",
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: Colors.grey.shade800,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),

          CircleAvatar(
            radius: 20,
            backgroundColor: const Color(0xffE8F5E9),
            backgroundImage: _getImageProvider(base64Image),
            child: base64Image == null
                ? Text(
                    name.isNotEmpty ? name[0].toUpperCase() : "U",
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "$name${age > 0 ? ' ($age)' : ''}",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontWeight: isMe ? FontWeight.bold : FontWeight.w600,
                    fontSize: 14,
                    color: isMe ? const Color(0xff2E7D32) : Colors.black87,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(tier['badge'], style: const TextStyle(fontSize: 11)),
                    const SizedBox(width: 4),
                    Text(
                      tier['title'],
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: tier['color'],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xffF4F8F4),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xffE0EFE0)),
            ),
            child: Text(
              "$xp XP",
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: const Color(0xff2E7D32),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // Floating User Position Card
  // ============================================================
  Widget _buildMyPositionBanner(int rank, Map<String, dynamic> data) {
    final name = data['name'] ?? "You";
    final age = data['age'] ?? 0;
    final xp = (data['xp'] is num) ? (data['xp'] as num).toInt() : 0;
    final base64Image = data['profileImageBase64'];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xff1B3A1E),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: const Color(0xff1B3A1E).withOpacity(0.35),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xff4CAF50),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              "#$rank",
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 12),
          CircleAvatar(
            radius: 18,
            backgroundColor: Colors.white24,
            backgroundImage: _getImageProvider(base64Image),
            child: base64Image == null
                ? Text(
                    name.isNotEmpty ? name[0].toUpperCase() : "U",
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: Colors.white,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "$name${age > 0 ? ' ($age)' : ''}",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: Colors.white,
                  ),
                ),
                Text(
                  "Your Current Standing",
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
          Text(
            "$xp XP",
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: const Color(0xff81C784),
            ),
          ),
        ],
      ),
    );
  }

  ImageProvider? _getImageProvider(String? base64Str) {
    if (base64Str != null && base64Str.isNotEmpty) {
      try {
        final Uint8List bytes = base64Decode(base64Str);
        return MemoryImage(bytes);
      } catch (_) {
        return null;
      }
    }
    return null;
  }
}
