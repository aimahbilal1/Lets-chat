import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../models/message_model.dart';

class ChatService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  void _logError(String context, Object error, [StackTrace? stackTrace]) {
    debugPrint('[ChatService] $context error: $error');
    if (stackTrace != null) {
      debugPrint('[ChatService] $context stack: $stackTrace');
    }
  }

  // Send message
  Future<void> sendMessage(
    String receiverId,
    String message, {
    String type = 'text',
    String? mediaUrl,
    String? fileName,
  }) async {
    try {
      final String currentUserId = _auth.currentUser!.uid;
      final String currentUserEmail = _auth.currentUser!.email.toString();
      final Timestamp timestamp = Timestamp.now();

      MessageModel newMessage = MessageModel(
        senderId: currentUserId,
        senderEmail: currentUserEmail,
        receiverId: receiverId,
        message: message,
        mediaUrl: mediaUrl,
        fileName: fileName,
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
    } catch (e, st) {
      _logError('sendMessage', e, st);
      rethrow;
    }
  }

  // Mark message as read
  Future<void> markMessageAsRead(String chatRoomId, String messageId) async {
    try {
      await _firestore
          .collection('chat_rooms')
          .doc(chatRoomId)
          .collection('messages')
          .doc(messageId)
          .update({'isRead': true});
    } catch (e, st) {
      _logError('markMessageAsRead', e, st);
      rethrow;
    }
  }

  // Toggle star message
  Future<void> toggleStarMessage(
    String chatRoomId,
    String messageId,
    bool isStarred,
  ) async {
    try {
      await _firestore
          .collection('chat_rooms')
          .doc(chatRoomId)
          .collection('messages')
          .doc(messageId)
          .update({'isStarred': !isStarred});
    } catch (e, st) {
      _logError('toggleStarMessage', e, st);
      rethrow;
    }
  }

  // Toggle favorite user
  Future<void> toggleFavoriteUser(String userId) async {
    try {
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
    } catch (e, st) {
      _logError('toggleFavoriteUser', e, st);
      rethrow;
    }
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
        .snapshots()
        .handleError((error, stack) => _logError('getMessages', error, stack));
  }

  Future<String?> createGroup(String name, List<String> memberIds) async {
    try {
      final String currentUserId = _auth.currentUser!.uid;
      final Set<String> members = {...memberIds, currentUserId};
      final doc = _firestore.collection('groups').doc();

      await doc.set({
        'name': name,
        'members': members.toList(),
        'createdBy': currentUserId,
        'createdAt': FieldValue.serverTimestamp(),
        'lastMessage': 'Group created',
        'lastMessageTime': FieldValue.serverTimestamp(),
      });

      await doc.collection('messages').add({
        'senderId': currentUserId,
        'senderEmail': _auth.currentUser!.email,
        'message': 'Group created',
        'timestamp': FieldValue.serverTimestamp(),
        'messageType': 'system',
      });

      return doc.id;
    } catch (e, st) {
      _logError('createGroup', e, st);
      rethrow;
    }
  }

  Stream<QuerySnapshot> getGroupsStream() {
    final String currentUserId = _auth.currentUser!.uid;
    return _firestore
        .collection('groups')
        .where('members', arrayContains: currentUserId)
        .snapshots()
        .handleError(
          (error, stack) => _logError('getGroupsStream', error, stack),
        );
  }

  Stream<QuerySnapshot> getGroupMessages(String groupId) {
    return _firestore
        .collection('groups')
        .doc(groupId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots()
        .handleError(
          (error, stack) => _logError('getGroupMessages', error, stack),
        );
  }

  Future<void> sendGroupMessage(
    String groupId,
    String message, {
    String type = 'text',
    String? mediaUrl,
    String? fileName,
  }) async {
    try {
      final String currentUserId = _auth.currentUser!.uid;
      final String currentUserEmail = _auth.currentUser!.email ?? 'user';
      final Timestamp timestamp = Timestamp.now();

      await _firestore
          .collection('groups')
          .doc(groupId)
          .collection('messages')
          .add({
            'senderId': currentUserId,
            'senderEmail': currentUserEmail,
            'message': message,
            'mediaUrl': mediaUrl,
            'fileName': fileName,
            'timestamp': timestamp,
            'messageType': type,
          });

      await _firestore.collection('groups').doc(groupId).set({
        'lastMessage': message,
        'lastMessageTime': timestamp,
      }, SetOptions(merge: true));
    } catch (e, st) {
      _logError('sendGroupMessage', e, st);
      rethrow;
    }
  }

  // Get users stream for the chat list
  Stream<List<Map<String, dynamic>>> getUsersStream() {
    return _firestore
        .collection('users')
        .snapshots()
        .handleError(
          (error, stack) => _logError('getUsersStream', error, stack),
        )
        .map((snapshot) {
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
        .snapshots()
        .handleError(
          (error, stack) => _logError('getStarredMessages', error, stack),
        );
  }

  // Perform chat backup (mock logic - updating timestamp)
  Future<void> performBackup() async {
    try {
      final String currentUserId = _auth.currentUser!.uid;
      await _firestore.collection('users').doc(currentUserId).update({
        'lastBackup': FieldValue.serverTimestamp(),
      });
    } catch (e, st) {
      _logError('performBackup', e, st);
      rethrow;
    }
  }

  // Search users by name or email
  Stream<List<Map<String, dynamic>>> searchUsers(String query) {
    return _firestore
        .collection('users')
        .where('email', isGreaterThanOrEqualTo: query)
        .where('email', isLessThanOrEqualTo: query + '\uf8ff')
        .snapshots()
        .handleError((error, stack) => _logError('searchUsers', error, stack))
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
        .snapshots()
        .handleError((error, stack) => _logError('getCallLogs', error, stack));
  }

  Stream<QuerySnapshot> getScheduledCalls() {
    final String currentUserId = _auth.currentUser!.uid;
    return _firestore
        .collection('call_schedules')
        .where('users', arrayContains: currentUserId)
        .orderBy('scheduledAt', descending: false)
        .snapshots()
        .handleError(
          (error, stack) => _logError('getScheduledCalls', error, stack),
        );
  }

  Future<void> scheduleCall(
    String receiverId,
    String receiverName,
    DateTime scheduledAt,
  ) async {
    try {
      final String currentUserId = _auth.currentUser!.uid;
      final String currentUserName = _auth.currentUser!.displayName ?? "User";

      await _firestore.collection('call_schedules').add({
        'users': [currentUserId, receiverId],
        'callerId': currentUserId,
        'receiverId': receiverId,
        'callerName': currentUserName,
        'receiverName': receiverName,
        'scheduledAt': Timestamp.fromDate(scheduledAt),
        'status': 'scheduled',
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e, st) {
      _logError('scheduleCall', e, st);
      rethrow;
    }
  }

  // Start/Log a call
  Future<void> logCall(
    String receiverId,
    String receiverName,
    String type,
  ) async {
    try {
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
    } catch (e, st) {
      _logError('logCall', e, st);
      rethrow;
    }
  }

  // Clear call log for current user
  Future<void> clearCallLog() async {
    try {
      final String currentUserId = _auth.currentUser!.uid;
      final snapshot =
          await _firestore
              .collection('calls')
              .where('users', arrayContains: currentUserId)
              .get();

      for (var doc in snapshot.docs) {
        await doc.reference.delete();
      }
    } catch (e, st) {
      _logError('clearCallLog', e, st);
      rethrow;
    }
  }

  // Join community logic
  Future<void> joinCommunity(String communityName) async {
    try {
      final String currentUserId = _auth.currentUser!.uid;
      final communityDoc = _firestore
          .collection('communities')
          .doc(communityName);

      await communityDoc.set({
        'name': communityName,
        'members': FieldValue.arrayUnion([currentUserId]),
      }, SetOptions(merge: true));
    } catch (e, st) {
      _logError('joinCommunity', e, st);
      rethrow;
    }
  }

  // Get status updates
  Stream<QuerySnapshot> getStatusUpdates() {
    return _firestore
        .collection('status')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .handleError(
          (error, stack) => _logError('getStatusUpdates', error, stack),
        );
  }

  // Post a status update (media or text)
  Future<void> postStatus(
    String? mediaUrl,
    String type, {
    String? statusText,
  }) async {
    try {
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
        'likes': [],
      });
    } catch (e, st) {
      _logError('postStatus', e, st);
      rethrow;
    }
  }

  Future<void> toggleStatusLike(String statusId) async {
    try {
      final String currentUserId = _auth.currentUser!.uid;
      final doc = _firestore.collection('status').doc(statusId);
      final snapshot = await doc.get();
      final data = snapshot.data() ?? {};
      final List likes = List.from(data['likes'] ?? []);
      if (likes.contains(currentUserId)) {
        await doc.update({
          'likes': FieldValue.arrayRemove([currentUserId]),
        });
      } else {
        await doc.update({
          'likes': FieldValue.arrayUnion([currentUserId]),
        });
      }
    } catch (e, st) {
      _logError('toggleStatusLike', e, st);
      rethrow;
    }
  }

  // Get communities stream
  Stream<QuerySnapshot> getCommunitiesStream() {
    return _firestore
        .collection('communities')
        .snapshots()
        .handleError(
          (error, stack) => _logError('getCommunitiesStream', error, stack),
        );
  }

  // Search communities
  Stream<QuerySnapshot> searchCommunities(String query) {
    return _firestore
        .collection('communities')
        .where('name', isGreaterThanOrEqualTo: query)
        .where('name', isLessThanOrEqualTo: query + '\uf8ff')
        .snapshots()
        .handleError(
          (error, stack) => _logError('searchCommunities', error, stack),
        );
  }
}
