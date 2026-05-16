import 'package:flutter/material.dart';
import '../../core/app_colors.dart';
import '../../core/services/call_signaling_service.dart';
import 'audio_call_screen.dart';
import 'video_call_screen.dart';

class IncomingCallScreen extends StatelessWidget {
  final String callId;
  final String callerName;
  final String callType; // 'audio' or 'video'
  final CallSignalingService signalingService;

  const IncomingCallScreen({
    super.key,
    required this.callId,
    required this.callerName,
    required this.callType,
    required this.signalingService,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 80),
              Text(
                callType == 'video' ? 'Incoming Video Call' : 'Incoming Audio Call',
                style: const TextStyle(fontSize: 16, color: Colors.white70),
              ),
              const SizedBox(height: 32),
              CircleAvatar(
                radius: 64,
                backgroundColor: Colors.white.withValues(alpha: 0.3),
                child: Text(
                  callerName.isNotEmpty ? callerName[0].toUpperCase() : '?',
                  style: const TextStyle(fontSize: 52, color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                callerName,
                style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Reject
                  _callActionButton(
                    icon: Icons.call_end,
                    color: Colors.red,
                    label: 'Decline',
                    onTap: () async {
                      await signalingService.rejectCall(callId);
                      if (context.mounted) Navigator.of(context).pop();
                    },
                  ),
                  // Accept
                  _callActionButton(
                    icon: callType == 'video' ? Icons.videocam : Icons.call,
                    color: Colors.green,
                    label: 'Accept',
                    onTap: () async {
                      await signalingService.getLocalStream(video: callType == 'video');
                      if (!context.mounted) return;

                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                          builder: (_) => callType == 'video'
                              ? VideoCallScreen(
                                  contactName: callerName,
                                  callId: callId,
                                  isCaller: false,
                                  signalingService: signalingService,
                                )
                              : AudioCallScreen(
                                  contactName: callerName,
                                  callId: callId,
                                  isCaller: false,
                                  signalingService: signalingService,
                                ),
                        ),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 60),
            ],
          ),
        ),
      ),
    );
  }

  Widget _callActionButton({
    required IconData icon,
    required Color color,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            child: Icon(icon, color: Colors.white, size: 32),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 14)),
        ],
      ),
    );
  }
}
