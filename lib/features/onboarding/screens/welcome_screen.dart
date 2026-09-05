import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/brand_logo.dart';
import '../../../core/widgets/gradient_button.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Spacer(),

              const BrandLogo(size: 140),

              const SizedBox(height: 24),

              const Text(
                "Brand Next Door",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 34,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 20),

              const Text(
                "Create Your Brand.\nSell Locally.\nGrow Everywhere.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 18,
                ),
              ),

              const Spacer(),

              GradientButton(
                text: "Get Started",
                onTap: () {
                  context.go('/account-type');
                },
              ),

              const SizedBox(height: 16),

              OutlinedButton(
                onPressed: () {
                  context.go('/login');
                },
                child: const Text("Continue as Buyer"),
              ),

              const SizedBox(height: 12),

              OutlinedButton(
                onPressed: () {
                  context.go('/login');
                },
                child: const Text("Continue as a Seller"),
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}