import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../core/app_colors.dart';
import '../../core/services/chat_service.dart';
import '../../core/services/storage_service.dart';
import 'contact_details_screen.dart';
import 'create_group_screen.dart';

class MessageScreen extends StatefulWidget {
  final String userName;
  final String receiverId;

  const MessageScreen({
    super.key,
    required this.userName,
    required this.receiverId,
  });

  @override
  State<MessageScreen> createState() => _MessageScreenState();
}

class _MessageScreenState extends State<MessageScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  void sendMessage() async {
    if (_messageController.text.trim().isNotEmpty) {
      final chatService = Provider.of<ChatService>(context, listen: false);
      await chatService.sendMessage(widget.receiverId, _messageController.text);
      _messageController.clear();
      _scrollToBottom();
    }
  }

  Future<void> _sendImageMessage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source, imageQuality: 75);
    if (pickedFile == null) return;

    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("Uploading image...")));

    final storageService = Provider.of<StorageService>(context, listen: false);
    final chatService = Provider.of<ChatService>(context, listen: false);
    final url = await storageService.uploadFile(
      File(pickedFile.path),
      'chat_images',
    );

    if (url != null) {
      await chatService.sendMessage(
        widget.receiverId,
        'Photo',
        type: 'image',
        mediaUrl: url,
      );
      _scrollToBottom();
    }
  }

  Future<void> _sendDocumentMessage() async {
    final result = await FilePicker.pickFiles();
    if (result == null || result.files.isEmpty) return;

    final file = result.files.single;
    if (file.path == null) return;

    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("Uploading document...")));

    final storageService = Provider.of<StorageService>(context, listen: false);
    final chatService = Provider.of<ChatService>(context, listen: false);
    final url = await storageService.uploadFile(File(file.path!), 'chat_docs');

    if (url != null) {
      await chatService.sendMessage(
        widget.receiverId,
        file.name,
        type: 'doc',
        mediaUrl: url,
        fileName: file.name,
      );
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final chatService = Provider.of<ChatService>(context);
    final currentUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
        child: SafeArea(
          child: Column(
            children: [
              // Custom Chat AppBar
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
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
                            builder:
                                (context) => ContactDetailsScreen(
                                  userName: widget.userName,
                                ),
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
                              builder:
                                  (context) => ContactDetailsScreen(
                                    userName: widget.userName,
                                  ),
                            ),
                          );
                        },
                        child: StreamBuilder<DocumentSnapshot>(
                          stream:
                              FirebaseFirestore.instance
                                  .collection('users')
                                  .doc(widget.receiverId)
                                  .snapshots(),
                          builder: (context, snapshot) {
                            bool isOnline = false;
                            String subtitle = "Offline";

                            if (snapshot.hasData &&
                                snapshot.data?.data() != null) {
                              final data =
                                  snapshot.data!.data() as Map<String, dynamic>;
                              isOnline = data['isOnline'] == true;
                              final lastSeen = data['lastSeen'] as Timestamp?;
                              subtitle =
                                  isOnline
                                      ? "Online"
                                      : (lastSeen != null
                                          ? "Last seen ${lastSeen.toDate().toString().substring(0, 16)}"
                                          : "Offline");
                            }

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.userName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                Text(
                                  subtitle,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color:
                                        isOnline
                                            ? Colors.green
                                            : Colors.black54,
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.videocam_outlined),
                      onPressed: () {},
                    ),
                    IconButton(
                      icon: const Icon(Icons.call_outlined),
                      onPressed: () {},
                    ),
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert),
                      onSelected: (value) {
                        if (value == 'View contact') {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (context) => ContactDetailsScreen(
                                    userName: widget.userName,
                                  ),
                            ),
                          );
                        } else if (value == 'New group') {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const CreateGroupScreen(),
                            ),
                          );
                        }
                      },
                      itemBuilder: (BuildContext context) {
                        return [
                          'New group',
                          'View contact',
                          'Search',
                          'Mute notifications',
                          'Chat theme',
                          'More',
                        ].map((String choice) {
                          if (choice == 'More') {
                            return PopupMenuItem<String>(
                              value: choice,
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(choice),
                                  const Icon(
                                    Icons.arrow_right,
                                    color: Colors.black54,
                                  ),
                                ],
                              ),
                            );
                          }
                          return PopupMenuItem<String>(
                            value: choice,
                            child: Text(choice),
                          );
                        }).toList();
                      },
                    ),
                  ],
                ),
              ),

              // Messages List
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: chatService.getMessages(
                    currentUser!.uid,
                    widget.receiverId,
                  ),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return const Center(
                        child: Text("Error loading messages"),
                      );
                    }
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final docs = snapshot.data!.docs;

                    // Automatically scroll to bottom on new messages
                    WidgetsBinding.instance.addPostFrameCallback(
                      (_) => _scrollToBottom(),
                    );

                    return ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(20),
                      itemCount: docs.length,
                      itemBuilder: (context, index) {
                        Map<String, dynamic> data =
                            docs[index].data() as Map<String, dynamic>;
                        bool isCurrentUser =
                            data['senderId'] == currentUser.uid;

                        return _messageBubble(data, isCurrentUser);
                      },
                    );
                  },
                ),
              ),

              // Enhanced Input Bar
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                margin: const EdgeInsets.only(left: 10, right: 10, bottom: 10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 5,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.emoji_emotions_outlined,
                        color: Colors.black54,
                      ),
                      onPressed: () {},
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.attach_file_outlined,
                        color: Colors.black54,
                      ),
                      onPressed: () {
                        _showAttachmentMenu(context);
                      },
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.camera_alt_outlined,
                        color: Colors.black54,
                      ),
                      onPressed: () {
                        _sendImageMessage(ImageSource.camera);
                      },
                    ),
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          hintText: "Type message...",
                          hintStyle: TextStyle(fontSize: 15),
                        ),
                        onSubmitted: (_) => sendMessage(),
                      ),
                    ),
                    GestureDetector(
                      onTap: sendMessage,
                      onLongPress: () {
                        // Voice recording logic
                      },
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: const BoxDecoration(
                          color: AppColors.mint,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _messageController.text.isEmpty
                              ? Icons.mic_none
                              : Icons.send,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAttachmentMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder:
          (context) => Container(
            height: 300,
            margin: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(30),
            ),
            child: GridView.count(
              crossAxisCount: 3,
              padding: const EdgeInsets.all(20),
              children: [
                _attachmentOption(
                  Icons.description,
                  "Document",
                  Colors.indigo,
                  onTap: () async {
                    Navigator.pop(context);
                    await _sendDocumentMessage();
                  },
                ),
                _attachmentOption(
                  Icons.image,
                  "Photos",
                  Colors.pink,
                  onTap: () async {
                    Navigator.pop(context);
                    await _sendImageMessage(ImageSource.gallery);
                  },
                ),
                _attachmentOption(
                  Icons.camera_alt,
                  "Camera",
                  Colors.red,
                  onTap: () async {
                    Navigator.pop(context);
                    await _sendImageMessage(ImageSource.camera);
                  },
                ),
                _attachmentOption(
                  Icons.person,
                  "Contact",
                  Colors.blue,
                  onTap: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Contact sharing coming soon"),
                      ),
                    );
                  },
                ),
                _attachmentOption(
                  Icons.location_on,
                  "Location",
                  Colors.green,
                  onTap: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Location sharing coming soon"),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
    );
  }

  Widget _attachmentOption(
    IconData icon,
    String label,
    Color color, {
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          CircleAvatar(
            radius: 25,
            backgroundColor: color.withOpacity(0.2),
            child: Icon(icon, color: color),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

  Widget _messageBubble(Map<String, dynamic> data, bool isCurrentUser) {
    final String type = data['messageType'] ?? 'text';
    final String text = data['message'] ?? '';
    final String? mediaUrl = data['mediaUrl'];
    final String? fileName = data['fileName'];

    final bubbleColor = isCurrentUser ? Colors.green.shade300 : Colors.white;
    final textColor = isCurrentUser ? Colors.white : Colors.black87;

    Widget content;
    if (type == 'image' && mediaUrl != null) {
      content = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.network(
              mediaUrl,
              width: 220,
              height: 160,
              fit: BoxFit.cover,
            ),
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
          Flexible(
            child: Text(
              fileName ?? text,
              style: TextStyle(color: textColor),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      );
    } else {
      content = Text(text, style: TextStyle(color: textColor));
    }

    return Align(
      alignment: isCurrentUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        constraints: const BoxConstraints(maxWidth: 260),
        decoration: BoxDecoration(
          color: bubbleColor,
          borderRadius: BorderRadius.circular(22),
        ),
        child: content,
      ),
    );
  }
}
