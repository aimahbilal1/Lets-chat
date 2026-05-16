import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import '../../models/message_model.dart';

class ChatService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  void _logError(String context, Object error, [StackTrace? stackTrace]) {
    debugPrint('[ChatService] $context error: $error');
    if (stackTrace != null) debugPrint('[ChatService] $context stack: $stackTrace');
  }

  // ─── CHAT ROOMS STREAM (sorted by last message time) ───────────────────────
  Stream<List<Map<String, dynamic>>> getChatRoomsStream() {
    final String currentUserId = _auth.currentUser!.uid;
    return _firestore
        .collection('chat_rooms')
        .where('users', arrayContains: currentUserId)
        .orderBy('lastMessageTime', descending: true)
        .snapshots()
        .handleError((e, s) => _logError('getChatRoomsStream', e, s))
        .asyncMap((snapshot) async {
      final List<Map<String, dynamic>> rooms = [];
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final List users = data['users'] ?? [];
        final String otherUid = users.firstWhere((u) => u != currentUserId, orElse: () => '');
        if (otherUid.isEmpty) continue;
        try {
          final userDoc = await _firestore.collection('users').doc(otherUid).get();
          final userData = userDoc.data() ?? {};
          rooms.add({
            'chatRoomId': doc.id,
            'lastMessage': data['lastMessage'] ?? '',
            'lastMessageTime': data['lastMessageTime'],
            'lastMessageSenderId': data['lastMessageSenderId'] ?? '',
            'uid': otherUid,
            'name': userData['name'] ?? (userData['email'] ?? 'User').toString().split('@')[0],
            'email': userData['email'] ?? '',
            'photoUrl': userData['photoUrl'],
            'isOnline': userData['isOnline'] ?? false,
            'profilePhotoPrivacy': userData['settings']?['Privacy']?['Profile photo'] ?? 'Everyone',
          });
        } catch (_) {}
      }
      return rooms;
    });
  }

  // ─── SEND MESSAGE ───────────────────────────────────────────────────────────
  Future<void> sendMessage(
    String receiverId,
    String message, {
    String type = 'text',
    String? mediaUrl,
    String? fileName,
    String? replyToId,
    String? replyToText,
    String? replyToSender,
  }) async {
    try {
      final String currentUserId = _auth.currentUser!.uid;
      final String currentUserEmail = _auth.currentUser!.email.toString();
      
      // Check for block status before sending
      final receiverDoc = await _firestore.collection('users').doc(receiverId).get();
      final receiverData = receiverDoc.data() ?? {};
      final List blockedByReceiver = receiverData['blockedUsers'] ?? [];
      if (blockedByReceiver.contains(currentUserId)) {
         throw Exception("Message failed to send. You are blocked.");
      }

      final currentUserDoc = await _firestore.collection('users').doc(currentUserId).get();
      final currentUserData = currentUserDoc.data() ?? {};
      final List blockedByMe = currentUserData['blockedUsers'] ?? [];
      if (blockedByMe.contains(receiverId)) {
         throw Exception("You blocked this user. Unblock to send messages.");
      }

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
        replyToId: replyToId,
        replyToText: replyToText,
        replyToSender: replyToSender,
      );

      List<String> ids = [currentUserId, receiverId];
      ids.sort();
      String chatRoomId = ids.join("_");

      await _firestore
          .collection('chat_rooms')
          .doc(chatRoomId)
          .collection('messages')
          .add(newMessage.toMap());

      await _firestore.collection('chat_rooms').doc(chatRoomId).set({
        'lastMessage': type == 'text' ? message : '📎 $type',
        'lastMessageTime': timestamp,
        'lastMessageSenderId': currentUserId,
        'users': ids,
      }, SetOptions(merge: true));
    } catch (e, st) {
      _logError('sendMessage', e, st);
      rethrow;
    }
  }

  // ─── DELETE MESSAGE ─────────────────────────────────────────────────────────
  Future<void> deleteMessage(String chatRoomId, String messageId, {bool forEveryone = false}) async {
    try {
      final ref = _firestore
          .collection('chat_rooms')
          .doc(chatRoomId)
          .collection('messages')
          .doc(messageId);
      if (forEveryone) {
        final doc = await ref.get();
        final data = doc.data();
        final String? mediaUrl = data?['mediaUrl'];

        await ref.update({'message': 'This message was deleted', 'messageType': 'deleted', 'mediaUrl': null});

        if (mediaUrl != null && mediaUrl.isNotEmpty) {
          try {
            await FirebaseStorage.instance.refFromURL(mediaUrl).delete();
          } catch (e) {
            debugPrint("Storage delete error: $e");
          }
        }
      } else {
        await ref.update({'deletedFor': FieldValue.arrayUnion([_auth.currentUser!.uid])});
      }
    } catch (e, st) {
      _logError('deleteMessage', e, st);
      rethrow;
    }
  }

  Future<void> deleteGroupMessage(String groupId, String messageId) async {
    try {
      final ref = _firestore
          .collection('groups')
          .doc(groupId)
          .collection('messages')
          .doc(messageId);
      
      final doc = await ref.get();
      final data = doc.data();
      final String? mediaUrl = data?['mediaUrl'];

      await ref.update({'message': 'This message was deleted', 'messageType': 'deleted', 'mediaUrl': null});

      if (mediaUrl != null && mediaUrl.isNotEmpty) {
        try {
          await FirebaseStorage.instance.refFromURL(mediaUrl).delete();
        } catch (e) {
          debugPrint("Storage delete error: $e");
        }
      }
    } catch (e, st) {
      _logError('deleteGroupMessage', e, st);
      rethrow;
    }
  }

  // ─── MARK MESSAGES AS READ ──────────────────────────────────────────────────
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
    }
  }

  Future<void> markAllMessagesAsRead(String chatRoomId) async {
    try {
      final currentUserId = _auth.currentUser!.uid;
      final snapshot = await _firestore
          .collection('chat_rooms')
          .doc(chatRoomId)
          .collection('messages')
          .where('isRead', isEqualTo: false)
          .where('senderId', isNotEqualTo: currentUserId)
          .get();
      final batch = _firestore.batch();
      for (final doc in snapshot.docs) {
        batch.update(doc.reference, {'isRead': true});
      }
      await batch.commit();
    } catch (e, st) {
      _logError('markAllMessagesAsRead', e, st);
    }
  }

  // ─── UNREAD COUNT ───────────────────────────────────────────────────────────
  Stream<int> getUnreadCount(String chatRoomId) {
    final currentUserId = _auth.currentUser!.uid;
    return _firestore
        .collection('chat_rooms')
        .doc(chatRoomId)
        .collection('messages')
        .where('isRead', isEqualTo: false)
        .where('senderId', isNotEqualTo: currentUserId)
        .snapshots()
        .map((s) => s.docs.length)
        .handleError((e, st) => _logError('getUnreadCount', e, st));
  }

  // ─── TOGGLE STAR MESSAGE ────────────────────────────────────────────────────
  Future<void> toggleStarMessage(String chatRoomId, String messageId, bool isStarred) async {
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

  // ─── ADD REACTION ───────────────────────────────────────────────────────────
  Future<void> addReaction(String chatRoomId, String messageId, String emoji) async {
    try {
      final currentUserId = _auth.currentUser!.uid;
      final ref = _firestore
          .collection('chat_rooms')
          .doc(chatRoomId)
          .collection('messages')
          .doc(messageId);

      final doc = await ref.get();
      final data = doc.data() ?? {};
      final Map<String, dynamic> reactions = Map<String, dynamic>.from(data['reactions'] ?? {});

      // Find any emoji this user already reacted with
      String? previousEmoji;
      for (final entry in reactions.entries) {
        final users = List<String>.from(entry.value as List);
        if (users.contains(currentUserId)) {
          previousEmoji = entry.key;
          break;
        }
      }

      final Map<String, dynamic> updates = {};

      if (previousEmoji != null && previousEmoji != emoji) {
        updates['reactions.$previousEmoji'] = FieldValue.arrayRemove([currentUserId]);
      }

      if (previousEmoji == emoji) {
        updates['reactions.$emoji'] = FieldValue.arrayRemove([currentUserId]);
      } else {
        updates['reactions.$emoji'] = FieldValue.arrayUnion([currentUserId]);
      }

      await ref.update(updates);
    } catch (e, st) {
      _logError('addReaction', e, st);
    }
  }

  // ─── TOGGLE FAVOURITE ───────────────────────────────────────────────────────
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

  // ─── BLOCK / MUTE ───────────────────────────────────────────────────────────
  Future<void> blockUser(String userId) async {
    try {
      final currentUserId = _auth.currentUser!.uid;
      await _firestore.collection('users').doc(currentUserId).update({
        'blockedUsers': FieldValue.arrayUnion([userId])
      });
    } catch (e, st) {
      _logError('blockUser', e, st);
    }
  }

  Future<void> unblockUser(String userId) async {
    try {
      final currentUserId = _auth.currentUser!.uid;
      await _firestore.collection('users').doc(currentUserId).update({
        'blockedUsers': FieldValue.arrayRemove([userId])
      });
    } catch (e, st) {
      _logError('unblockUser', e, st);
    }
  }

  Future<void> muteUser(String userId) async {
    try {
      final currentUserId = _auth.currentUser!.uid;
      await _firestore.collection('users').doc(currentUserId).update({
        'mutedUsers': FieldValue.arrayUnion([userId])
      });
    } catch (e, st) {
      _logError('muteUser', e, st);
    }
  }

  Future<void> unmuteUser(String userId) async {
    try {
      final currentUserId = _auth.currentUser!.uid;
      await _firestore.collection('users').doc(currentUserId).update({
        'mutedUsers': FieldValue.arrayRemove([userId])
      });
    } catch (e, st) {
      _logError('unmuteUser', e, st);
    }
  }

  // ─── GET MESSAGES ───────────────────────────────────────────────────────────
  Stream<QuerySnapshot> getMessages(String userId, String otherUserId, {int limit = 40}) {
    List<String> ids = [userId, otherUserId];
    ids.sort();
    String chatRoomId = ids.join("_");
    return _firestore
        .collection('chat_rooms')
        .doc(chatRoomId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .snapshots()
        .handleError((error, stack) => _logError('getMessages', error, stack));
  }

  String getChatRoomId(String uid1, String uid2) {
    List<String> ids = [uid1, uid2];
    ids.sort();
    return ids.join('_');
  }

  // ─── GROUPS ─────────────────────────────────────────────────────────────────
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
        .handleError((error, stack) => _logError('getGroupsStream', error, stack));
  }

  Stream<QuerySnapshot> getGroupMessages(String groupId) {
    return _firestore
        .collection('groups')
        .doc(groupId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots()
        .handleError((error, stack) => _logError('getGroupMessages', error, stack));
  }

  Stream<List<Map<String, dynamic>>> getGroupsInCommon(String otherUserId) {
    final String currentUserId = _auth.currentUser!.uid;
    return _firestore
        .collection('groups')
        .where('members', arrayContains: currentUserId)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => {...doc.data() as Map<String, dynamic>, 'id': doc.id})
              .where((group) {
                final List members = group['members'] ?? [];
                return members.contains(otherUserId);
              })
              .toList();
        })
        .handleError((e, s) => _logError('getGroupsInCommon', e, s));
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

      await _firestore.collection('groups').doc(groupId).collection('messages').add({
        'senderId': currentUserId,
        'senderEmail': currentUserEmail,
        'message': message,
        'mediaUrl': mediaUrl,
        'fileName': fileName,
        'timestamp': timestamp,
        'messageType': type,
      });

      await _firestore.collection('groups').doc(groupId).set({
        'lastMessage': type == 'text' ? message : '📎 $type',
        'lastMessageTime': timestamp,
      }, SetOptions(merge: true));
    } catch (e, st) {
      _logError('sendGroupMessage', e, st);
      rethrow;
    }
  }

  // ─── USERS ──────────────────────────────────────────────────────────────────
  Stream<List<Map<String, dynamic>>> getUsersStream() {
    return _firestore
        .collection('users')
        .snapshots()
        .handleError((error, stack) => _logError('getUsersStream', error, stack))
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }

  Stream<List<Map<String, dynamic>>> searchUsers(String query) {
    final q = query.toLowerCase();
    return _firestore
        .collection('users')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => doc.data())
            .where((user) {
              final name = (user['name'] ?? '').toString().toLowerCase();
              final email = (user['email'] ?? '').toString().toLowerCase();
              return name.contains(q) || email.contains(q);
            })
            .toList())
        .handleError((e, s) => _logError('searchUsers', e, s));
  }

  Stream<List<Map<String, dynamic>>> getFavouriteUsersStream(List<String> favouriteIds) {
    if (favouriteIds.isEmpty) {
      return Stream.value([]);
    }
    return _firestore
        .collection('users')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => doc.data())
            .where((user) => favouriteIds.contains(user['uid']))
            .toList())
        .handleError((e, s) => _logError('getFavouriteUsersStream', e, s));
  }

  // ─── STARRED MESSAGES ───────────────────────────────────────────────────────
  Stream<QuerySnapshot> getStarredMessages() {
    return _firestore
        .collectionGroup('messages')
        .where('isStarred', isEqualTo: true)
        .snapshots()
        .handleError((error, stack) => _logError('getStarredMessages', error, stack));
  }

  // ─── BACKUP ─────────────────────────────────────────────────────────────────
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

  // ─── CALLS ──────────────────────────────────────────────────────────────────
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
        .handleError((error, stack) => _logError('getScheduledCalls', error, stack));
  }

  Future<void> scheduleCall(String receiverId, String receiverName, DateTime scheduledAt) async {
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

  Future<void> logCall(String receiverId, String receiverName, String type) async {
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

  Future<void> clearCallLog() async {
    try {
      final String currentUserId = _auth.currentUser!.uid;
      final snapshot = await _firestore
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

  // ─── COMMUNITY ──────────────────────────────────────────────────────────────
  Future<void> joinCommunity(String communityName) async {
    try {
      final String currentUserId = _auth.currentUser!.uid;
      await _firestore.collection('communities').doc(communityName).set({
        'name': communityName,
        'members': FieldValue.arrayUnion([currentUserId]),
      }, SetOptions(merge: true));
    } catch (e, st) {
      _logError('joinCommunity', e, st);
      rethrow;
    }
  }

  Stream<QuerySnapshot> getCommunitiesStream() {
    return _firestore
        .collection('communities')
        .snapshots()
        .handleError((error, stack) => _logError('getCommunitiesStream', error, stack));
  }

  Stream<QuerySnapshot> searchCommunities(String query) {
    return _firestore
        .collection('communities')
        .where('name', isGreaterThanOrEqualTo: query)
        .where('name', isLessThanOrEqualTo: query + '\uf8ff')
        .snapshots()
        .handleError((error, stack) => _logError('searchCommunities', error, stack));
  }

  Stream<QuerySnapshot> getCommunityMessages(String communityId) {
    return _firestore
        .collection('communities')
        .doc(communityId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots()
        .handleError((e, s) => _logError('getCommunityMessages', e, s));
  }

  Future<void> sendCommunityMessage(String communityId, String message, {String type = 'text', String? mediaUrl}) async {
    try {
      final currentUserId = _auth.currentUser!.uid;
      final currentUserEmail = _auth.currentUser!.email ?? 'user';
      final timestamp = Timestamp.now();
      await _firestore.collection('communities').doc(communityId).collection('messages').add({
        'senderId': currentUserId,
        'senderEmail': currentUserEmail,
        'message': message,
        'mediaUrl': mediaUrl,
        'timestamp': timestamp,
        'messageType': type,
      });
      await _firestore.collection('communities').doc(communityId).set({
        'lastMessage': message,
        'lastMessageTime': timestamp,
      }, SetOptions(merge: true));
    } catch (e, st) {
      _logError('sendCommunityMessage', e, st);
      rethrow;
    }
  }

  // ─── STATUS ─────────────────────────────────────────────────────────────────
  Stream<QuerySnapshot> getStatusUpdates() {
    final cutoff = Timestamp.fromDate(DateTime.now().subtract(const Duration(hours: 24)));
    return _firestore
        .collection('status')
        .where('timestamp', isGreaterThan: cutoff)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .handleError((error, stack) => _logError('getStatusUpdates', error, stack));
  }

  Future<void> postStatus(String? mediaUrl, String type, {String? statusText}) async {
    try {
      final String currentUserId = _auth.currentUser!.uid;
      final userDoc = await _firestore.collection('users').doc(currentUserId).get();
      final userData = userDoc.data() ?? {};
      final String currentUserName = userData['name'] ?? _auth.currentUser!.displayName ?? "User";
      final String? photoUrl = userData['photoUrl'];

      await _firestore.collection('status').add({
        'uid': currentUserId,
        'userName': currentUserName,
        'profilePic': photoUrl,
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

  Future<void> addStatusViewer(String statusId) async {
    try {
      final currentUserId = _auth.currentUser!.uid;
      await _firestore.collection('status').doc(statusId).update({
        'viewers': FieldValue.arrayUnion([currentUserId]),
      });
    } catch (e, st) {
      _logError('addStatusViewer', e, st);
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
        await doc.update({'likes': FieldValue.arrayRemove([currentUserId])});
      } else {
        await doc.update({'likes': FieldValue.arrayUnion([currentUserId])});
      }
    } catch (e, st) {
      _logError('toggleStatusLike', e, st);
      rethrow;
    }
  }
}
