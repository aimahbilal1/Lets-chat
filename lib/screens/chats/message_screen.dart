import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:uuid/uuid.dart';

import '../../core/app_colors.dart';
import '../../core/services/call_signaling_service.dart';
import '../../core/services/chat_service.dart';
import '../../core/services/storage_service.dart';
import '../calls/audio_call_screen.dart';
import '../calls/video_call_screen.dart';
import 'contact_details_screen.dart';
import 'create_group_screen.dart';

class MessageScreen extends StatefulWidget {
  final String userName;
  final String receiverId;
  final String chatRoomId;

  const MessageScreen({
    super.key,
    required this.userName,
    required this.receiverId,
    required this.chatRoomId,
  });

  @override
  State<MessageScreen> createState() => _MessageScreenState();
}

class _MessageScreenState extends State<MessageScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  Map<String, dynamic>? _replyingTo;
  int _messageLimit = 40;
  bool _isLoadingMore = false;
  final AudioRecorder _audioRecorder = AudioRecorder();
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isRecording = false;
  String? _currentlyPlayingId;
  bool _emojiShowing = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ChatService>(context, listen: false).markAllMessagesAsRead(widget.chatRoomId);
    });

    _audioPlayer.onPlayerComplete.listen((event) {
      if (mounted) {
        setState(() {
          _currentlyPlayingId = null;
        });
      }
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _audioRecorder.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      if (!_isLoadingMore) {
        setState(() {
          _isLoadingMore = true;
          _messageLimit += 40;
        });
        // Briefly debouncing or just letting stream rebuild
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) setState(() => _isLoadingMore = false);
        });
      }
    }
  }

  void sendMessage() async {
    if (_messageController.text.trim().isNotEmpty) {
      final chatService = Provider.of<ChatService>(context, listen: false);
      
      String? replyId;
      String? replyText;
      String? replySender;
      
      if (_replyingTo != null) {
        replyId = _replyingTo!['id'];
        replyText = _replyingTo!['messageType'] == 'text' ? _replyingTo!['message'] : 'Attachment';
        replySender = _replyingTo!['senderEmail'].toString().split('@')[0];
      }

      await chatService.sendMessage(
        widget.receiverId, 
        _messageController.text,
        replyToId: replyId,
        replyToText: replyText,
        replyToSender: replySender,
      );
      
      _messageController.clear();
      setState(() {
        _replyingTo = null;
      });
      _scrollToBottom();
    }
  }

  Future<void> _startRecording() async {
    final status = await Permission.microphone.request();
    if (status != PermissionStatus.granted) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Microphone permission denied')));
      return;
    }

    if (await _audioRecorder.hasPermission()) {
      final Directory tempDir = await getTemporaryDirectory();
      final String path = '${tempDir.path}/voice_${const Uuid().v4()}.m4a';
      
      await _audioRecorder.start(
        const RecordConfig(encoder: AudioEncoder.aacLc),
        path: path,
      );
      
      setState(() {
        _isRecording = true;
      });
    }
  }

  Future<void> _stopRecordingAndSend() async {
    if (!_isRecording) return;
    
    final path = await _audioRecorder.stop();
    setState(() {
      _isRecording = false;
    });

    if (path != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Sending voice message...")));
      
      final storageService = Provider.of<StorageService>(context, listen: false);
      final chatService = Provider.of<ChatService>(context, listen: false);
      
      final url = await storageService.uploadFile(File(path), 'chat_voices');
      if (url != null) {
        await chatService.sendMessage(widget.receiverId, 'Voice Message', type: 'voice', mediaUrl: url);
        _scrollToBottom();
      }
    }
  }

  Future<void> _playPauseVoice(String messageId, String url) async {
    if (_currentlyPlayingId == messageId) {
      await _audioPlayer.pause();
      setState(() {
        _currentlyPlayingId = null;
      });
    } else {
      await _audioPlayer.play(UrlSource(url));
      setState(() {
        _currentlyPlayingId = messageId;
      });
    }
  }

  Future<void> _sendImageMessage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source, imageQuality: 75);
    if (pickedFile == null) return;

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Uploading image...")));

    final storageService = Provider.of<StorageService>(context, listen: false);
    final chatService = Provider.of<ChatService>(context, listen: false);
    final url = await storageService.uploadFile(File(pickedFile.path), 'chat_images');

    if (url != null) {
      await chatService.sendMessage(widget.receiverId, 'Photo', type: 'image', mediaUrl: url);
      _scrollToBottom();
    }
  }

  Future<void> _sendDocumentMessage() async {
    final result = await FilePicker.pickFiles();
    if (result == null || result.files.isEmpty) return;

    final file = result.files.single;
    if (file.path == null) return;

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Uploading document...")));

    final storageService = Provider.of<StorageService>(context, listen: false);
    final chatService = Provider.of<ChatService>(context, listen: false);
    final url = await storageService.uploadFile(File(file.path!), 'chat_docs');

    if (url != null) {
      await chatService.sendMessage(widget.receiverId, file.name, type: 'doc', mediaUrl: url, fileName: file.name);
      _scrollToBottom();
    }
  }

  Future<void> _startCall(BuildContext context, String type) async {
    final signalingService = CallSignalingService();
    final currentUser = FirebaseAuth.instance.currentUser;
    final callerName = currentUser?.email?.split('@')[0] ?? 'Me';

    try {
      await signalingService.getLocalStream(video: type == 'video');
      final callId = await signalingService.initiateCall(
        receiverId: widget.receiverId,
        callerName: callerName,
        receiverName: widget.userName,
        type: type,
        onRemoteStream: (_) {},
        onCallEnded: () {},
      );

      if (!context.mounted) return;

      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => type == 'video'
              ? VideoCallScreen(
                  contactName: widget.userName,
                  callId: callId,
                  isCaller: true,
                  signalingService: signalingService,
                )
              : AudioCallScreen(
                  contactName: widget.userName,
                  callId: callId,
                  isCaller: true,
                  signalingService: signalingService,
                ),
        ),
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not start call: $e')),
        );
      }
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _showMessageOptions(Map<String, dynamic> data, String messageId, bool isCurrentUser) {
    final emojis = ['👍', '❤️', '😂', '😮', '😢', '🙏'];
    final isText = data['messageType'] == 'text';
    final chatService = Provider.of<ChatService>(context, listen: false);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Reaction row
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: emojis.map((emoji) => GestureDetector(
                  onTap: () async {
                    Navigator.pop(ctx);
                    await chatService.addReaction(widget.chatRoomId, messageId, emoji);
                  },
                  child: Text(emoji, style: const TextStyle(fontSize: 30)),
                )).toList(),
              ),
            ),
            const Divider(height: 1),
            // Reply
            ListTile(
              leading: const Icon(Icons.reply, color: Colors.black87),
              title: const Text("Reply"),
              onTap: () {
                Navigator.pop(ctx);
                setState(() => _replyingTo = {...data, 'id': messageId});
              },
            ),
            // Copy (text only)
            if (isText)
              ListTile(
                leading: const Icon(Icons.copy, color: Colors.black87),
                title: const Text("Copy"),
                onTap: () {
                  Navigator.pop(ctx);
                  Clipboard.setData(ClipboardData(text: data['message'] ?? ''));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Message copied"), duration: Duration(seconds: 1)),
                  );
                },
              ),
            // Delete for me
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: const Text("Delete for me", style: TextStyle(color: Colors.red)),
              onTap: () async {
                Navigator.pop(ctx);
                await chatService.deleteMessage(widget.chatRoomId, messageId, forEveryone: false);
              },
            ),
            // Delete for everyone (sender only)
            if (isCurrentUser)
              ListTile(
                leading: const Icon(Icons.delete_forever, color: Colors.red),
                title: const Text("Delete for everyone", style: TextStyle(color: Colors.red)),
                onTap: () async {
                  Navigator.pop(ctx);
                  await chatService.deleteMessage(widget.chatRoomId, messageId, forEveryone: true);
                },
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final chatService = Provider.of<ChatService>(context, listen: false);
    final currentUser = FirebaseAuth.instance.currentUser;

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(currentUser?.uid).snapshots(),
      builder: (context, userSnapshot) {
        double currentFontSize = 15.0;
        BoxDecoration backgroundDecoration = const BoxDecoration(gradient: AppColors.primaryGradient);

        bool isBlocked = false;

        if (userSnapshot.hasData && userSnapshot.data?.data() != null) {
          final data = userSnapshot.data!.data() as Map<String, dynamic>;
          
          final List blockedUsers = data['blockedUsers'] ?? [];
          isBlocked = blockedUsers.contains(widget.receiverId);

          final chatSettings = data['settings']?['Chats'] ?? {};
          final String fontSizeStr = chatSettings['Font size'] ?? 'Medium';
          if (fontSizeStr == 'Small') currentFontSize = 12.0;
          if (fontSizeStr == 'Large') currentFontSize = 18.0;

          final String wallpaper = chatSettings['Wallpaper'] ?? 'Default';
          if (wallpaper == 'Dark') {
            backgroundDecoration = const BoxDecoration(color: Color(0xFF1E1E1E));
          } else if (wallpaper != 'Default') {
            // Simplified custom handling
            backgroundDecoration = BoxDecoration(color: Colors.grey.shade200);
          }
        }

        return Scaffold(
          body: Container(
            decoration: backgroundDecoration,
            child: SafeArea(
          child: Column(
            children: [
              // Custom Chat AppBar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ContactDetailsScreen(receiverId: widget.receiverId),
                          ),
                        );
                      },
                      child: CircleAvatar(
                        backgroundColor: Colors.pink.shade200,
                        child: Text(widget.userName[0].toUpperCase()),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ContactDetailsScreen(receiverId: widget.receiverId),
                            ),
                          );
                        },
                        child: StreamBuilder<DocumentSnapshot>(
                          stream: FirebaseFirestore.instance.collection('users').doc(widget.receiverId).snapshots(),
                          builder: (context, snapshot) {
                            bool isOnline = false;
                            String subtitle = "Offline";

                            if (snapshot.hasData && snapshot.data?.data() != null) {
                              final data = snapshot.data!.data() as Map<String, dynamic>;
                              isOnline = data['isOnline'] == true;
                              final lastSeen = data['lastSeen'] as Timestamp?;
                              
                              final privacy = data['settings']?['Privacy']?['Last seen'] ?? 'Everyone';
                              if (privacy == 'Nobody') {
                                subtitle = "";
                              } else {
                                subtitle = isOnline
                                    ? "Online"
                                    : (lastSeen != null ? "Last seen ${lastSeen.toDate().toString().substring(0, 16)}" : "Offline");
                              }
                            }

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(widget.userName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                if (subtitle.isNotEmpty) Text(subtitle, style: TextStyle(fontSize: 12, color: isOnline ? Colors.green : Colors.black54)),
                              ],
                            );
                          },
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.videocam_outlined),
                      onPressed: () => _startCall(context, 'video'),
                    ),
                    IconButton(
                      icon: const Icon(Icons.call_outlined),
                      onPressed: () => _startCall(context, 'audio'),
                    ),
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert),
                      onSelected: (value) {
                        if (value == 'View contact') {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => ContactDetailsScreen(receiverId: widget.receiverId)),
                          );
                        } else if (value == 'New group') {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const CreateGroupScreen()),
                          );
                        }
                      },
                      itemBuilder: (BuildContext context) {
                        return ['New group', 'View contact', 'Search', 'Mute notifications', 'Chat theme', 'More'].map((String choice) {
                          return PopupMenuItem<String>(value: choice, child: Text(choice));
                        }).toList();
                      },
                    ),
                  ],
                ),
              ),

              // Messages List
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: chatService.getMessages(currentUser!.uid, widget.receiverId, limit: _messageLimit),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) return const Center(child: Text("Error loading messages"));
                    if (snapshot.connectionState == ConnectionState.waiting && _messageLimit == 40) return const Center(child: CircularProgressIndicator());

                    final docs = snapshot.data!.docs;

                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      chatService.markAllMessagesAsRead(widget.chatRoomId);
                    });

                    return ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(20),
                      reverse: true,
                      itemCount: docs.length + (_isLoadingMore ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == docs.length) {
                           return const Center(child: Padding(
                             padding: EdgeInsets.all(8.0),
                             child: CircularProgressIndicator(strokeWidth: 2),
                           ));
                        }
                        Map<String, dynamic> data = docs[index].data() as Map<String, dynamic>;
                        final messageId = docs[index].id;
                        bool isCurrentUser = data['senderId'] == currentUser.uid;

                        List deletedFor = data['deletedFor'] ?? [];
                        if (deletedFor.contains(currentUser.uid)) {
                          return const SizedBox();
                        }

                        return GestureDetector(
                          onLongPress: () {
                            if (data['messageType'] != 'deleted') {
                              _showMessageOptions(data, messageId, isCurrentUser);
                            }
                          },
                          onHorizontalDragEnd: (details) {
                            if (details.primaryVelocity != null && details.primaryVelocity! > 0) {
                              if (data['messageType'] != 'deleted') {
                                setState(() {
                                  _replyingTo = {...data, 'id': messageId};
                                });
                              }
                            }
                          },
                          child: _messageBubble(data, isCurrentUser, messageId, currentFontSize),
                        );
                      },
                    );
                  },
                ),
              ),

              if (_replyingTo != null)
                Container(
                  padding: const EdgeInsets.all(10),
                  margin: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.reply, color: AppColors.mint),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Replying to ${_replyingTo!['senderEmail'].toString().split('@')[0]}",
                              style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.mint, fontSize: 12),
                            ),
                            Text(
                              _replyingTo!['messageType'] == 'text' ? _replyingTo!['message'] : 'Attachment',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: Colors.black54, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, size: 20),
                        onPressed: () => setState(() => _replyingTo = null),
                      ),
                    ],
                  ),
                ),

              // Enhanced Input Bar
              if (isBlocked)
                Container(
                  padding: const EdgeInsets.all(20),
                  margin: const EdgeInsets.only(bottom: 10, left: 10, right: 10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  alignment: Alignment.center,
                  child: const Text(
                    "You blocked this contact. Unblock to send messages.",
                    style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  margin: EdgeInsets.only(
                    left: 10, right: 10, bottom: 10, 
                    top: _replyingTo != null ? 0 : 0
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    borderRadius: _replyingTo != null 
                      ? const BorderRadius.vertical(bottom: Radius.circular(30))
                      : BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5, offset: const Offset(0, 2)),
                    ],
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: Icon(
                          _emojiShowing ? Icons.keyboard : Icons.emoji_emotions_outlined,
                          color: Colors.black54,
                        ),
                        onPressed: () {
                          if (_emojiShowing) {
                            FocusScope.of(context).requestFocus(FocusNode());
                          } else {
                            FocusScope.of(context).unfocus();
                          }
                          setState(() => _emojiShowing = !_emojiShowing);
                        },
                      ),
                      IconButton(icon: const Icon(Icons.attach_file_outlined, color: Colors.black54), onPressed: () => _showAttachmentMenu(context)),
                      IconButton(icon: const Icon(Icons.camera_alt_outlined, color: Colors.black54), onPressed: () => _sendImageMessage(ImageSource.camera)),
                      Expanded(
                        child: _isRecording
                          ? const Text("Recording...", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold))
                          : TextField(
                              controller: _messageController,
                              onTap: () {
                                if (_emojiShowing) setState(() => _emojiShowing = false);
                              },
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                hintText: "Type message...",
                                hintStyle: TextStyle(fontSize: 15),
                            ),
                            onSubmitted: (_) => sendMessage(),
                          ),
                    ),
                    ValueListenableBuilder<TextEditingValue>(
                      valueListenable: _messageController,
                      builder: (context, value, _) {
                        final hasText = value.text.isNotEmpty;
                        return GestureDetector(
                          onTap: () {
                            if (hasText) sendMessage();
                          },
                          onLongPress: () {
                            if (!hasText) _startRecording();
                          },
                          onLongPressEnd: (details) {
                            if (_isRecording) _stopRecordingAndSend();
                          },
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: _isRecording ? Colors.red : AppColors.mint,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(hasText ? Icons.send : Icons.mic_none, color: Colors.white, size: 20),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              if (_emojiShowing)
                SizedBox(
                  height: 280,
                  child: EmojiPicker(
                    textEditingController: _messageController,
                    onEmojiSelected: (category, emoji) {},
                    config: const Config(
                      emojiViewConfig: EmojiViewConfig(
                        emojiSizeMax: 28,
                        columns: 8,
                      ),
                      bottomActionBarConfig: BottomActionBarConfig(showBackspaceButton: true),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

  void _showAttachmentMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: 300,
        margin: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(30)),
        child: GridView.count(
          crossAxisCount: 3,
          padding: const EdgeInsets.all(20),
          children: [
            _attachmentOption(Icons.description, "Document", Colors.indigo, onTap: () async {
              Navigator.pop(context);
              await _sendDocumentMessage();
            }),
            _attachmentOption(Icons.image, "Photos", Colors.pink, onTap: () async {
              Navigator.pop(context);
              await _sendImageMessage(ImageSource.gallery);
            }),
            _attachmentOption(Icons.camera_alt, "Camera", Colors.red, onTap: () async {
              Navigator.pop(context);
              await _sendImageMessage(ImageSource.camera);
            }),
            _attachmentOption(Icons.person, "Contact", Colors.blue, onTap: () {
              Navigator.pop(context);
              _messageController.text = "[Shared Contact 👤]";
              sendMessage();
            }),
            _attachmentOption(Icons.location_on, "Location", Colors.green, onTap: () {
              Navigator.pop(context);
              _messageController.text = "[Shared Location: 📍 My Current Location]";
              sendMessage();
            }),
          ],
        ),
      ),
    );
  }

  Widget _attachmentOption(IconData icon, String label, Color color, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          CircleAvatar(radius: 25, backgroundColor: color.withOpacity(0.2), child: Icon(icon, color: color)),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

  Widget _messageBubble(Map<String, dynamic> data, bool isCurrentUser, String messageId, double fontSize) {
    final String type = data['messageType'] ?? 'text';
    final String text = data['message'] ?? '';
    final String? mediaUrl = data['mediaUrl'];
    final String? fileName = data['fileName'];
    final bool isRead = data['isRead'] ?? false;
    final Timestamp timestamp = data['timestamp'] ?? Timestamp.now();
    final timeStr = "${timestamp.toDate().hour.toString().padLeft(2, '0')}:${timestamp.toDate().minute.toString().padLeft(2, '0')}";

    final String? replyToText = data['replyToText'];
    final String? replyToSender = data['replyToSender'];
    final Map<String, dynamic>? reactions = data['reactions'];

    final bubbleColor = isCurrentUser ? Colors.green.shade300 : Colors.white;
    final textColor = isCurrentUser ? Colors.white : Colors.black87;

    Widget content;
    if (type == 'deleted') {
      content = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.block, color: textColor.withOpacity(0.7), size: 16),
          const SizedBox(width: 6),
          Text("This message was deleted", style: TextStyle(color: textColor.withOpacity(0.7), fontStyle: FontStyle.italic)),
        ],
      );
    } else if (type == 'image' && mediaUrl != null) {
      content = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.network(mediaUrl, width: 220, height: 160, fit: BoxFit.cover),
          ),
          if (text.isNotEmpty && text != 'Photo') ...[
            const SizedBox(height: 8),
            Text(text, style: TextStyle(color: textColor)),
          ],
        ],
      );
    } else if (type == 'doc' && mediaUrl != null) {
      content = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.description, color: textColor),
          const SizedBox(width: 10),
          Flexible(child: Text(fileName ?? text, style: TextStyle(color: textColor), overflow: TextOverflow.ellipsis)),
        ],
      );
    } else if (type == 'voice' && mediaUrl != null) {
      bool isPlaying = _currentlyPlayingId == messageId;
      content = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: () => _playPauseVoice(messageId, mediaUrl),
            child: Icon(isPlaying ? Icons.pause_circle_filled : Icons.play_circle_fill, color: textColor, size: 30),
          ),
          const SizedBox(width: 10),
          Icon(Icons.graphic_eq, color: textColor),
          Icon(Icons.graphic_eq, color: textColor),
          Icon(Icons.graphic_eq, color: textColor),
        ],
      );
    } else {
      content = Text(text, style: TextStyle(color: textColor, fontSize: fontSize));
    }

    Widget bubbleWrapper = Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(12),
          constraints: const BoxConstraints(maxWidth: 280),
          decoration: BoxDecoration(
            color: bubbleColor,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (replyToText != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(replyToSender ?? '', style: TextStyle(fontWeight: FontWeight.bold, color: textColor, fontSize: 12)),
                      Text(replyToText, style: TextStyle(color: textColor.withOpacity(0.8), fontSize: 12), maxLines: 2, overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
              content,
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(timeStr, style: TextStyle(fontSize: 10, color: isCurrentUser ? Colors.white70 : Colors.black54)),
                  if (isCurrentUser) ...[
                    const SizedBox(width: 4),
                    Icon(
                      isRead ? Icons.done_all : Icons.check,
                      size: 14,
                      color: isRead ? Colors.blue.shade700 : Colors.white70,
                    ),
                  ]
                ],
              ),
            ],
          ),
        ),
        
        if (reactions != null && reactions.isNotEmpty)
          Positioned(
            bottom: 4,
            right: isCurrentUser ? null : 10,
            left: isCurrentUser ? 10 : null,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 2, offset: const Offset(0, 1))],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: reactions.entries
                  .where((e) => (e.value as List).isNotEmpty)
                  .map((e) => Text(e.key, style: const TextStyle(fontSize: 12)))
                  .toList(),
              ),
            ),
          )
      ],
    );

    return Align(
      alignment: isCurrentUser ? Alignment.centerRight : Alignment.centerLeft,
      child: bubbleWrapper,
    );
  }
}
