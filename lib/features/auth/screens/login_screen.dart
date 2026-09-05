import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() =>
      _LoginScreenState();
}

class _LoginScreenState
    extends State<LoginScreen> {
  final emailController =
      TextEditingController();

  final passwordController =
      TextEditingController();

  bool isLoading = false;

  Future<void> loginUser() async {
    try {
      setState(() {
        isLoading = true;
      });

      await AuthService().signIn(
        email:
            emailController.text.trim(),
        password:
            passwordController.text.trim(),
      );

      if (!mounted) return;

      context.go('/');
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            e.toString(),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(
      BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Login',
        ),
      ),
      body: Padding(
        padding:
            const EdgeInsets.all(24),
        child: Column(
          children: [
            TextField(
              controller:
                  emailController,
              style:
                  const TextStyle(
                color: Colors.white,
              ),
              decoration:
                  InputDecoration(
                hintText: 'Email',
                hintStyle:
                    const TextStyle(
                  color:
                      Colors.white54,
                ),
                border:
                    OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(
                    12,
                  ),
                ),
              ),
            ),

            const SizedBox(
                height: 16),

            TextField(
              controller:
                  passwordController,
              obscureText: true,
              style:
                  const TextStyle(
                color: Colors.white,
              ),
              decoration:
                  InputDecoration(
                hintText:
                    'Password',
                hintStyle:
                    const TextStyle(
                  color:
                      Colors.white54,
                ),
                border:
                    OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(
                    12,
                  ),
                ),
              ),
            ),

            const SizedBox(
                height: 24),

            SizedBox(
              width:
                  double.infinity,
              child:
                  ElevatedButton(
                onPressed:
                    isLoading
                        ? null
                        : loginUser,
                child:
                    isLoading
                        ? const CircularProgressIndicator()
                        : const Text(
                            "Login",
                          ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}