import 'package:flutter/material.dart';
import '../../core/app_colors.dart';
import '../../widgets/bottom_nav.dart';
import '../calls/calls_screen.dart';
import '../chats/chats_screen.dart';

class UpdatesScreen extends StatelessWidget {
  const UpdatesScreen({super.key});

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.primaryGradient,
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [

                Row(
                  children: const [
                    Text(
                      "Updates",
                      style: TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(26),
                  ),
                  child: Row(
                    children: [

                      CircleAvatar(
                        radius: 28,
                        backgroundColor: Colors.orange.shade200,
                      ),

                      const SizedBox(width: 14),

                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "My Status",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 6),
                            Text("Tap to add update")
                          ],
                        ),
                      ),

                      CircleAvatar(
                        radius: 12,
                        backgroundColor: Colors.green,
                        child: const Icon(
                          Icons.add,
                          size: 14,
                          color: Colors.white,
                        ),
                      )
                    ],
                  ),
                ),

                const SizedBox(height: 30),

                Expanded(
                  child: ListView.builder(
                    itemCount: 5,
                    itemBuilder: (_, index) {

                      return Container(
                        margin: const EdgeInsets.only(bottom: 14),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.75),
                          borderRadius: BorderRadius.circular(22),
                        ),
                        child: Row(
                          children: [

                            CircleAvatar(
                              radius: 28,
                              backgroundColor: Colors.purple.shade200,
                            ),

                            const SizedBox(width: 14),

                            const Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Leo",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text("Coffee at the new gallery space...")
                                ],
                              ),
                            ),

                            Text(
                              "10:45",
                              style: TextStyle(
                                color: Colors.grey.shade500,
                              ),
                            )
                          ],
                        ),
                      );
                    },
                  ),
                ),

                const BottomNav(
  currentIndex: 1,
)
              ],
            ),
          ),
        ),
      ),
    );
  }
}