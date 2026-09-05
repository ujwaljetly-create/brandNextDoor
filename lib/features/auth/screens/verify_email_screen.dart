import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class VerifyEmailScreen extends StatefulWidget {
  const VerifyEmailScreen({super.key});

  @override
  State<VerifyEmailScreen> createState() =>
      _VerifyEmailScreenState();
}

class _VerifyEmailScreenState
    extends State<VerifyEmailScreen> {
  bool isLoading = false;

  Future<void> checkVerification() async {
    try {
      setState(() {
        isLoading = true;
      });

      await FirebaseAuth.instance.currentUser
          ?.reload();

      final user =
          FirebaseAuth.instance.currentUser;

      if (user != null &&
          user.emailVerified) {
        if (!mounted) return;

        context.go('/');
      } else {
        ScaffoldMessenger.of(context)
            .showSnackBar(
          const SnackBar(
            content: Text(
              'Email not verified yet.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> resendEmail() async {
    try {
      await FirebaseAuth.instance.currentUser
          ?.sendEmailVerification();

      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Verification email sent.',
          ),
        ),
      );
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
  Widget build(
      BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Verify Email',
        ),
      ),
      body: Padding(
        padding:
            const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 40),

            const Icon(
              Icons.mark_email_read,
              size: 100,
            ),

            const SizedBox(height: 30),

            const Text(
              'Verify Your Email',
              style: TextStyle(
                fontSize: 28,
                fontWeight:
                    FontWeight.bold,
              ),
            ),

            const SizedBox(height: 20),

            const Text(
              'We have sent a verification link to your email address. Verify your email and then tap Continue.',
              textAlign:
                  TextAlign.center,
            ),

            const SizedBox(height: 40),

            SizedBox(
              width:
                  double.infinity,
              child:
                  ElevatedButton(
                onPressed:
                    isLoading
                        ? null
                        : checkVerification,
                child:
                    isLoading
                        ? const CircularProgressIndicator()
                        : const Text(
                            'Continue',
                          ),
              ),
            ),

            const SizedBox(height: 12),

            SizedBox(
              width:
                  double.infinity,
              child:
                  OutlinedButton(
                onPressed:
                    resendEmail,
                child: const Text(
                  'Resend Email',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}