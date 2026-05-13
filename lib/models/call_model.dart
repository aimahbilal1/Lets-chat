import 'package:cloud_firestore/cloud_firestore.dart';

class CallModel {
  final String callerId;
  final String receiverId;
  final String callerName;
  final String receiverName;
  final Timestamp timestamp;
  final String type; // audio, video
  final String status; // missed, outgoing, incoming

  CallModel({
    required this.callerId,
    required this.receiverId,
    required this.callerName,
    required this.receiverName,
    required this.timestamp,
    required this.type,
    required this.status,
  });

  Map<String, dynamic> toMap() {
    return {
      'callerId': callerId,
      'receiverId': receiverId,
      'callerName': callerName,
      'receiverName': receiverName,
      'timestamp': timestamp,
      'type': type,
      'status': status,
    };
  }

  factory CallModel.fromMap(Map<String, dynamic> map) {
    return CallModel(
      callerId: map['callerId'],
      receiverId: map['receiverId'],
      callerName: map['callerName'],
      receiverName: map['receiverName'],
      timestamp: map['timestamp'],
      type: map['type'],
      status: map['status'],
    );
  }
}
