import 'package:cloud_firestore/cloud_firestore.dart';

class FeedPostModel {
  final String id;
  final String userId;
  final String userName;
  final String? userPhotoUrl;
  final String textContent;
  final String? mediaUrl;
  final String? mediaType; // 'image' or 'video'
  final DateTime createdAt;
  final List<String> upvotes;
  final List<String> downvotes;
  final int commentCount;
  final List<String> savedBy;

  FeedPostModel({
    required this.id,
    required this.userId,
    required this.userName,
    this.userPhotoUrl,
    required this.textContent,
    this.mediaUrl,
    this.mediaType,
    required this.createdAt,
    required this.upvotes,
    required this.downvotes,
    required this.commentCount,
    required this.savedBy,
  });

  int get score => upvotes.length - downvotes.length;

  factory FeedPostModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return FeedPostModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? 'Nutritionist',
      userPhotoUrl: data['userPhotoUrl'],
      textContent: data['textContent'] ?? '',
      mediaUrl: data['mediaUrl'],
      mediaType: data['mediaType'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      upvotes: List<String>.from(data['upvotes'] ?? []),
      downvotes: List<String>.from(data['downvotes'] ?? []),
      commentCount: data['commentCount'] ?? 0,
      savedBy: List<String>.from(data['savedBy'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userName': userName,
      'userPhotoUrl': userPhotoUrl,
      'textContent': textContent,
      'mediaUrl': mediaUrl,
      'mediaType': mediaType,
      'createdAt': Timestamp.fromDate(createdAt),
      'upvotes': upvotes,
      'downvotes': downvotes,
      'commentCount': commentCount,
      'savedBy': savedBy,
    };
  }
}
