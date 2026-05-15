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
  final String messageType; // text, voice, image, doc, location, deleted
  final String? replyToId;
  final String? replyToText;
  final String? replyToSender;
  final Map<String, List<String>>? reactions; // emoji -> [userIds]

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
    this.replyToId,
    this.replyToText,
    this.replyToSender,
    this.reactions,
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
      if (replyToId != null) 'replyToId': replyToId,
      if (replyToText != null) 'replyToText': replyToText,
      if (replyToSender != null) 'replyToSender': replyToSender,
    };
  }

  factory MessageModel.fromMap(Map<String, dynamic> map) {
    Map<String, List<String>>? reactions;
    if (map['reactions'] != null) {
      reactions = (map['reactions'] as Map<String, dynamic>).map(
        (k, v) => MapEntry(k, List<String>.from(v ?? [])),
      );
    }
    return MessageModel(
      senderId: map['senderId'] ?? '',
      senderEmail: map['senderEmail'] ?? '',
      receiverId: map['receiverId'] ?? '',
      message: map['message'] ?? '',
      mediaUrl: map['mediaUrl'],
      fileName: map['fileName'],
      timestamp: map['timestamp'] ?? Timestamp.now(),
      isRead: map['isRead'] ?? false,
      isStarred: map['isStarred'] ?? false,
      messageType: map['messageType'] ?? 'text',
      replyToId: map['replyToId'],
      replyToText: map['replyToText'],
      replyToSender: map['replyToSender'],
      reactions: reactions,
    );
  }
}
