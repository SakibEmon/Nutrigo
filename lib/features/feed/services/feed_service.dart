import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ModerationResult {
  final bool isRestricted;
  final int strikeCount;
  final bool isBanned;
  final String message;

  ModerationResult({
    required this.isRestricted,
    required this.strikeCount,
    required this.isBanned,
    required this.message,
  });
}

class FeedService {
  static final _firestore = FirebaseFirestore.instance;
  static final _auth = FirebaseAuth.instance;

  // ব্যাকগ্রাউন্ড ফিল্টারিং কিওয়ার্ড
  static const List<String> _forbiddenKeywords = [
    'sex',
    'sexy',
    'porn',
    'nude',
    'nudity',
    'adult',
    'violation',
    'violence',
    'politics',
    'political',
    'election',
    'minister',
    'vote',
  ];

  static bool isRestrictedContent(String text) {
    final lower = text.toLowerCase();
    for (final word in _forbiddenKeywords) {
      if (lower.contains(word)) return true;
    }
    return false;
  }

  // ব্যানড ইউজারের সমস্ত পোস্ট ডাটাবেজ থেকে মুছে ফেলা
  static Future<void> purgeUserPosts(String userId) async {
    try {
      final userPostsSnap = await _firestore
          .collection('feed_posts')
          .where('userId', isEqualTo: userId)
          .get();

      if (userPostsSnap.docs.isNotEmpty) {
        final batch = _firestore.batch();
        for (final doc in userPostsSnap.docs) {
          batch.delete(doc.reference);
        }
        await batch.commit();
      }
    } catch (_) {}
  }

  // পোস্ট তৈরি ও ভায়োলেশন হ্যান্ডলার
  static Future<ModerationResult?> createPost({
    required String textContent,
    String? mediaUrl,
    String? mediaType,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      return ModerationResult(
        isRestricted: false,
        strikeCount: 0,
        isBanned: false,
        message: "User not authenticated",
      );
    }

    final userDocRef = _firestore.collection('users').doc(user.uid);
    final userSnap = await userDocRef.get();
    final userData = userSnap.data() ?? {};

    if (userData['isAccountBanned'] == true) {
      await purgeUserPosts(user.uid);
      await _auth.signOut();
      return ModerationResult(
        isRestricted: true,
        strikeCount: 3,
        isBanned: true,
        message:
            "Your account is permanently disabled due to violating guidelines.",
      );
    }

    if (isRestrictedContent(textContent)) {
      int strikes = (userData['feedStrikes'] ?? 0) + 1;
      bool shouldBan = strikes >= 3;

      await userDocRef.set({
        'feedStrikes': strikes,
        'isAccountBanned': shouldBan,
        'bannedAt': shouldBan ? FieldValue.serverTimestamp() : null,
      }, SetOptions(merge: true));

      if (shouldBan) {
        await purgeUserPosts(user.uid);
        await _auth.signOut();
        return ModerationResult(
          isRestricted: true,
          strikeCount: 3,
          isBanned: true,
          message:
              "You have reached 3 strikes! Your account has been disabled and all your posts have been permanently removed.",
        );
      } else {
        return ModerationResult(
          isRestricted: true,
          strikeCount: strikes,
          isBanned: false,
          message:
              "Restricted topic detected (Adult content, Violence, or Politics). Warning $strikes of 3.",
        );
      }
    }

    await _firestore.collection('feed_posts').add({
      'userId': user.uid,
      'userName': user.displayName ?? 'Nutrition Member',
      'userPhotoUrl': user.photoURL,
      'textContent': textContent,
      'mediaUrl': mediaUrl,
      'mediaType': mediaType,
      'createdAt': FieldValue.serverTimestamp(),
      'upvotes': [],
      'downvotes': [],
      'commentCount': 0,
      'savedBy': [],
    });

    return null;
  }

  // কমেন্ট তৈরি ও ভায়োলেশন হ্যান্ডলার
  static Future<ModerationResult?> addComment({
    required String postId,
    required String commentText,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return null;

    final userDocRef = _firestore.collection('users').doc(user.uid);
    final userSnap = await userDocRef.get();
    final userData = userSnap.data() ?? {};

    if (userData['isAccountBanned'] == true) {
      await purgeUserPosts(user.uid);
      await _auth.signOut();
      return ModerationResult(
        isRestricted: true,
        strikeCount: 3,
        isBanned: true,
        message: "Account disabled.",
      );
    }

    if (isRestrictedContent(commentText)) {
      int strikes = (userData['feedStrikes'] ?? 0) + 1;
      bool shouldBan = strikes >= 3;

      await userDocRef.set({
        'feedStrikes': strikes,
        'isAccountBanned': shouldBan,
        'bannedAt': shouldBan ? FieldValue.serverTimestamp() : null,
      }, SetOptions(merge: true));

      if (shouldBan) {
        await purgeUserPosts(user.uid);
        await _auth.signOut();
        return ModerationResult(
          isRestricted: true,
          strikeCount: 3,
          isBanned: true,
          message:
              "You have reached 3 strikes! Your account has been disabled and all your posts have been permanently removed.",
        );
      } else {
        return ModerationResult(
          isRestricted: true,
          strikeCount: strikes,
          isBanned: false,
          message:
              "Restricted comment detected (Adult content, Violence, or Politics). Warning $strikes of 3.",
        );
      }
    }

    await _firestore
        .collection('feed_posts')
        .doc(postId)
        .collection('comments')
        .add({
          'userId': user.uid,
          'userName': user.displayName ?? 'Nutrition Member',
          'commentText': commentText,
          'createdAt': FieldValue.serverTimestamp(),
        });

    await _firestore.collection('feed_posts').doc(postId).update({
      'commentCount': FieldValue.increment(1),
    });

    return null;
  }

  static Future<void> toggleUpvote(String postId) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final docRef = _firestore.collection('feed_posts').doc(postId);
    final snap = await docRef.get();
    if (!snap.exists) return;

    List upvotes = List.from(snap.data()?['upvotes'] ?? []);
    List downvotes = List.from(snap.data()?['downvotes'] ?? []);

    if (upvotes.contains(user.uid)) {
      upvotes.remove(user.uid);
    } else {
      upvotes.add(user.uid);
      downvotes.remove(user.uid);
    }

    await docRef.update({'upvotes': upvotes, 'downvotes': downvotes});
  }

  static Future<void> toggleDownvote(String postId) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final docRef = _firestore.collection('feed_posts').doc(postId);
    final snap = await docRef.get();
    if (!snap.exists) return;

    List upvotes = List.from(snap.data()?['upvotes'] ?? []);
    List downvotes = List.from(snap.data()?['downvotes'] ?? []);

    if (downvotes.contains(user.uid)) {
      downvotes.remove(user.uid);
    } else {
      downvotes.add(user.uid);
      upvotes.remove(user.uid);
    }

    await docRef.update({'upvotes': upvotes, 'downvotes': downvotes});
  }

  static Future<void> toggleSave(String postId) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final docRef = _firestore.collection('feed_posts').doc(postId);
    final snap = await docRef.get();
    if (!snap.exists) return;

    List savedBy = List.from(snap.data()?['savedBy'] ?? []);
    if (savedBy.contains(user.uid)) {
      savedBy.remove(user.uid);
    } else {
      savedBy.add(user.uid);
    }
    await docRef.update({'savedBy': savedBy});
  }

  static Future<void> deletePost(String postId) async {
    await _firestore.collection('feed_posts').doc(postId).delete();
  }
}
