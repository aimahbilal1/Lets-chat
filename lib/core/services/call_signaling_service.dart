import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:uuid/uuid.dart';

typedef OnRemoteStream = void Function(MediaStream stream);
typedef OnCallEnded = void Function();

class CallSignalingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  RTCPeerConnection? _peerConnection;
  MediaStream? _localStream;
  String? _currentCallId;

  static const Map<String, dynamic> _iceServers = {
    'iceServers': [
      {'urls': 'stun:stun.l.google.com:19302'},
      {'urls': 'stun:stun1.l.google.com:19302'},
    ],
  };

  Future<MediaStream> getLocalStream({bool video = true}) async {
    _localStream = await navigator.mediaDevices.getUserMedia({
      'audio': true,
      'video': video ? {'facingMode': 'user'} : false,
    });
    return _localStream!;
  }

  Future<RTCPeerConnection> _createPeerConnection() async {
    final pc = await createPeerConnection(_iceServers);
    if (_localStream != null) {
      for (final track in _localStream!.getTracks()) {
        await pc.addTrack(track, _localStream!);
      }
    }
    return pc;
  }

  /// Caller side: creates offer and writes to Firestore. Returns callId.
  Future<String> initiateCall({
    required String receiverId,
    required String callerName,
    required String receiverName,
    required String type,
    required OnRemoteStream onRemoteStream,
    required OnCallEnded onCallEnded,
  }) async {
    final callId = const Uuid().v4();
    _currentCallId = callId;
    final callerId = _auth.currentUser!.uid;
    final callDoc = _firestore.collection('calls').doc(callId);

    _peerConnection = await _createPeerConnection();
    _peerConnection!.onTrack = (event) {
      if (event.streams.isNotEmpty) onRemoteStream(event.streams[0]);
    };

    final offer = await _peerConnection!.createOffer();
    await _peerConnection!.setLocalDescription(offer);

    await callDoc.set({
      'callerId': callerId,
      'receiverId': receiverId,
      'callerName': callerName,
      'receiverName': receiverName,
      'type': type,
      'status': 'ringing',
      'offer': {'sdp': offer.sdp, 'type': offer.type},
      'createdAt': FieldValue.serverTimestamp(),
    });

    _peerConnection!.onIceCandidate = (candidate) {
      if (candidate.candidate != null) {
        callDoc.collection('callerCandidates').add(candidate.toMap());
      }
    };

    callDoc.snapshots().listen((snapshot) async {
      if (!snapshot.exists) return;
      final data = snapshot.data()!;
      final status = data['status'] as String?;

      if (status == 'ended' || status == 'rejected') {
        onCallEnded();
        return;
      }

      final answerData = data['answer'];
      if (answerData != null) {
        final sigState = _peerConnection?.signalingState;
        if (sigState != null && sigState != RTCSignalingState.RTCSignalingStateStable) {
          await _peerConnection!.setRemoteDescription(
            RTCSessionDescription(answerData['sdp'], answerData['type']),
          );
        }
      }
    });

    callDoc.collection('receiverCandidates').snapshots().listen((snapshot) {
      for (final change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.added) {
          final d = change.doc.data()!;
          _peerConnection?.addCandidate(RTCIceCandidate(
            d['candidate'],
            d['sdpMid'],
            d['sdpMLineIndex'],
          ));
        }
      }
    });

    return callId;
  }

  /// Receiver side: creates answer and writes to Firestore.
  Future<void> answerCall({
    required String callId,
    required OnRemoteStream onRemoteStream,
    required OnCallEnded onCallEnded,
  }) async {
    _currentCallId = callId;
    final callDoc = _firestore.collection('calls').doc(callId);
    final callData = (await callDoc.get()).data()!;

    _peerConnection = await _createPeerConnection();
    _peerConnection!.onTrack = (event) {
      if (event.streams.isNotEmpty) onRemoteStream(event.streams[0]);
    };
    _peerConnection!.onIceCandidate = (candidate) {
      if (candidate.candidate != null) {
        callDoc.collection('receiverCandidates').add(candidate.toMap());
      }
    };

    final offerData = callData['offer'];
    await _peerConnection!.setRemoteDescription(
      RTCSessionDescription(offerData['sdp'], offerData['type']),
    );

    final answer = await _peerConnection!.createAnswer();
    await _peerConnection!.setLocalDescription(answer);

    await callDoc.update({
      'answer': {'sdp': answer.sdp, 'type': answer.type},
      'status': 'accepted',
    });

    callDoc.collection('callerCandidates').snapshots().listen((snapshot) {
      for (final change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.added) {
          final d = change.doc.data()!;
          _peerConnection?.addCandidate(RTCIceCandidate(
            d['candidate'],
            d['sdpMid'],
            d['sdpMLineIndex'],
          ));
        }
      }
    });

    callDoc.snapshots().listen((snapshot) {
      if (!snapshot.exists) return;
      final status = (snapshot.data() ?? {})['status'];
      if (status == 'ended') onCallEnded();
    });
  }

  Future<void> endCall() async {
    if (_currentCallId != null) {
      try {
        await _firestore.collection('calls').doc(_currentCallId).update({'status': 'ended'});
      } catch (_) {}
    }
    _cleanup();
  }

  Future<void> rejectCall(String callId) async {
    try {
      await _firestore.collection('calls').doc(callId).update({'status': 'rejected'});
    } catch (_) {}
  }

  void _cleanup() {
    _localStream?.getTracks().forEach((t) => t.stop());
    _localStream?.dispose();
    _peerConnection?.close();
    _localStream = null;
    _peerConnection = null;
    _currentCallId = null;
  }

  void toggleMute(bool muted) {
    for (final track in _localStream?.getAudioTracks() ?? []) {
      track.enabled = !muted;
    }
  }

  void toggleCamera(bool enabled) {
    for (final track in _localStream?.getVideoTracks() ?? []) {
      track.enabled = enabled;
    }
  }

  Future<void> switchCamera() async {
    final tracks = _localStream?.getVideoTracks() ?? [];
    if (tracks.isNotEmpty) {
      await Helper.switchCamera(tracks.first);
    }
  }

  void setSpeakerphoneOn(bool enabled) {
    Helper.setSpeakerphoneOn(enabled);
  }

  /// Stream of incoming call documents for the current user.
  Stream<QuerySnapshot> incomingCallsStream() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return const Stream.empty();
    return _firestore
        .collection('calls')
        .where('receiverId', isEqualTo: uid)
        .where('status', isEqualTo: 'ringing')
        .snapshots();
  }
}
