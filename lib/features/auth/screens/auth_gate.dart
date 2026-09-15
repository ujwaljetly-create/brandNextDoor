import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../models/user_model.dart';
import '../../../services/user_service.dart';
import '../../buyer/screens/buyer_home_screen.dart';
import '../../onboarding/screens/welcome_screen.dart';
import '../../seller/screens/seller_dashboard_screen.dart';
import '../../seller/screens/seller_onboarding_screen.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const WelcomeScreen();

    return FutureBuilder<UserModel?>(
      future: UserService().getUser(user.uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        if (!snapshot.hasData || snapshot.data == null) {
          return const WelcomeScreen();
        }

        final appUser = snapshot.data!;
        final isBuyer = appUser.roles.contains('buyer');
        final isSeller = appUser.roles.contains('seller');

        if (!isSeller) return const BuyerHomeScreen();

        return FutureBuilder<QuerySnapshot<Map<String, dynamic>>>(
          future: FirebaseFirestore.instance
              .collection('brands')
              .where('sellerId', isEqualTo: appUser.uid)
              .limit(1)
              .get(),
          builder: (context, brandSnapshot) {
            if (brandSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(body: Center(child: CircularProgressIndicator()));
            }

            final hasBrand = brandSnapshot.data?.docs.isNotEmpty ?? false;

            // A seller account is not ready for the seller portal until its
            // first brand has been created.
            if (!hasBrand) return const SellerOnboardingScreen();

            // Dual-role users launch into shopping. They can enter their seller
            // portal from Profile > Go to Seller Account. Seller-only legacy
            // accounts continue to launch into the seller dashboard.
            if (isBuyer) return const BuyerHomeScreen();
            return const SellerDashboardScreen();
          },
        );
      },
    );
  }
}
