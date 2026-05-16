import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import '../../core/services/call_signaling_service.dart';

class VideoCallScreen extends StatefulWidget {
  final String contactName;
  final String callId;
  final bool isCaller;
  final CallSignalingService signalingService;

  const VideoCallScreen({
    super.key,
    required this.contactName,
    required this.callId,
    required this.isCaller,
    required this.signalingService,
  });

  @override
  State<VideoCallScreen> createState() => _VideoCallScreenState();
}

class _VideoCallScreenState extends State<VideoCallScreen> {
  final RTCVideoRenderer _localRenderer = RTCVideoRenderer();
  final RTCVideoRenderer _remoteRenderer = RTCVideoRenderer();

  bool _isMuted = false;
  bool _isCameraOff = false;
  bool _isConnected = false;
  bool _isFrontCamera = true;
  int _seconds = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _initRenderers();
  }

  Future<void> _initRenderers() async {
    await _localRenderer.initialize();
    await _remoteRenderer.initialize();
    await _startCall();
  }

  Future<void> _startCall() async {
    final localStream = await widget.signalingService.getLocalStream(video: true);
    if (mounted) {
      setState(() => _localRenderer.srcObject = localStream);
    }

    if (!widget.isCaller) {
      await widget.signalingService.answerCall(
        callId: widget.callId,
        onRemoteStream: _onRemoteStream,
        onCallEnded: _onCallEnded,
      );
    }
  }

  void _onRemoteStream(dynamic stream) {
    if (!mounted) return;
    setState(() {
      _remoteRenderer.srcObject = stream;
      _isConnected = true;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _seconds++);
    });
  }

  void _onCallEnded() {
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  Future<void> _endCall() async {
    await widget.signalingService.endCall();
    if (mounted) Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _localRenderer.dispose();
    _remoteRenderer.dispose();
    super.dispose();
  }

  String _formatDuration(int s) {
    final m = s ~/ 60;
    final sec = s % 60;
    return '${m.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Remote video (full screen)
          Positioned.fill(
            child: _isConnected
                ? RTCVideoView(_remoteRenderer, objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover)
                : Container(
                    color: Colors.black87,
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircleAvatar(
                            radius: 50,
                            backgroundColor: Colors.white24,
                            child: Text(
                              widget.contactName.isNotEmpty ? widget.contactName[0].toUpperCase() : '?',
                              style: const TextStyle(fontSize: 40, color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            widget.contactName,
                            style: const TextStyle(fontSize: 22, color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          const Text('Connecting...', style: TextStyle(color: Colors.white54)),
                        ],
                      ),
                    ),
                  ),
          ),

          // Local video (picture-in-picture)
          Positioned(
            top: 60,
            right: 16,
            width: 100,
            height: 140,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: _isCameraOff
                  ? Container(color: Colors.grey.shade800, child: const Icon(Icons.videocam_off, color: Colors.white))
                  : RTCVideoView(_localRenderer, mirror: _isFrontCamera, objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover),
            ),
          ),

          // Duration label
          if (_isConnected)
            Positioned(
              top: 50,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black45,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _formatDuration(_seconds),
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                  ),
                ),
              ),
            ),

          // Controls bar
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [Colors.black87, Colors.transparent],
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _controlButton(
                    icon: _isMuted ? Icons.mic_off : Icons.mic,
                    label: _isMuted ? 'Unmute' : 'Mute',
                    onTap: () {
                      setState(() => _isMuted = !_isMuted);
                      widget.signalingService.toggleMute(_isMuted);
                    },
                  ),
                  _controlButton(
                    icon: _isCameraOff ? Icons.videocam_off : Icons.videocam,
                    label: _isCameraOff ? 'Show' : 'Hide',
                    onTap: () {
                      setState(() => _isCameraOff = !_isCameraOff);
                      widget.signalingService.toggleCamera(!_isCameraOff);
                    },
                  ),
                  GestureDetector(
                    onTap: _endCall,
                    child: Container(
                      width: 64,
                      height: 64,
                      decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                      child: const Icon(Icons.call_end, color: Colors.white, size: 30),
                    ),
                  ),
                  _controlButton(
                    icon: Icons.flip_camera_ios,
                    label: 'Flip',
                    onTap: () async {
                      setState(() => _isFrontCamera = !_isFrontCamera);
                      await widget.signalingService.switchCamera();
                    },
                  ),
                  _controlButton(
                    icon: Icons.chat_bubble_outline,
                    label: 'Chat',
                    onTap: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _controlButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: 22),
          ),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11)),
        ],
      ),
    );
  }
}
