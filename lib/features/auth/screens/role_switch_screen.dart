import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class RoleSwitchScreen
    extends StatelessWidget {
  const RoleSwitchScreen({
    super.key,
  });

  @override
  Widget build(
      BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:
            const Text('Choose Role'),
      ),
      body: Padding(
        padding:
            const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(
              height: 40,
            ),

            SizedBox(
              width:
                  double.infinity,
              child:
                  ElevatedButton(
                onPressed: () {
                  context.go(
                    '/buyer-home',
                  );
                },
                child:
                    const Text(
                  'Continue as Buyer',
                ),
              ),
            ),

            const SizedBox(
              height: 20,
            ),

            SizedBox(
              width:
                  double.infinity,
              child:
                  ElevatedButton(
                onPressed: () {
                  context.go(
                    '/seller-dashboard',
                  );
                },
                child:
                    const Text(
                  'Continue as Seller',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}