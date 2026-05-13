import 'package:cloud_firestore/cloud_firestore.dart';

class StatusModel {
  final String uid;
  final String userName;
  final String? profilePic;
  final String mediaUrl;
  final String type; // image, video
  final Timestamp timestamp;
  final List<String> viewers;

  StatusModel({
    required this.uid,
    required this.userName,
    this.profilePic,
    required this.mediaUrl,
    required this.type,
    required this.timestamp,
    required this.viewers,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'userName': userName,
      'profilePic': profilePic,
      'mediaUrl': mediaUrl,
      'type': type,
      'timestamp': timestamp,
      'viewers': viewers,
    };
  }

  factory StatusModel.fromMap(Map<String, dynamic> map) {
    return StatusModel(
      uid: map['uid'],
      userName: map['userName'],
      profilePic: map['profilePic'],
      mediaUrl: map['mediaUrl'],
      type: map['type'],
      timestamp: map['timestamp'],
      viewers: List<String>.from(map['viewers'] ?? []),
    );
  }
}
