import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../models/user_model.dart';
import '../../../services/user_service.dart';

class AccountSettingsScreen extends StatefulWidget {
  final String role;

  const AccountSettingsScreen({super.key, required this.role});

  @override
  State<AccountSettingsScreen> createState() => _AccountSettingsScreenState();
}

class _AccountSettingsScreenState extends State<AccountSettingsScreen> {
  static const _navy = Color(0xFF0C2430);
  static const _gold = Color(0xFFC99245);
  static const _cream = Color(0xFFF8F3EA);

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
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveName() async {
    final user = _firebaseUser;
    final name = _nameController.text.trim();
    if (user == null || name.isEmpty) return _showMessage('Please enter your name.');
    setState(() => _isSaving = true);
    try {
      await UserService().updateName(uid: user.uid, name: name);
      await user.updateDisplayName(name);
      if (!mounted) return;
      _showMessage('Name updated successfully.');
      await _loadUser();
    } catch (_) {
      if (mounted) _showMessage('Unable to update your name.');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _sendPasswordReset() async {
    final email = _firebaseUser?.email;
    if (email == null || email.isEmpty) return _showMessage('No email address is associated with this account.');
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      if (mounted) _showMessage('Password reset email sent to $email.');
    } on FirebaseAuthException catch (e) {
      if (mounted) _showMessage(e.message ?? 'Unable to send password reset email.');
    }
  }

  Future<void> _signOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Sign out?'),
        content: const Text('You will need to sign in again to access your account.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Sign Out')),
        ],
      ),
    );
    if (confirmed != true) return;
    await FirebaseAuth.instance.signOut();
    if (mounted) context.go('/welcome');
  }

  void _showMessage(String message) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (!_isSeller) return _buyerSettings();

    return Scaffold(
      backgroundColor: _cream,
      appBar: AppBar(
        backgroundColor: _cream,
        elevation: 0,
        leading: IconButton(
          onPressed: () => context.canPop() ? context.pop() : context.go('/seller-dashboard'),
          icon: const Icon(Icons.arrow_back, color: _navy),
        ),
        title: const Text('Settings', style: TextStyle(color: _navy, fontFamily: 'serif', fontWeight: FontWeight.w700)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 30),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFE6DED2))),
            child: Column(
              children: [
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Seller Name', prefixIcon: Icon(Icons.person_outline)),
                ),
                const SizedBox(height: 10),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.email_outlined, color: _navy),
                  title: Text(_firebaseUser?.email ?? _appUser?.email ?? ''),
                  subtitle: const Text('Account email'),
                ),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    style: FilledButton.styleFrom(backgroundColor: _gold, foregroundColor: Colors.white),
                    onPressed: _isSaving ? null : _saveName,
                    child: Text(_isSaving ? 'Saving...' : 'Save Name'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          _setting(Icons.storefront_outlined, 'Business Information', () => context.push('/seller-brand')),
          _setting(Icons.inventory_2_outlined, 'Manage Products', () => context.push('/my-listings')),
          _setting(Icons.receipt_long_outlined, 'Received Orders', () => context.push('/seller-orders')),
          _setting(Icons.local_shipping_outlined, 'Pickup & Delivery Options', () => context.push('/seller-brand')),
          _setting(Icons.notifications_none, 'Notifications', () => _showMessage('Order notifications are enabled for this account.')),
          _setting(Icons.lock_reset, 'Reset Password', _sendPasswordReset),
          _setting(Icons.chat_bubble_outline, 'Messages', () => context.push('/messages')),
          _setting(Icons.help_outline, 'Help & Support', () => _showMessage('Help & Support is coming next.')),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red,
              side: const BorderSide(color: Color(0xFFE8CACA)),
              minimumSize: const Size.fromHeight(52),
            ),
            onPressed: _signOut,
            icon: const Icon(Icons.logout),
            label: const Text('Log Out'),
          ),
        ],
      ),
    );
  }

  Widget _setting(IconData icon, String title, VoidCallback onTap) => Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFFE6DED2))),
        child: ListTile(
          leading: Icon(icon, color: _navy),
          title: Text(title, style: const TextStyle(color: _navy, fontWeight: FontWeight.w600)),
          trailing: const Icon(Icons.chevron_right, color: Color(0xFF8C969B)),
          onTap: onTap,
        ),
      );

  Widget _buyerSettings() {
    final name = _nameController.text.trim().isEmpty ? 'Buyer' : _nameController.text.trim();
    final email = _firebaseUser?.email ?? _appUser?.email ?? '';

    return Scaffold(
      backgroundColor: _cream,
      appBar: AppBar(
        backgroundColor: _cream,
        elevation: 0,
        title: const Text('Profile', style: TextStyle(color: _navy, fontFamily: 'serif', fontWeight: FontWeight.w700)),
        actions: [
          IconButton(
            onPressed: _saveName,
            icon: const Icon(Icons.settings_outlined, color: _navy),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 30),
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 38,
                backgroundColor: const Color(0xFFE6D3B5),
                child: Text(
                  name.isNotEmpty ? name[0].toUpperCase() : 'B',
                  style: const TextStyle(color: _navy, fontFamily: 'serif', fontSize: 26, fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: const TextStyle(color: _navy, fontFamily: 'serif', fontSize: 23, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Text(email, style: const TextStyle(color: Color(0xFF7A858B), fontSize: 12)),
                  ],
                ),
              ),
              IconButton(
                onPressed: _editBuyerName,
                icon: const Icon(Icons.edit_outlined, color: _navy),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buyerItem(Icons.receipt_long_outlined, 'My Orders', () => context.push('/buyer-orders')),
          _buyerItem(Icons.favorite_border, 'Saved Items', () => context.push('/saved-items')),
          _buyerItem(Icons.star_border, 'My Reviews', () => context.push('/buyer-orders')),
          _buyerItem(Icons.location_on_outlined, 'My Addresses', () => _showMessage('Address management is coming next.')),
          _buyerItem(Icons.credit_card_outlined, 'Payment Methods', () => _showMessage('Payment methods will be available with checkout integration.')),
          _buyerItem(Icons.storefront_outlined, 'Sell on Brand Next Door', () => context.push('/account-type')),
          _buyerItem(Icons.lock_reset, 'Reset Password', _sendPasswordReset),
          _buyerItem(Icons.help_outline, 'Help & Support', () => _showMessage('Help & Support is coming next.')),
          const SizedBox(height: 14),
          ListTile(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            tileColor: Colors.white,
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Sign Out', style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600)),
            onTap: _signOut,
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        backgroundColor: Colors.white,
        selectedIndex: 3,
        onDestinationSelected: (index) {
          if (index == 0) context.go('/buyer-home');
          if (index == 1) context.push('/marketplace');
          if (index == 2) context.push('/buyer-orders');
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.search), label: 'Explore'),
          NavigationDestination(icon: Icon(Icons.receipt_long_outlined), label: 'Orders'),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }

  Future<void> _editBuyerName() async {
    final controller = TextEditingController(text: _nameController.text);
    final value = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Edit name'),
        content: TextField(controller: controller, decoration: const InputDecoration(labelText: 'Name')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(dialogContext, controller.text.trim()), child: const Text('Save')),
        ],
      ),
    );
    controller.dispose();
    if (value == null || value.isEmpty) return;
    _nameController.text = value;
    await _saveName();
  }

  Widget _buyerItem(IconData icon, String title, VoidCallback onTap) => Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE6DED2)),
        ),
        child: ListTile(
          leading: Icon(icon, color: _navy),
          title: Text(title, style: const TextStyle(color: _navy, fontWeight: FontWeight.w600)),
          trailing: const Icon(Icons.chevron_right, color: Color(0xFF8C969B)),
          onTap: onTap,
        ),
      );
}
