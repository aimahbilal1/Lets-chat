import 'package:flutter/material.dart';
import '../../core/app_colors.dart';
import '../../widgets/bottom_nav.dart';
import '../chats/chats_screen.dart';
import '../updates/updates_screen.dart';

class CallsScreen extends StatelessWidget {
  const CallsScreen({super.key});

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.primaryGradient,
        ),
        child: SafeArea(
          child: Column(
            children: [

              const SizedBox(height: 20),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Calls",
                      style: TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Icon(Icons.person_add_alt_1)
                  ],
                ),
              ),

              const SizedBox(height: 24),

              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: 6,
                  itemBuilder: (_, index) {

                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.75),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Row(
                        children: [

                          CircleAvatar(
                            radius: 28,
                            backgroundColor: Colors.pink.shade200,
                          ),

                          const SizedBox(width: 14),

                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Julian Vance",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text("Outgoing • 10:24 AM")
                              ],
                            ),
                          ),

                          const Icon(Icons.call)
                        ],
                      ),
                    );
                  },
                ),
              ),

              const BottomNav(
  currentIndex: 0,
)
            ],
          ),
        ),
      ),
    );
  }
}