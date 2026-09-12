import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../login/login_screen.dart';
import 'models/feed_post_model.dart';
import 'services/feed_service.dart';

class NutritionFeedScreen extends StatefulWidget {
  const NutritionFeedScreen({super.key});

  @override
  State<NutritionFeedScreen> createState() => _NutritionFeedScreenState();
}

class _NutritionFeedScreenState extends State<NutritionFeedScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _postCtrl = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  File? _selectedImage;
  bool _isPosting = false;

  final currentUserId = FirebaseAuth.instance.currentUser?.uid;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showCommunityGuidelinesDialog();
      _cleanupBannedUsersPosts();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _postCtrl.dispose();
    super.dispose();
  }

  // ফায়ারস্টোর থেকে ব্যানড অ্যাকাউন্টের পোস্ট ক্লিনআপ
  Future<void> _cleanupBannedUsersPosts() async {
    try {
      final bannedUsersSnap = await FirebaseFirestore.instance
          .collection('users')
          .where('isAccountBanned', isEqualTo: true)
          .get();

      for (final userDoc in bannedUsersSnap.docs) {
        await FeedService.purgeUserPosts(userDoc.id);
      }
    } catch (_) {}
  }

  void _showCommunityGuidelinesDialog() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => AlertDialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xffE8F5E9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.shield_outlined,
                color: Color(0xff4CAF50),
                size: 24,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                "Community Guidelines",
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Welcome to Nutrition Feed! Please keep all discussions strictly focused on nutrition, diet, food recipes, and wellness.",
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: Colors.black87,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                "Strictly Prohibited Topics:",
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Colors.redAccent,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.shade100),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _prohibitedItem("Adult & Sensitive Content"),
                    _prohibitedItem("Violent content & Abuse"),
                    _prohibitedItem("Political discussions & Propaganda"),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                "⚠️ Posting or commenting on these topics triggers automated warnings. Reaching 3 strikes results in permanent account termination and removal of all your posts.",
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.grey.shade700,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xff4CAF50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                "I Agree & Continue",
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _prohibitedItem(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 2),
            child: Icon(Icons.cancel, color: Colors.redAccent, size: 14),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.red.shade900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _forceLogoutToLogin() {
    FirebaseAuth.instance.signOut();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  void _showModerationDialog(ModerationResult result) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: Row(
          children: [
            Icon(
              result.isBanned
                  ? Icons.block_rounded
                  : Icons.warning_amber_rounded,
              color: result.isBanned ? Colors.red : Colors.orange,
              size: 28,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                result.isBanned ? "Account Disabled" : "Content Warning",
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  fontSize: 17,
                  color: result.isBanned ? Colors.red : Colors.orange.shade800,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              result.message,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.black87,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: result.isBanned
                    ? Colors.red.shade50
                    : Colors.orange.shade50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                result.isBanned
                    ? "Violations: 3/3 (Account Terminated & Posts Cleared)"
                    : "Warning Strike: ${result.strikeCount} of 3\n(Account will be disabled after 3 strikes)",
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: result.isBanned
                      ? Colors.red.shade900
                      : Colors.orange.shade900,
                ),
              ),
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: result.isBanned
                    ? Colors.red
                    : const Color(0xff4CAF50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () {
                Navigator.pop(ctx);
                if (result.isBanned) {
                  _forceLogoutToLogin();
                }
              },
              child: Text(
                result.isBanned ? "Go to Login" : "I Understand",
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickImage(ImageSource source, StateSetter setModalState) async {
    try {
      final XFile? picked = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 70,
      );
      if (picked != null) {
        setModalState(() {
          _selectedImage = File(picked.path);
        });
      }
    } catch (e) {
      debugPrint("Error picking image: $e");
    }
  }

  Future<void> _submitPost() async {
    final text = _postCtrl.text.trim();
    if (text.isEmpty && _selectedImage == null) return;

    setState(() => _isPosting = true);

    String? base64Image;
    if (_selectedImage != null) {
      final bytes = await _selectedImage!.readAsBytes();
      base64Image = base64Encode(bytes);
    }

    final result = await FeedService.createPost(
      textContent: text,
      mediaUrl: base64Image,
      mediaType: base64Image != null ? 'image' : null,
    );

    setState(() => _isPosting = false);

    if (!mounted) return;

    if (result != null) {
      Navigator.pop(context);
      _showModerationDialog(result);
    } else {
      _postCtrl.clear();
      setState(() => _selectedImage = null);
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Shared to Nutrition Feed! 🥗",
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: const Color(0xff4CAF50),
        ),
      );
    }
  }

  void _showCommentsModal(String postId) {
    final TextEditingController commentCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
          left: 18,
          right: 18,
          top: 18,
        ),
        child: SizedBox(
          height: MediaQuery.of(ctx).size.height * 0.65,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Comments",
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const Divider(),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('feed_posts')
                      .doc(postId)
                      .collection('comments')
                      .orderBy('createdAt', descending: true)
                      .snapshots(),
                  builder: (context, snap) {
                    if (!snap.hasData) {
                      return const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xff4CAF50),
                        ),
                      );
                    }
                    final comments = snap.data!.docs;
                    if (comments.isEmpty) {
                      return Center(
                        child: Text(
                          "No comments yet. Start the conversation!",
                          style: GoogleFonts.poppins(color: Colors.grey),
                        ),
                      );
                    }
                    return ListView.builder(
                      itemCount: comments.length,
                      itemBuilder: (context, i) {
                        final data = comments[i].data() as Map<String, dynamic>;
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CircleAvatar(
                                radius: 16,
                                backgroundColor: const Color(0xffE8F5E9),
                                child: const Icon(
                                  Icons.person,
                                  size: 18,
                                  color: Color(0xff4CAF50),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        data['userName'] ?? 'Member',
                                        style: GoogleFonts.poppins(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        data['commentText'] ?? '',
                                        style: GoogleFonts.poppins(
                                          fontSize: 13,
                                          color: Colors.black87,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: commentCtrl,
                        decoration: InputDecoration(
                          hintText: "Write a nutrition reply...",
                          hintStyle: GoogleFonts.poppins(fontSize: 13),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    CircleAvatar(
                      backgroundColor: const Color(0xff4CAF50),
                      child: IconButton(
                        icon: const Icon(
                          Icons.send_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                        onPressed: () async {
                          final text = commentCtrl.text.trim();
                          if (text.isEmpty) return;
                          commentCtrl.clear();
                          final res = await FeedService.addComment(
                            postId: postId,
                            commentText: text,
                          );
                          if (res != null) {
                            if (!mounted) return;
                            Navigator.pop(ctx);
                            _showModerationDialog(res);
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCreatePostModal() {
    _selectedImage = null;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom,
                left: 20,
                right: 20,
                top: 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Create Nutrition Post",
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _postCtrl,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText:
                            "Share healthy recipes, food pictures, diet tips...",
                        hintStyle: GoogleFonts.poppins(
                          color: Colors.grey.shade500,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (_selectedImage != null)
                      Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: Image.file(
                              _selectedImage!,
                              height: 160,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                          ),
                          Positioned(
                            top: 8,
                            right: 8,
                            child: CircleAvatar(
                              backgroundColor: Colors.black54,
                              radius: 16,
                              child: IconButton(
                                padding: EdgeInsets.zero,
                                icon: const Icon(
                                  Icons.close,
                                  size: 18,
                                  color: Colors.white,
                                ),
                                onPressed: () =>
                                    setModalState(() => _selectedImage = null),
                              ),
                            ),
                          ),
                        ],
                      ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        OutlinedButton.icon(
                          onPressed: () =>
                              _pickImage(ImageSource.gallery, setModalState),
                          icon: const Icon(
                            Icons.photo_library_rounded,
                            size: 18,
                            color: Color(0xff4CAF50),
                          ),
                          label: Text(
                            "Gallery",
                            style: GoogleFonts.poppins(
                              color: const Color(0xff4CAF50),
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xff4CAF50)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        OutlinedButton.icon(
                          onPressed: () =>
                              _pickImage(ImageSource.camera, setModalState),
                          icon: const Icon(
                            Icons.camera_alt_rounded,
                            size: 18,
                            color: Color(0xff4CAF50),
                          ),
                          label: Text(
                            "Camera",
                            style: GoogleFonts.poppins(
                              color: const Color(0xff4CAF50),
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xff4CAF50)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xff4CAF50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: _isPosting ? null : _submitPost,
                        child: _isPosting
                            ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                            : Text(
                                "Post to Community",
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildPostList({required bool showSavedOnly}) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .where('isAccountBanned', isEqualTo: true)
          .snapshots(),
      builder: (context, bannedUsersSnap) {
        final bannedUserIds = bannedUsersSnap.hasData
            ? bannedUsersSnap.data!.docs.map((d) => d.id).toSet()
            : <String>{};

        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('feed_posts')
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(
                child: CircularProgressIndicator(color: Color(0xff4CAF50)),
              );
            }

            var posts = snapshot.data!.docs
                .map((doc) => FeedPostModel.fromFirestore(doc))
                .where((p) => !bannedUserIds.contains(p.userId))
                .toList();

            if (showSavedOnly) {
              posts = posts
                  .where((p) => p.savedBy.contains(currentUserId))
                  .toList();
            }

            posts.sort((a, b) => b.score.compareTo(a.score));

            if (posts.isEmpty) {
              return Center(
                child: Text(
                  showSavedOnly
                      ? "No saved posts yet!\nBookmark posts to see them here."
                      : "Welcome to Nutrition Feed!\nBe the first to share healthy habits.",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(color: Colors.grey.shade600),
                ),
              );
            }

            return RefreshIndicator(
              color: const Color(0xff4CAF50),
              onRefresh: () async => setState(() {}),
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
                itemCount: posts.length,
                itemBuilder: (context, index) {
                  final post = posts[index];
                  final isSaved = post.savedBy.contains(currentUserId);
                  final isUpvoted = post.upvotes.contains(currentUserId);
                  final isDownvoted = post.downvotes.contains(currentUserId);

                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(.04),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: const Color(0xffE8F5E9),
                              child: const Icon(
                                Icons.person,
                                color: Color(0xff4CAF50),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                post.userName,
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            if (post.userId == currentUserId)
                              IconButton(
                                icon: const Icon(
                                  Icons.delete_outline_rounded,
                                  color: Colors.redAccent,
                                  size: 20,
                                ),
                                onPressed: () =>
                                    FeedService.deletePost(post.id),
                              ),
                          ],
                        ),
                        if (post.textContent.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          Text(
                            post.textContent,
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: Colors.black87,
                              height: 1.5,
                            ),
                          ),
                        ],
                        if (post.mediaUrl != null &&
                            post.mediaUrl!.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: Image.memory(
                              base64Decode(post.mediaUrl!),
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ],
                        const SizedBox(height: 14),
                        const Divider(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                IconButton(
                                  icon: Icon(
                                    Icons.thumb_up_alt_rounded,
                                    color: isUpvoted
                                        ? const Color(0xff4CAF50)
                                        : Colors.grey,
                                    size: 20,
                                  ),
                                  onPressed: () =>
                                      FeedService.toggleUpvote(post.id),
                                ),
                                Text(
                                  "${post.score}",
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(
                                    Icons.thumb_down_alt_rounded,
                                    color: isDownvoted
                                        ? Colors.redAccent
                                        : Colors.grey,
                                    size: 20,
                                  ),
                                  onPressed: () =>
                                      FeedService.toggleDownvote(post.id),
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                IconButton(
                                  icon: const Icon(
                                    Icons.chat_bubble_outline_rounded,
                                    color: Colors.grey,
                                    size: 20,
                                  ),
                                  onPressed: () => _showCommentsModal(post.id),
                                ),
                                Text(
                                  "${post.commentCount}",
                                  style: GoogleFonts.poppins(
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                                IconButton(
                                  tooltip: isSaved
                                      ? "Unsave Post"
                                      : "Save Post",
                                  icon: Icon(
                                    isSaved
                                        ? Icons.bookmark_rounded
                                        : Icons.bookmark_border_rounded,
                                    color: isSaved
                                        ? const Color(0xff4CAF50)
                                        : Colors.grey,
                                  ),
                                  onPressed: () =>
                                      FeedService.toggleSave(post.id),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF8FBF8),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        foregroundColor: Colors.black87,
        title: Text(
          "Nutrition Community",
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            tooltip: "Community Guidelines",
            icon: const Icon(
              Icons.info_outline_rounded,
              color: Color(0xff4CAF50),
            ),
            onPressed: _showCommunityGuidelinesDialog,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xff4CAF50),
          unselectedLabelColor: Colors.grey,
          indicatorColor: const Color(0xff4CAF50),
          indicatorWeight: 3,
          labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600),
          tabs: const [
            Tab(text: "All Posts"),
            Tab(text: "Saved Posts"),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xff4CAF50),
        onPressed: _showCreatePostModal,
        icon: const Icon(
          Icons.add_photo_alternate_rounded,
          color: Colors.white,
        ),
        label: Text(
          "Share Meal / Tip",
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildPostList(showSavedOnly: false),
          _buildPostList(showSavedOnly: true),
        ],
      ),
    );
  }
}
