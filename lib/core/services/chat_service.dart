import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../models/message_model.dart';

class ChatService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Send message
  Future<void> sendMessage(String receiverId, String message, {String type = 'text'}) async {
    final String currentUserId = _auth.currentUser!.uid;
    final String currentUserEmail = _auth.currentUser!.email.toString();
    final Timestamp timestamp = Timestamp.now();

    MessageModel newMessage = MessageModel(
      senderId: currentUserId,
      senderEmail: currentUserEmail,
      receiverId: receiverId,
      message: message,
      timestamp: timestamp,
      messageType: type,
    );

    List<String> ids = [currentUserId, receiverId];
    ids.sort();
    String chatRoomId = ids.join("_");

    await _firestore
        .collection('chat_rooms')
        .doc(chatRoomId)
        .collection('messages')
        .add(newMessage.toMap());
        
    // Update last message in chat room metadata (optional but recommended for chat list)
    await _firestore.collection('chat_rooms').doc(chatRoomId).set({
      'lastMessage': message,
      'lastMessageTime': timestamp,
      'users': ids,
    }, SetOptions(merge: true));
  }

  // Mark message as read
  Future<void> markMessageAsRead(String chatRoomId, String messageId) async {
    await _firestore
        .collection('chat_rooms')
        .doc(chatRoomId)
        .collection('messages')
        .doc(messageId)
        .update({'isRead': true});
  }

  // Toggle star message
  Future<void> toggleStarMessage(String chatRoomId, String messageId, bool isStarred) async {
    await _firestore
        .collection('chat_rooms')
        .doc(chatRoomId)
        .collection('messages')
        .doc(messageId)
        .update({'isStarred': !isStarred});
  }

  // Toggle favorite user
  Future<void> toggleFavoriteUser(String userId) async {
    final String currentUserId = _auth.currentUser!.uid;
    final userDoc = _firestore.collection('users').doc(currentUserId);
    
    final doc = await userDoc.get();
    List favourites = doc.data()?['favourites'] ?? [];
    
    if (favourites.contains(userId)) {
      favourites.remove(userId);
    } else {
      favourites.add(userId);
    }
    
    await userDoc.update({'favourites': favourites});
  }

  // Get messages
  Stream<QuerySnapshot> getMessages(String userId, String otherUserId) {
    List<String> ids = [userId, otherUserId];
    ids.sort();
    String chatRoomId = ids.join("_");

    return _firestore
        .collection('chat_rooms')
        .doc(chatRoomId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots();
  }

  // Get users stream for the chat list
  Stream<List<Map<String, dynamic>>> getUsersStream() {
    return _firestore.collection('users').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final user = doc.data();
        return user;
      }).toList();
    });
  }

  // Get starred messages for current user
  Stream<QuerySnapshot> getStarredMessages() {
    return _firestore
        .collectionGroup('messages')
        .where('isStarred', isEqualTo: true)
        .snapshots();
  }

  // Perform chat backup (mock logic - updating timestamp)
  Future<void> performBackup() async {
    final String currentUserId = _auth.currentUser!.uid;
    await _firestore.collection('users').doc(currentUserId).update({
      'lastBackup': FieldValue.serverTimestamp(),
    });
  }

  // Search users by name or email
  Stream<List<Map<String, dynamic>>> searchUsers(String query) {
    return _firestore
        .collection('users')
        .where('email', isGreaterThanOrEqualTo: query)
        .where('email', isLessThanOrEqualTo: query + '\uf8ff')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => doc.data()).toList();
    });
  }

  // Get call logs for current user
  Stream<QuerySnapshot> getCallLogs() {
    final String currentUserId = _auth.currentUser!.uid;
    return _firestore
        .collection('calls')
        .where('users', arrayContains: currentUserId)
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  // Start/Log a call
  Future<void> logCall(String receiverId, String receiverName, String type) async {
    final String currentUserId = _auth.currentUser!.uid;
    final String currentUserName = _auth.currentUser!.displayName ?? "User";
    
    await _firestore.collection('calls').add({
      'users': [currentUserId, receiverId],
      'callerId': currentUserId,
      'receiverId': receiverId,
      'callerName': currentUserName,
      'receiverName': receiverName,
      'timestamp': FieldValue.serverTimestamp(),
      'type': type,
      'status': 'outgoing',
    });
  }

  // Clear call log for current user
  Future<void> clearCallLog() async {
    final String currentUserId = _auth.currentUser!.uid;
    final snapshot = await _firestore
        .collection('calls')
        .where('users', arrayContains: currentUserId)
        .get();
        
    for (var doc in snapshot.docs) {
      await doc.reference.delete();
    }
  }

  // Join community logic
  Future<void> joinCommunity(String communityName) async {
    final String currentUserId = _auth.currentUser!.uid;
    final communityDoc = _firestore.collection('communities').doc(communityName);
    
    await communityDoc.set({
      'name': communityName,
      'members': FieldValue.arrayUnion([currentUserId]),
    }, SetOptions(merge: true));
  }

  // Get status updates
  Stream<QuerySnapshot> getStatusUpdates() {
    return _firestore
        .collection('status')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  // Post a status update (media or text)
  Future<void> postStatus(String? mediaUrl, String type, {String? statusText}) async {
    final String currentUserId = _auth.currentUser!.uid;
    final String currentUserName = _auth.currentUser!.displayName ?? "User";
    
    await _firestore.collection('status').add({
      'uid': currentUserId,
      'userName': currentUserName,
      'mediaUrl': mediaUrl,
      'statusText': statusText,
      'type': type,
      'timestamp': FieldValue.serverTimestamp(),
      'viewers': [],
    });
  }

  // Get communities stream
  Stream<QuerySnapshot> getCommunitiesStream() {
    return _firestore.collection('communities').snapshots();
  }

  // Search communities
  Stream<QuerySnapshot> searchCommunities(String query) {
    return _firestore
        .collection('communities')
        .where('name', isGreaterThanOrEqualTo: query)
        .where('name', isLessThanOrEqualTo: query + '\uf8ff')
        .snapshots();
  }
}
