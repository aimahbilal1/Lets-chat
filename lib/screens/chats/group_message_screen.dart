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

class GroupMessageScreen extends StatefulWidget {
  final String groupId;
  final String groupName;

  const GroupMessageScreen({
    super.key,
    required this.groupId,
    required this.groupName,
  });

  @override
  State<GroupMessageScreen> createState() => _GroupMessageScreenState();
}

class _GroupMessageScreenState extends State<GroupMessageScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;
    final chatService = Provider.of<ChatService>(context, listen: false);
    await chatService.sendGroupMessage(widget.groupId, _messageController.text);
    _messageController.clear();
    _scrollToBottom();
  }

  Future<void> _sendImageMessage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source, imageQuality: 75);
    if (pickedFile == null) return;

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Uploading image...')),
    );

    final storageService = Provider.of<StorageService>(context, listen: false);
    final chatService = Provider.of<ChatService>(context, listen: false);
    final url = await storageService.uploadFile(
      File(pickedFile.path),
      'group_images',
    );

    if (url != null) {
      await chatService.sendGroupMessage(
        widget.groupId,
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
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Uploading document...')),
    );

    final storageService = Provider.of<StorageService>(context, listen: false);
    final chatService = Provider.of<ChatService>(context, listen: false);
    final url = await storageService.uploadFile(File(file.path!), 'group_docs');

    if (url != null) {
      await chatService.sendGroupMessage(
        widget.groupId,
        file.name,
        type: 'doc',
        mediaUrl: url,
        fileName: file.name,
      );
      _scrollToBottom();
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
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back),
                    ),
                    CircleAvatar(
                      backgroundColor: Colors.purple.shade200,
                      child: Text(widget.groupName[0].toUpperCase()),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        widget.groupName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: chatService.getGroupMessages(widget.groupId),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return const Center(child: Text('Error loading messages'));
                    }
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final docs = snapshot.data!.docs;
                    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

                    return ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(20),
                      itemCount: docs.length,
                      itemBuilder: (context, index) {
                        final data = docs[index].data() as Map<String, dynamic>;
                        final isCurrentUser = data['senderId'] == currentUser?.uid;
                        return _groupMessageBubble(data, isCurrentUser);
                      },
                    );
                  },
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
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
                      icon: const Icon(Icons.attach_file_outlined, color: Colors.black54),
                      onPressed: () => _showAttachmentMenu(context),
                    ),
                    IconButton(
                      icon: const Icon(Icons.camera_alt_outlined, color: Colors.black54),
                      onPressed: () => _sendImageMessage(ImageSource.camera),
                    ),
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          hintText: 'Type message...',
                          hintStyle: TextStyle(fontSize: 15),
                        ),
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                    GestureDetector(
                      onTap: _sendMessage,
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: const BoxDecoration(
                          color: AppColors.mint,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _messageController.text.isEmpty ? Icons.mic_none : Icons.send,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    )
                  ],
                ),
              )
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
      builder: (context) => Container(
        height: 260,
        margin: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
        ),
        child: GridView.count(
          crossAxisCount: 3,
          padding: const EdgeInsets.all(20),
          children: [
            _attachmentOption(Icons.description, 'Document', Colors.indigo, onTap: () async {
              Navigator.pop(context);
              await _sendDocumentMessage();
            }),
            _attachmentOption(Icons.image, 'Photos', Colors.pink, onTap: () async {
              Navigator.pop(context);
              await _sendImageMessage(ImageSource.gallery);
            }),
            _attachmentOption(Icons.camera_alt, 'Camera', Colors.red, onTap: () async {
              Navigator.pop(context);
              await _sendImageMessage(ImageSource.camera);
            }),
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

  Widget _groupMessageBubble(Map<String, dynamic> data, bool isCurrentUser) {
    final String type = data['messageType'] ?? 'text';
    final String text = data['message'] ?? '';
    final String? mediaUrl = data['mediaUrl'];
    final String? fileName = data['fileName'];
    final String sender = data['senderEmail']?.toString().split('@').first ?? 'User';

    final bubbleColor = isCurrentUser ? Colors.green.shade300 : Colors.white;
    final textColor = isCurrentUser ? Colors.white : Colors.black87;

    Widget content;
    if (type == 'image' && mediaUrl != null) {
      content = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(sender, style: TextStyle(fontSize: 12, color: textColor.withOpacity(0.8))),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.network(mediaUrl, width: 220, height: 160, fit: BoxFit.cover),
          ),
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
      content = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(sender, style: TextStyle(fontSize: 12, color: textColor.withOpacity(0.8))),
          const SizedBox(height: 6),
          Text(text, style: TextStyle(color: textColor)),
        ],
      );
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
