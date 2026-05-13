import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../core/app_colors.dart';
import '../../core/services/chat_service.dart';
import '../../widgets/bottom_nav.dart';
import '../chats/chats_screen.dart';
import '../community/community_screen.dart';
import '../settings/settings_detail_screen.dart';
import '../chats/new_message_screen.dart';
import '../updates/updates_screen.dart';

class CallsScreen extends StatelessWidget {
  const CallsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final chatService = Provider.of<ChatService>(context);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Calls",
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.search),
                          onPressed: () {},
                        ),
                        PopupMenuButton<String>(
                          icon: const Icon(Icons.more_vert),
                          onSelected: (value) async {
                            if (value == 'Clear call log') {
                              await chatService.clearCallLog();
                            } else if (value == 'Schedule calls') {
                              _scheduleCall(context);
                            }
                          },
                          itemBuilder: (BuildContext context) {
                            return ['Clear call log', 'Schedule calls'].map((
                              String choice,
                            ) {
                              return PopupMenuItem<String>(
                                value: choice,
                                child: Text(choice),
                              );
                            }).toList();
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Call Control Bar
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _controlIcon(context, Icons.call_outlined, "Call"),
                    _controlIcon(
                      context,
                      Icons.calendar_month_outlined,
                      "Schedule",
                    ),
                    _controlIcon(context, Icons.dialpad_outlined, "Keypad"),
                    _controlIcon(context, Icons.star_outline, "Favourite"),
                  ],
                ),
              ),

              const SizedBox(height: 10),

              // Call Log List
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: chatService.getCallLogs(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      debugPrint(
                        '[CallsScreen] call log stream error: ${snapshot.error}',
                      );
                    }
                    return ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      children: [
                        // New Call Option
                        ListTile(
                          leading: const CircleAvatar(
                            backgroundColor: AppColors.mint,
                            child: Icon(Icons.add_call, color: Colors.white),
                          ),
                          title: const Text(
                            "New call",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: const Text("Select a contact to call"),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const NewMessageScreen(),
                              ),
                            );
                          },
                        ),
                        const Divider(),
                        StreamBuilder<QuerySnapshot>(
                          stream: chatService.getScheduledCalls(),
                          builder: (context, scheduledSnapshot) {
                            if (scheduledSnapshot.hasData &&
                                scheduledSnapshot.data!.docs.isNotEmpty) {
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 10),
                                  const Text(
                                    "Scheduled Calls",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black54,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  ...scheduledSnapshot.data!.docs.map((doc) {
                                    final data =
                                        doc.data() as Map<String, dynamic>;
                                    final name =
                                        data['receiverName'] ?? 'User';
                                    final scheduledAt =
                                        (data['scheduledAt'] as Timestamp?)
                                            ?.toDate();
                                    final time = scheduledAt != null
                                        ? '${scheduledAt.day}/${scheduledAt.month}/${scheduledAt.year} ${scheduledAt.hour.toString().padLeft(2, '0')}:${scheduledAt.minute.toString().padLeft(2, '0')}'
                                        : 'Scheduled';

                                    return _callLogItem(
                                      context,
                                      name,
                                      data['receiverId'] ?? '',
                                      'scheduled • $time',
                                      Icons.schedule,
                                      Colors.purple,
                                      Colors.purple.shade100,
                                    );
                                  }),
                                  const Divider(),
                                ],
                              );
                            }
                            return const SizedBox.shrink();
                          },
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          "Recent Calls",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.black54,
                          ),
                        ),
                        const SizedBox(height: 10),

                        if (snapshot.hasError)
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.all(20.0),
                              child: Text("Error: ${snapshot.error}"),
                            ),
                          ),
                        if (snapshot.connectionState == ConnectionState.waiting)
                          const Center(child: CircularProgressIndicator()),

                        if (snapshot.hasData && snapshot.data!.docs.isEmpty)
                          const Center(
                            child: Padding(
                              padding: EdgeInsets.only(top: 50),
                              child: Text("No recent calls"),
                            ),
                          ),

                        if (snapshot.hasData)
                          ...snapshot.data!.docs.map((doc) {
                            final data = doc.data() as Map<String, dynamic>;
                            final String name = data['receiverName'];
                            final String receiverId = data['receiverId'];
                            final String time =
                                (data['timestamp'] as Timestamp?)
                                    ?.toDate()
                                    .toString()
                                    .substring(11, 16) ??
                                "";
                            final String details = "${data['status']} • $time";
                            final IconData icon =
                                data['status'] == 'missed'
                                    ? Icons.call_missed
                                    : (data['status'] == 'outgoing'
                                        ? Icons.call_made
                                        : Icons.call_received);
                            final Color color =
                                data['status'] == 'missed'
                                    ? Colors.red
                                    : (data['status'] == 'outgoing'
                                        ? Colors.green
                                        : Colors.blue);

                            return _callLogItem(
                              context,
                              name,
                              receiverId,
                              details,
                              icon,
                              color,
                              Colors.pink.shade100,
                            );
                          }),
                      ],
                    );
                  },
                ),
              ),

              const BottomNav(currentIndex: 0),
            ],
          ),
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
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const NewMessageScreen()),
          );
        } else if (label == "Keypad") {
          _showKeypad(context);
        } else if (label == "Favourite") {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Filtering favourites...")),
          );
        }
      },
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.6),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.black87),
          ),
          const SizedBox(height: 5),
          Text(
            label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  void _showKeypad(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.7,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Dialer",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 15),
              Flexible(
                child: GridView.count(
                  shrinkWrap: true,
                  crossAxisCount: 3,
                  mainAxisSpacing: 5,
                  crossAxisSpacing: 10,
                  childAspectRatio: 1.5,
                  children:
                      [
                        "1",
                        "2",
                        "3",
                        "4",
                        "5",
                        "6",
                        "7",
                        "8",
                        "9",
                        "*",
                        "0",
                        "#",
                      ].map((key) {
                        return InkWell(
                          onTap: () {},
                          child: Container(
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              key,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
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
                    Navigator.pop(context);
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(const SnackBar(content: Text("Calling...")));
                  },
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  void _scheduleCall(BuildContext context) async {
    final chatService = Provider.of<ChatService>(context, listen: false);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: StreamBuilder<List<Map<String, dynamic>>>(
            stream: chatService.getUsersStream(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return const Center(child: Text('Error loading contacts'));
              }
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final users = snapshot.data ?? [];
              if (users.isEmpty) {
                return const Center(child: Text('No contacts found'));
              }

              return ListView.builder(
                itemCount: users.length,
                itemBuilder: (context, index) {
                  final user = users[index];
                  final String email = user['email'] ?? 'User';
                  final String name = email.contains('@')
                      ? email.split('@')[0]
                      : email;

                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.purple.shade100,
                      child: Text(name[0].toUpperCase()),
                    ),
                    title: Text(name),
                    subtitle: const Text('Schedule a call'),
                    onTap: () async {
                      final DateTime? pickedDate = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime.now(),
                        lastDate: DateTime(2101),
                        builder: (context, child) {
                          return Theme(
                            data: Theme.of(context).copyWith(
                              colorScheme: const ColorScheme.light(
                                primary: AppColors.mint,
                                onPrimary: Colors.white,
                                onSurface: Colors.black,
                              ),
                            ),
                            child: child!,
                          );
                        },
                      );

                      if (pickedDate == null || !context.mounted) return;
                      final TimeOfDay? pickedTime = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.now(),
                      );

                      if (pickedTime == null || !context.mounted) return;
                      final scheduledAt = DateTime(
                        pickedDate.year,
                        pickedDate.month,
                        pickedDate.day,
                        pickedTime.hour,
                        pickedTime.minute,
                      );

                      await chatService.scheduleCall(
                        user['uid'],
                        name,
                        scheduledAt,
                      );

                      if (context.mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Call scheduled for $name at ${pickedTime.format(context)}',
                            ),
                            backgroundColor: AppColors.mint,
                          ),
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

  Widget _callLogItem(
    BuildContext context,
    String name,
    String receiverId,
    String details,
    IconData statusIcon,
    Color statusColor,
    Color avatarColor,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.75),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 25,
            backgroundColor: avatarColor,
            child: Text(
              name[0],
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
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
                    Text(
                      details,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.call_outlined, color: Colors.black54),
            onPressed: () {
              final chatService = Provider.of<ChatService>(
                context,
                listen: false,
              );
              chatService.logCall(receiverId, name, 'voice');
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text("Calling $name...")));
            },
          ),
        ],
      ),
    );
  }
}
