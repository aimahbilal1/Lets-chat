import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'core/app_theme.dart';
import 'core/services/call_signaling_service.dart';
import 'firebase_options.dart';
import 'screens/calls/incoming_call_screen.dart';
import 'screens/splash/splash_screen.dart';
import 'core/services/auth_service.dart';
import 'core/services/chat_service.dart';
import 'core/services/storage_service.dart';
import 'core/services/notification_service.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  FlutterError.onError = (details) {
    FlutterError.dumpErrorToConsole(details);
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('[GlobalError] $error');
    debugPrint('[GlobalError] $stack');
    return true;
  };
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint("Firebase initialization failed: $e");
  }
  runApp(const LetsChatApp());
}

class LetsChatApp extends StatelessWidget {
  const LetsChatApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        ChangeNotifierProvider(create: (_) => ChatService()),
        Provider(create: (_) => StorageService()),
        ChangeNotifierProvider(create: (_) => NotificationService()),
      ],
      child: const _LetsChatAppRoot(),
    );
  }
}

class _LetsChatAppRoot extends StatefulWidget {
  const _LetsChatAppRoot();

  @override
  State<_LetsChatAppRoot> createState() => _LetsChatAppRootState();
}

class _LetsChatAppRootState extends State<_LetsChatAppRoot> with WidgetsBindingObserver {
  final CallSignalingService _signalingService = CallSignalingService();
  StreamSubscription<QuerySnapshot>? _incomingCallSub;
  StreamSubscription<User?>? _authSub;
  final Set<String> _handledCallIds = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initNotifications();
    // Re-subscribe to incoming calls whenever the user signs in/out so we
    // never start listening on a null uid (which returns Stream.empty()).
    _authSub = FirebaseAuth.instance.authStateChanges().listen((user) {
      _incomingCallSub?.cancel();
      _handledCallIds.clear();
      if (user != null) {
        _setPresence(isOnline: true);
        _listenForIncomingCalls();
      }
    });
  }

  void _listenForIncomingCalls() {
    _incomingCallSub = _signalingService.incomingCallsStream().listen((snapshot) {
      for (final doc in snapshot.docs) {
        final callId = doc.id;
        if (_handledCallIds.contains(callId)) continue;
        _handledCallIds.add(callId);

        final data = doc.data() as Map<String, dynamic>;
        final callerName = data['callerName'] as String? ?? 'Unknown';
        final callType = data['type'] as String? ?? 'audio';

        navigatorKey.currentState?.push(
          MaterialPageRoute(
            builder: (_) => IncomingCallScreen(
              callId: callId,
              callerName: callerName,
              callType: callType,
              signalingService: _signalingService,
            ),
          ),
        );
      }
    });
  }

  Future<void> _initNotifications() async {
    final notificationService = Provider.of<NotificationService>(context, listen: false);
    await notificationService.initialize();
  }

  Future<void> _setPresence({required bool isOnline}) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
      'isOnline': isOnline,
      'lastSeen': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _setPresence(isOnline: true);
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached ||
        state == AppLifecycleState.inactive) {
      _setPresence(isOnline: false);
    }
  }

  @override
  void dispose() {
    _authSub?.cancel();
    _incomingCallSub?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    _setPresence(isOnline: false);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      title: "Let's Chat",
      theme: AppTheme.lightTheme,
      home: const SplashScreen(),
    );
  }
}
