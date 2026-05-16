# Lets-chat

Lets-chat is a Flutter-based chat application with real-time audio and video calling powered by WebRTC and Firebase Firestore for signaling. The project includes UI for messaging, call screens (audio & video), and a simple WebRTC signaling service that uses Firestore documents + subcollections to exchange SDP and ICE candidates.

This README documents how to set up, run, and understand the call flow and Firestore schema used by the app.

## Features

- 1-to-1 real-time audio and video calling using `flutter_webrtc`.
- Firestore-based signaling (offer/answer + ICE candidates) in `calls` collection.
- Call UI for caller/receiver, mute/camera toggle, switch camera, speaker control.
- Firebase authentication + Firestore-backed chat and call metadata.

## Repository layout (important files)

- `lib/core/services/call_signaling_service.dart` — WebRTC + Firestore signaling implementation (getUserMedia, RTCPeerConnection, offer/answer, ICE candidate exchange, call lifecycle helpers).
- `lib/screens/calls/video_call_screen.dart` — video call UI and renderers (local/remote).
- `lib/screens/calls/audio_call_screen.dart` — audio-call UI.
- `lib/screens/calls/incoming_call_screen.dart` — UI for incoming call handling.
- `lib/firebase_options.dart` — generated Firebase options (platform-specific config helper).
- `pubspec.yaml` — dependencies (notably `flutter_webrtc`, `firebase_*`, `audioplayers`, `record`).

## Prerequisites

- Flutter (project SDK constraint: >=3.7.0 <4.0.0). Use the Flutter tool matching your environment.
- A Firebase project with Firestore and optional Cloud Authentication set up.
- Platform tooling (Android SDK / Xcode) for device/emulator testing.

## Setup

1. Clone the repo and open it in your editor.

2. Install Flutter dependencies:

```bash
flutter pub get
```

3. Firebase configuration

- Add your Firebase configuration files:
	- Android: place `google-services.json` in `android/app/` (there is already an example at `android/app/google-services.json` — replace with your own).
	- iOS/macOS: add `GoogleService-Info.plist` to the Xcode project / macOS Runner as appropriate.
- The project contains `lib/firebase_options.dart` — if you generated Firebase options using `flutterfire` CLI, verify they match your Firebase project.

4. Platform permissions

- Make sure the following permissions are present in platform manifests:
	- Android `AndroidManifest.xml`: CAMERA, RECORD_AUDIO, INTERNET
	- iOS `Info.plist`: NSCameraUsageDescription, NSMicrophoneUsageDescription

## Run

Run the app on a device or emulator from your project root:

```bash
flutter run
```

For a full clean & install (useful when changing native plugins):

```bash
flutter clean
flutter pub get
flutter run
```

## Call Flow (detailed)

The app implements a simple peer-to-peer WebRTC flow with Firestore as the signaling channel. Below is the step-by-step flow and the files that implement each step.

1. UI triggers a call (caller) — create `VideoCallScreen` or `AudioCallScreen` and pass a `CallSignalingService` instance. (See `lib/screens/chats/message_screen.dart` / `lib/main.dart` for examples.)

2. Acquire local media
	 - Function: `CallSignalingService.getLocalStream({video: true/false})`
	 - Uses: `navigator.mediaDevices.getUserMedia(...)` provided by `flutter_webrtc`.

3. Create RTCPeerConnection and add local tracks
	 - Function: `CallSignalingService._createPeerConnection()` — calls `createPeerConnection(_iceServers)` and adds tracks from `_localStream`.

4. Caller creates an SDP offer and writes call document to Firestore
	 - Function: `CallSignalingService.initiateCall(...)`
	 - Writes to: `calls/{callId}` with fields `callerId`, `receiverId`, `offer`, `type`, `status: 'ringing'`, `createdAt`.

5. Caller streams local ICE candidates into `calls/{callId}/callerCandidates`.

6. Receiver listens for incoming call docs using `CallSignalingService.incomingCallsStream()` and shows incoming UI.

7. Receiver answers: reads `offer`, sets remote description, creates `answer`, sets local description, and writes `answer` into the call document and updates `status: 'accepted'`.

8. Receiver streams its ICE candidates into `calls/{callId}/receiverCandidates`.

9. Both peers listen to the other party's candidate subcollection and add candidates to the RTCPeerConnection.

10. Remote media arrives via `RTCPeerConnection.onTrack` and UI attaches the stream to `RTCVideoRenderer` (see `lib/screens/calls/video_call_screen.dart`).

11. Controls such as mute, camera toggle, camera switch, and speaker toggle are implemented by helper methods on `CallSignalingService` (e.g., `toggleMute`, `toggleCamera`, `switchCamera`, `setSpeakerphoneOn`).

12. Ending or rejecting a call updates the Firestore document status to `'ended'` or `'rejected'` and the service cleans up tracks and closes the peer connection.

## Firestore signaling schema

- Call document: `calls/{callId}`
	- `callerId` (string)
	- `receiverId` (string)
	- `callerName` (string)
	- `receiverName` (string)
	- `type` ('audio' | 'video')
	- `status` ('ringing' | 'accepted' | 'ended' | 'rejected')
	- `offer`: { `sdp`: string, `type`: string }
	- `answer`: { `sdp`: string, `type`: string } (added when answered)
	- `createdAt`: server timestamp

- Subcollections:
	- `calls/{callId}/callerCandidates` — documents created by caller for each ICE candidate
	- `calls/{callId}/receiverCandidates` — documents created by receiver for each ICE candidate

When writing security rules for Firestore, ensure only authorized users can create or update call documents for the expected participants.

## Important notes & recommendations

- TURN server: the project currently uses public STUN servers (`stun.l.google.com:19302`). For reliable connectivity across restrictive NATs/firewalls, configure a TURN server and add it to the `_iceServers` map in `lib/core/services/call_signaling_service.dart`.
- Background / push notifications: Firestore-based signaling requires the app to be running. To support incoming calls when the app is backgrounded or terminated, integrate server-side signaling or use FCM push notifications to wake the app / show incoming call UI.
- Cleanup: stale call documents may remain in Firestore if clients crash. Consider adding a TTL/cleanup mechanism or Cloud Function to remove old calls.
- Permissions: ensure camera and microphone permissions are requested and handled. The app uses `flutter_webrtc` which requires platform permissions to be granted by the user.

## Tests and verification

- There are no end-to-end tests included for real-time calling in this repo. To manually test:
	1. Run the app on two devices (or one emulator and one physical device) logged in as different users.
	2. Initiate a call from one user to the other and verify audio/video connectivity and controls.

## Troubleshooting

- No remote video/audio: check microphone/camera permissions, network connectivity, and confirm that both devices can reach STUN/TURN servers.
- Candidates not exchanged: make sure Firestore reads/writes are succeeding and that Firestore security rules allow reads/writes for the calling users.
- Long connection times / one-way audio: likely missing TURN or candidate exchange delays — add TURN and validate both sides add the remote candidates.

## Contributing

Contributions are welcome. Please open issues or PRs describing changes. Keep changes small and focused. If you modify signaling or call logic, add clear notes about the schema and compatibility.

## License

This project does not include an explicit license file. Add a license (for example MIT) if you intend to open-source this repository.
