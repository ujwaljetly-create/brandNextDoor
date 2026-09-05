import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AccountTypeScreen extends StatelessWidget {
  const AccountTypeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Choose Account Type',
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 40),

            Card(
              child: ListTile(
                leading: const Icon(
                  Icons.shopping_bag,
                ),
                title: const Text(
                  'Buyer',
                ),
                subtitle: const Text(
                  'Shop local brands',
                ),
                onTap: () {
                  context.go(
                    '/register?role=buyer',
                  );
                },
              ),
            ),

            const SizedBox(height: 20),

            Card(
              child: ListTile(
                leading: const Icon(
                  Icons.store,
                ),
                title: const Text(
                  'Seller',
                ),
                subtitle: const Text(
                  'Create your brand',
                ),
                onTap: () {
                  context.go(
                    '/register?role=seller',
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}