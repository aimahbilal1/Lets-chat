import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/app_colors.dart';
import '../../core/services/call_signaling_service.dart';

class AudioCallScreen extends StatefulWidget {
  final String contactName;
  final String callId;
  final bool isCaller;
  final CallSignalingService signalingService;

  const AudioCallScreen({
    super.key,
    required this.contactName,
    required this.callId,
    required this.isCaller,
    required this.signalingService,
  });

  @override
  State<AudioCallScreen> createState() => _AudioCallScreenState();
}

class _AudioCallScreenState extends State<AudioCallScreen> {
  bool _isMuted = false;
  bool _isSpeakerOn = false;
  bool _isConnected = false;
  int _seconds = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startCall();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _startCall() async {
    await widget.signalingService.getLocalStream(video: false);

    if (widget.isCaller) {
      // Call was already initiated before navigating here; just wait for connection
      setState(() => _isConnected = false);
    } else {
      await widget.signalingService.answerCall(
        callId: widget.callId,
        onRemoteStream: (_) => _onConnected(),
        onCallEnded: _onCallEnded,
      );
    }
  }

  void _onConnected() {
    if (!mounted) return;
    setState(() => _isConnected = true);
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

  String _formatDuration(int s) {
    final m = s ~/ 60;
    final sec = s % 60;
    return '${m.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 60),
              CircleAvatar(
                radius: 60,
                backgroundColor: Colors.white.withValues(alpha: 0.3),
                child: Text(
                  widget.contactName.isNotEmpty ? widget.contactName[0].toUpperCase() : '?',
                  style: const TextStyle(fontSize: 48, color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                widget.contactName,
                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 8),
              Text(
                _isConnected ? _formatDuration(_seconds) : 'Connecting...',
                style: const TextStyle(fontSize: 16, color: Colors.white70),
              ),
              const Spacer(),
              _buildControls(),
              const SizedBox(height: 60),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildControls() {
    return Row(
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
        GestureDetector(
          onTap: _endCall,
          child: Container(
            width: 72,
            height: 72,
            decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
            child: const Icon(Icons.call_end, color: Colors.white, size: 32),
          ),
        ),
        _controlButton(
          icon: _isSpeakerOn ? Icons.volume_up : Icons.volume_down,
          label: 'Speaker',
          onTap: () {
            setState(() => _isSpeakerOn = !_isSpeakerOn);
            widget.signalingService.setSpeakerphoneOn(_isSpeakerOn);
          },
        ),
      ],
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
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: 26),
          ),
          const SizedBox(height: 6),
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
        ],
      ),
    );
  }
}
