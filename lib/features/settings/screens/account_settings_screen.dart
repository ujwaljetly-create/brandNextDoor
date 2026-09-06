import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../models/user_model.dart';
import '../../../services/user_service.dart';

class AccountSettingsScreen extends StatefulWidget {
  final String role;

  const AccountSettingsScreen({
    super.key,
    required this.role,
  });

  @override
  State<AccountSettingsScreen> createState() =>
      _AccountSettingsScreenState();
}

class _AccountSettingsScreenState
    extends State<AccountSettingsScreen> {
  final _nameController = TextEditingController();

  bool _isLoading = true;
  bool _isSaving = false;
  UserModel? _appUser;

  User? get _firebaseUser => FirebaseAuth.instance.currentUser;
  bool get _isSeller => widget.role.toLowerCase() == 'seller';

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _loadUser() async {
    final user = _firebaseUser;

    if (user == null) {
      if (mounted) context.go('/welcome');
      return;
    }

    try {
      final appUser = await UserService().getUser(user.uid);
      if (!mounted) return;
      _appUser = appUser;
      _nameController.text = appUser?.name ?? user.displayName ?? '';
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _saveName() async {
    final user = _firebaseUser;
    final name = _nameController.text.trim();

    if (user == null || name.isEmpty) {
      _showMessage('Please enter your name.');
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      await UserService().updateName(uid: user.uid, name: name);
      await user.updateDisplayName(name);

      if (!mounted) return;
      _showMessage('Name updated successfully.');
      await _loadUser();
    } catch (_) {
      if (!mounted) return;
      _showMessage('Unable to update your name.');
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<void> _sendPasswordReset() async {
    final email = _firebaseUser?.email;

    if (email == null || email.isEmpty) {
      _showMessage('No email address is associated with this account.');
      return;
    }

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      if (!mounted) return;
      _showMessage('Password reset email sent to $email.');
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      _showMessage(
        e.message ?? 'Unable to send password reset email.',
      );
    }
  }

  Future<void> _signOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Sign out?'),
          content: const Text(
            'You will need to sign in again to access your account.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Sign Out'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    context.go('/welcome');
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final user = _firebaseUser;
    final email = user?.email ?? _appUser?.email ?? '';
    final roles = _appUser?.roles ?? <String>[widget.role];

    return Scaffold(
      appBar: AppBar(
        title: Text(_isSeller ? 'Seller Settings' : 'Buyer Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'Account',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _nameController,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Name',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    initialValue: email,
                    enabled: false,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Account type: ${roles.map((role) => role[0].toUpperCase() + role.substring(1)).join(', ')}',
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isSaving ? null : _saveName,
                      icon: _isSaving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.save_outlined),
                      label: Text(_isSaving ? 'Saving...' : 'Save Changes'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Security',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              leading: const Icon(Icons.lock_reset),
              title: const Text('Reset Password'),
              subtitle: const Text(
                'Send a password reset link to your email.',
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: _sendPasswordReset,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            _isSeller ? 'Seller Tools' : 'Buyer Tools',
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Card(
            child: Column(
              children: [
                if (_isSeller) ...[
                  ListTile(
                    leading: const Icon(Icons.storefront_outlined),
                    title: const Text('My Brand'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push('/seller-brand'),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.inventory_2_outlined),
                    title: const Text('My Listings'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push('/my-listings'),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.receipt_long_outlined),
                    title: const Text('Received Orders'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push('/seller-orders'),
                  ),
                ] else ...[
                  ListTile(
                    leading: const Icon(Icons.shopping_bag_outlined),
                    title: const Text('My Orders'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push('/buyer-orders'),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.store_mall_directory_outlined),
                    title: const Text('Marketplace'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push('/marketplace'),
                  ),
                ],
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.chat_bubble_outline),
                  title: const Text('Messages'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/messages'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          OutlinedButton.icon(
            onPressed: _signOut,
            icon: const Icon(Icons.logout),
            label: const Text('Sign Out'),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
