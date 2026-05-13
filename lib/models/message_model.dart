import 'package:cloud_firestore/cloud_firestore.dart';

class MessageModel {
  final String senderId;
  final String senderEmail;
  final String receiverId;
  final String message;
  final String? mediaUrl;
  final String? fileName;
  final Timestamp timestamp;
  final bool isRead;
  final bool isStarred;
  final String messageType; // text, voice, image, doc, location

  MessageModel({
    required this.senderId,
    required this.senderEmail,
    required this.receiverId,
    required this.message,
  this.mediaUrl,
  this.fileName,
    required this.timestamp,
    this.isRead = false,
    this.isStarred = false,
    this.messageType = 'text',
  });

  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'senderEmail': senderEmail,
      'receiverId': receiverId,
      'message': message,
  'mediaUrl': mediaUrl,
  'fileName': fileName,
      'timestamp': timestamp,
      'isRead': isRead,
      'isStarred': isStarred,
      'messageType': messageType,
    };
  }

  factory MessageModel.fromMap(Map<String, dynamic> map) {
    return MessageModel(
      senderId: map['senderId'],
      senderEmail: map['senderEmail'],
      receiverId: map['receiverId'],
      message: map['message'],
  mediaUrl: map['mediaUrl'],
  fileName: map['fileName'],
      timestamp: map['timestamp'],
      isRead: map['isRead'] ?? false,
      isStarred: map['isStarred'] ?? false,
      messageType: map['messageType'] ?? 'text',
    );
  }
}
