import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../../core/app_colors.dart';
import '../../core/services/call_signaling_service.dart';
import '../../core/services/chat_service.dart';
import '../../widgets/bottom_nav.dart';
import '../chats/new_message_screen.dart';
import 'audio_call_screen.dart';
import 'video_call_screen.dart';

class CallsScreen extends StatefulWidget {
  const CallsScreen({super.key});

  @override
  State<CallsScreen> createState() => _CallsScreenState();
}

class _CallsScreenState extends State<CallsScreen> {
  String _searchQuery = '';
  bool _showFavouritesOnly = false;

  bool _matchesQuery(String name) {
    if (_searchQuery.trim().isEmpty) return true;
    return name.toLowerCase().contains(_searchQuery.toLowerCase());
  }

  void _openSearch(BuildContext context) {
    final controller = TextEditingController(text: _searchQuery);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Search calls'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Type a name'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              setState(() => _searchQuery = controller.text.trim());
              Navigator.pop(context);
            },
            child: const Text('Search'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final chatService = Provider.of<ChatService>(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Calls", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                  Row(
                    children: [
                      IconButton(icon: const Icon(Icons.search), onPressed: () => _openSearch(context)),
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert),
                        onSelected: (value) async {
                          if (value == 'Clear call log') {
                            await chatService.clearCallLog();
                          } else if (value == 'Schedule calls') {
                            _scheduleCall(context);
                          }
                        },
                        itemBuilder: (_) => ['Clear call log', 'Schedule calls']
                            .map((c) => PopupMenuItem(value: c, child: Text(c)))
                            .toList(),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Control Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _controlIcon(context, Icons.call_outlined, "Call"),
                  _controlIcon(context, Icons.calendar_month_outlined, "Schedule"),
                  _controlIcon(context, Icons.dialpad_outlined, "Keypad"),
                  _controlIcon(context, _showFavouritesOnly ? Icons.star : Icons.star_outline, "Favourite"),
                ],
              ),
            ),

            const SizedBox(height: 10),

            // Call Log
            Expanded(
              child: StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .doc(FirebaseAuth.instance.currentUser?.uid)
                    .snapshots(),
                builder: (context, userSnapshot) {
                  final userData = userSnapshot.data?.data() as Map<String, dynamic>?;
                  final favouriteIds = List<String>.from(userData?['favourites'] ?? []);

                  return StreamBuilder<QuerySnapshot>(
                    stream: chatService.getCallLogs(),
                    builder: (context, snapshot) {
                      return ListView(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        children: [
                          ListTile(
                            leading: const CircleAvatar(
                              backgroundColor: AppColors.mint,
                              child: Icon(Icons.add_call, color: Colors.white),
                            ),
                            title: const Text("New call", style: TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: const Text("Select a contact to call"),
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NewMessageScreen())),
                          ),
                          const Divider(),

                          // Scheduled calls
                          StreamBuilder<QuerySnapshot>(
                            stream: chatService.getScheduledCalls(),
                            builder: (context, scheduledSnapshot) {
                              final docs = scheduledSnapshot.data?.docs ?? [];
                              final filtered = docs.where((doc) {
                                final data = doc.data() as Map<String, dynamic>;
                                return _matchesQuery(data['receiverName'] ?? 'User');
                              }).toList();

                              if (filtered.isEmpty) return const SizedBox.shrink();

                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 10),
                                  const Text("Scheduled Calls", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black54)),
                                  const SizedBox(height: 10),
                                  ...filtered.map((doc) {
                                    final data = doc.data() as Map<String, dynamic>;
                                    final name = data['receiverName'] ?? 'User';
                                    final scheduledAt = (data['scheduledAt'] as Timestamp?)?.toDate();
                                    final time = scheduledAt != null
                                        ? '${scheduledAt.day}/${scheduledAt.month}/${scheduledAt.year} ${scheduledAt.hour.toString().padLeft(2, '0')}:${scheduledAt.minute.toString().padLeft(2, '0')}'
                                        : 'Scheduled';
                                    return _callLogItem(context, name, data['receiverId'] ?? '', 'scheduled • $time', Icons.schedule, Colors.purple, Colors.purple.shade100);
                                  }),
                                  const Divider(),
                                ],
                              );
                            },
                          ),

                          const SizedBox(height: 10),
                          const Text("Recent Calls", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black54)),
                          const SizedBox(height: 10),

                          if (snapshot.hasError)
                            Center(child: Padding(padding: const EdgeInsets.all(20), child: Text("Error: ${snapshot.error}"))),
                          if (snapshot.connectionState == ConnectionState.waiting)
                            const Center(child: CircularProgressIndicator()),
                          if (snapshot.hasData && snapshot.data!.docs.isEmpty)
                            const Center(child: Padding(padding: EdgeInsets.only(top: 50), child: Text("No recent calls"))),

                          if (snapshot.hasData)
                            ...snapshot.data!.docs
                                .where((doc) {
                                  final data = doc.data() as Map<String, dynamic>;
                                  final receiverId = data['receiverId'] ?? '';
                                  final name = data['receiverName'] ?? 'User';
                                  if (_showFavouritesOnly && !favouriteIds.contains(receiverId)) return false;
                                  return _matchesQuery(name);
                                })
                                .map((doc) {
                                  final data = doc.data() as Map<String, dynamic>;
                                  final name = data['receiverName'] ?? 'User';
                                  final receiverId = data['receiverId'] ?? '';
                                  final time = (data['timestamp'] as Timestamp?)?.toDate().toString().substring(11, 16) ?? '';
                                  final details = "${data['status']} • $time";
                                  final icon = data['status'] == 'missed' ? Icons.call_missed : (data['status'] == 'outgoing' ? Icons.call_made : Icons.call_received);
                                  final color = data['status'] == 'missed' ? Colors.red : (data['status'] == 'outgoing' ? Colors.green : Colors.blue);
                                  return _callLogItem(context, name, receiverId, details, icon, color, Colors.pink.shade100);
                                }),
                        ],
                      );
                    },
                  );
                },
              ),
            ),

            const BottomNav(currentIndex: 0),
          ],
        ),
      ),
    );
  }

  Widget _controlIcon(BuildContext context, IconData icon, String label) {
    return GestureDetector(
      onTap: () {
        if (label == "Schedule") {
          _scheduleCall(context);
        } else if (label == "Call") {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const NewMessageScreen()));
        } else if (label == "Keypad") {
          _showKeypad(context);
        } else if (label == "Favourite") {
          setState(() => _showFavouritesOnly = !_showFavouritesOnly);
        }
      },
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.6),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.black87),
          ),
          const SizedBox(height: 5),
          Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  void _showKeypad(BuildContext context) {
    final dialController = TextEditingController();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (sheetContext, setModalState) {
            return Container(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
              constraints: BoxConstraints(maxHeight: MediaQuery.of(sheetContext).size.height * 0.75),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text("Dialer", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          dialController.text.isEmpty ? 'Enter number' : dialController.text,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 4,
                            color: dialController.text.isEmpty ? Colors.black26 : Colors.black87,
                          ),
                        ),
                      ),
                      if (dialController.text.isNotEmpty)
                        IconButton(
                          icon: const Icon(Icons.backspace_outlined),
                          onPressed: () => setModalState(() {
                            dialController.text = dialController.text.substring(0, dialController.text.length - 1);
                          }),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Flexible(
                    child: GridView.count(
                      shrinkWrap: true,
                      crossAxisCount: 3,
                      mainAxisSpacing: 5,
                      crossAxisSpacing: 10,
                      childAspectRatio: 1.5,
                      children: ["1","2","3","4","5","6","7","8","9","*","0","#"].map((key) {
                        return InkWell(
                          borderRadius: BorderRadius.circular(40),
                          onTap: () => setModalState(() => dialController.text += key),
                          child: Container(
                            alignment: Alignment.center,
                            decoration: BoxDecoration(color: Colors.grey.shade100, shape: BoxShape.circle),
                            child: Text(key, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 15),
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.green,
                    child: IconButton(
                      icon: const Icon(Icons.call, color: Colors.white, size: 28),
                      onPressed: () {
                        final number = dialController.text.trim();
                        Navigator.pop(sheetContext);
                        if (number.isNotEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text("Calling $number...")),
                          );
                        }
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _placeCall(BuildContext context, String receiverId, String receiverName, String type) async {
    final signalingService = CallSignalingService();
    final callerName = FirebaseAuth.instance.currentUser?.email?.split('@')[0] ?? 'Me';

    try {
      final result = await Navigator.of(context).push<Map<String, dynamic>>(
        MaterialPageRoute(
          builder: (_) => type == 'video'
              ? VideoCallScreen(contactName: receiverName, receiverId: receiverId, callerName: callerName, isCaller: true, signalingService: signalingService)
              : AudioCallScreen(contactName: receiverName, receiverId: receiverId, callerName: callerName, isCaller: true, signalingService: signalingService),
        ),
      );

      if (context.mounted) {
        final chatService = Provider.of<ChatService>(context, listen: false);
        await chatService.logCallMessage(receiverId, type, result?['status'] as String? ?? 'no_answer', result?['duration'] as int? ?? 0);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not start call: $e')));
      }
    }
  }

  void _scheduleCall(BuildContext context) {
    final chatService = Provider.of<ChatService>(context, listen: false);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
      builder: (sheetContext) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: StreamBuilder<List<Map<String, dynamic>>>(
            stream: chatService.getUsersStream(),
            builder: (context, snapshot) {
              if (snapshot.hasError) return const Center(child: Text('Error loading contacts'));
              if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
              final users = snapshot.data ?? [];
              if (users.isEmpty) return const Center(child: Text('No contacts found'));

              return ListView.builder(
                itemCount: users.length,
                itemBuilder: (context, index) {
                  final user = users[index];
                  final email = user['email'] ?? 'User';
                  final name = email.contains('@') ? email.split('@')[0] : email;

                  return ListTile(
                    leading: CircleAvatar(backgroundColor: Colors.purple.shade100, child: Text(name[0].toUpperCase())),
                    title: Text(name),
                    subtitle: const Text('Schedule a call'),
                    onTap: () async {
                      final pickedDate = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime.now(),
                        lastDate: DateTime(2101),
                        builder: (context, child) => Theme(
                          data: Theme.of(context).copyWith(
                            colorScheme: const ColorScheme.light(primary: AppColors.mint, onPrimary: Colors.white, onSurface: Colors.black),
                          ),
                          child: child!,
                        ),
                      );
                      if (pickedDate == null || !context.mounted) return;

                      final pickedTime = await showTimePicker(context: context, initialTime: TimeOfDay.now());
                      if (pickedTime == null || !context.mounted) return;

                      final scheduledAt = DateTime(pickedDate.year, pickedDate.month, pickedDate.day, pickedTime.hour, pickedTime.minute);
                      await chatService.scheduleCall(user['uid'], name, scheduledAt);

                      if (context.mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Call scheduled for $name at ${pickedTime.format(context)}'), backgroundColor: AppColors.mint),
                        );
                      }
                    },
                  );
                },
              );
            },
          ),
        );
      },
    );
  }

  Widget _callLogItem(BuildContext context, String name, String receiverId, String details, IconData statusIcon, Color statusColor, Color avatarColor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          CircleAvatar(radius: 25, backgroundColor: avatarColor, child: Text(name[0], style: const TextStyle(fontWeight: FontWeight.bold))),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(statusIcon, size: 14, color: statusColor),
                    const SizedBox(width: 5),
                    Text(details, style: const TextStyle(fontSize: 12, color: Colors.black54)),
                  ],
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.call_outlined, color: Colors.black54),
            onSelected: (type) => _placeCall(context, receiverId, name, type),
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'audio', child: Row(children: [Icon(Icons.call, size: 18), SizedBox(width: 8), Text('Audio call')])),
              PopupMenuItem(value: 'video', child: Row(children: [Icon(Icons.videocam, size: 18), SizedBox(width: 8), Text('Video call')])),
            ],
          ),
        ],
      ),
    );
  }
}
