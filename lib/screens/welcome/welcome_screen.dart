import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import '../../core/app_colors.dart';
import '../../widgets/feature_card.dart';
import '../../widgets/gradient_button.dart';
import '../auth/login_screen.dart';
import '../auth/signup_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.primaryGradient,
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 20,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: MediaQuery.of(context).size.height - 60,
                ),
                child: IntrinsicHeight(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 20),
                      const Text(
                        "CONNECT EFFORTLESSLY",
                        style: TextStyle(
                          letterSpacing: 2,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        "Welcome to Let's Chat",
                        style: TextStyle(
                          fontSize: 38,
                          fontWeight: FontWeight.bold,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        "Experience the next evolution of digital intimacy in our serene, ethereal community.",
                        style: TextStyle(
                          color: Colors.black.withOpacity(0.6),
                          fontSize: 16,
                          height: 1.7,
                        ),
                      ),
                      const SizedBox(height: 30),
                      Row(
                        children: [
                          const CircleAvatar(
                            radius: 24,
                            backgroundColor: Colors.orange,
                          ),
                          Transform.translate(
                            offset: const Offset(-12, 0),
                            child: const CircleAvatar(
                              radius: 24,
                              backgroundColor: Colors.green,
                            ),
                          ),
                          Transform.translate(
                            offset: const Offset(-24, 0),
                            child: const CircleAvatar(
                              radius: 24,
                              backgroundColor: Colors.pink,
                            ),
                          ),
                          Transform.translate(
                            offset: const Offset(-36, 0),
                            child: Container(
                              height: 48,
                              width: 48,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: Colors.green.shade200,
                                shape: BoxShape.circle,
                              ),
                              child: const Text("+10k"),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: const Text(
                          "10k+ people joined today",
                        ),
                      ),
                      const SizedBox(height: 30),
                      const FeatureCard(
                        icon: Icons.auto_awesome,
                        title: "Pure Serenity",
                        subtitle: "An interface designed for focus and tranquility.",
                      ),
                      const FeatureCard(
                        icon: Icons.shield_outlined,
                        title: "Safe Space",
                        subtitle: "Encrypted, private conversations with total control.",
                      ),
                      const Spacer(),
                      GradientButton(
                        key: const ValueKey('get_started_button'),
                        text: "Get Started",
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const SignupScreen(),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 18),
                      Center(
                        child: RichText(
                          text: TextSpan(
                            text: "Already have an account? ",
                            style: const TextStyle(
                              color: Colors.black54,
                            ),
                            children: [
                              TextSpan(
                                text: "Log In",
                                style: const TextStyle(
                                  color: Colors.green,
                                  fontWeight: FontWeight.bold,
                                ),
                                recognizer: TapGestureRecognizer()
                                  ..onTap = () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => const LoginScreen(),
                                      ),
                                    );
                                  },
                              )
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 25),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}