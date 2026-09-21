import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AccountTypeScreen extends StatelessWidget {
  const AccountTypeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/welcome');
            }
          },
        ),
        title: const Text('Choose Account Type'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 24),
          Card(
            child: ListTile(
              contentPadding: const EdgeInsets.all(18),
              leading: const Icon(Icons.shopping_bag, size: 34),
              title: const Text(
                'Buyer',
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: const Text('Discover and shop local brands'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                context.push('/register?role=buyer');
              },
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: ListTile(
              contentPadding: const EdgeInsets.all(18),
              leading: const Icon(Icons.store, size: 34),
              title: const Text(
                'Seller',
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: const Text('Create a brand and sell locally'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                context.push('/register?role=seller');
              },
            ),
          ),
        ],
      ),
    );
  }
}
