import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../features/auth/services/auth_service.dart';
class RegisterScreen extends StatefulWidget {
  final String role;

  const RegisterScreen({
    super.key,
    required this.role,
  });
  @override
  State<RegisterScreen> createState() =>
      _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
Future<void> registerUser() async {
  try {
    final credential =
        await AuthService().register(
      email:
          emailController.text.trim(),
      password:
          passwordController.text.trim(),
    );

    await credential.user!
        .updateDisplayName(
      nameController.text.trim(),
    );

    await credential.user!
        .sendEmailVerification();

    await FirebaseFirestore.instance
        .collection('users')
        .doc(credential.user!.uid)
        .set({
      'uid': credential.user!.uid,
      'name':
          nameController.text.trim(),
      'email':
          emailController.text.trim(),
      'roles': [widget.role],
      'createdAt':
          Timestamp.now(),
    });

    if (!mounted) return;

    context.go('/verify-email');
  } catch (e) {
    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(
          e.toString(),
        ),
      ),
    );
  }
}
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            TextField(
              controller: nameController,
              style: const TextStyle(
    color: Colors.white,
  ),
              decoration: InputDecoration(
                hintText: 'Full Name',
                hintStyle: const TextStyle(
      color: Colors.white54,
    ),border: OutlineInputBorder(
      borderRadius:
          BorderRadius.circular(12),
    ),
              ),
            ),

            const SizedBox(height: 16),

            TextField(
  controller: emailController,
  style: const TextStyle(
    color: Colors.white,
  ),
  decoration: InputDecoration(
    hintText: 'Email',
    hintStyle: const TextStyle(
      color: Colors.white54,
    ),
    border: OutlineInputBorder(
      borderRadius:
          BorderRadius.circular(12),
    ),
  ),
),

            const SizedBox(height: 16),

            TextField(
              controller: passwordController,
              style: const TextStyle(
    color: Colors.white,
  ),
              obscureText: true,
              decoration: InputDecoration(
                hintText: 'Password',
                 hintStyle: const TextStyle(
      color: Colors.white54,
    ),                border: OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(12),
                ),
              ),
            ),

            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: registerUser,
                child: const Text("Create Account"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}