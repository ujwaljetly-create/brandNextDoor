import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../services/user_service.dart';

class SellerOnboardingScreen extends StatefulWidget {
  const SellerOnboardingScreen({super.key});

  @override
  State<SellerOnboardingScreen> createState() => _SellerOnboardingScreenState();
}

class _SellerOnboardingScreenState extends State<SellerOnboardingScreen> {
  static const _navy = Color(0xFF0C2430);
  static const _gold = Color(0xFFC99245);
  static const _cream = Color(0xFFF8F3EA);
  bool _creating = false;

  void _goBack() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/settings?role=buyer');
    }
  }

  Future<void> _createSellerAccount() async {
    if (_creating) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      context.go('/welcome');
      return;
    }

    setState(() => _creating = true);
    try {
      await UserService().addRole(uid: user.uid, role: 'seller');
      if (!mounted) return;
      context.go('/ai-brand-builder');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not create seller account: $e')),
      );
      setState(() => _creating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: context.canPop(),
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) context.go('/settings?role=buyer');
      },
      child: Scaffold(
        backgroundColor: _cream,
        appBar: AppBar(
          backgroundColor: _cream,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: _navy),
            onPressed: _goBack,
          ),
        ),
        body: SafeArea(
          top: false,
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Join a community\nthat values\nlocal brands.',
                        style: TextStyle(
                          color: _navy,
                          fontSize: 35,
                          height: 1.05,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'serif',
                        ),
                      ),
                      const SizedBox(height: 28),
                      const _Benefit(icon: Icons.shopping_bag_outlined, text: 'List your products easily'),
                      const _Benefit(icon: Icons.location_on_outlined, text: 'Reach nearby customers'),
                      const _Benefit(icon: Icons.favorite_border, text: 'Build your brand presence'),
                      const _Benefit(icon: Icons.bar_chart_outlined, text: 'Track your performance'),
                      const SizedBox(height: 28),
                      Container(
                        height: 280,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(26),
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xFFF0DFC5), Color(0xFFD8B57C)],
                          ),
                        ),
                        child: Stack(
                          children: [
                            const Positioned(
                              left: 22,
                              top: 22,
                              child: Text(
                                'LOCAL\nBRANDS',
                                style: TextStyle(
                                  color: _navy,
                                  fontSize: 30,
                                  height: 1,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 3,
                                ),
                              ),
                            ),
                            Positioned(
                              right: 18,
                              bottom: 16,
                              child: Icon(
                                Icons.storefront_outlined,
                                size: 120,
                                color: _navy.withValues(alpha: 0.22),
                              ),
                            ),
                            const Positioned(
                              left: 22,
                              bottom: 24,
                              right: 120,
                              child: Text(
                                'Build something your neighbourhood can discover, trust and support.',
                                style: TextStyle(
                                  color: _navy,
                                  fontSize: 16,
                                  height: 1.4,
                                  fontWeight: FontWeight.w600,
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
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 22),
                child: SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: _gold,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: _creating ? null : _createSellerAccount,
                    child: _creating
                        ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('Create Seller Account', style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Benefit extends StatelessWidget {
  final IconData icon;
  final String text;
  const _Benefit({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          const SizedBox(width: 2),
          Icon(icon, color: _SellerOnboardingScreenState._navy, size: 24),
          const SizedBox(width: 14),
          Text(text, style: const TextStyle(color: _SellerOnboardingScreenState._navy, fontSize: 16, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
