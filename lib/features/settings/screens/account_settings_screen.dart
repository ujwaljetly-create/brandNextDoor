import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../models/user_model.dart';
import '../../../services/user_service.dart';
import '../../brand/services/brand_service.dart';

class AccountSettingsScreen extends StatefulWidget {
  final String role;
  const AccountSettingsScreen({super.key, required this.role});

  @override
  State<AccountSettingsScreen> createState() => _AccountSettingsScreenState();
}

class _AccountSettingsScreenState extends State<AccountSettingsScreen> {
  static const _navy = Color(0xFF0C2430);
  static const _cream = Color(0xFFF8F3EA);

  final _nameController = TextEditingController();
  bool _isLoading = true;
  bool _isSaving = false;
  bool _hasCompletedSellerAccount = false;
  UserModel? _appUser;

  User? get _firebaseUser => FirebaseAuth.instance.currentUser;
  bool get _isSellerView => widget.role.toLowerCase() == 'seller';

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
      _appUser = await UserService().getUser(user.uid);
      _nameController.text = _appUser?.name ?? user.displayName ?? '';

      // A seller account is considered completed only when BOTH the seller
      // role and a generated/saved brand exist. This also protects users that
      // received a stale seller role from the previous onboarding flow.
      if (_appUser?.isSeller == true) {
        final brand = await BrandService().getSellerBrand();
        _hasCompletedSellerAccount = brand != null;
      } else {
        _hasCompletedSellerAccount = false;
      }
    } catch (_) {
      _hasCompletedSellerAccount = false;
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveName() async {
    final user = _firebaseUser;
    final name = _nameController.text.trim();
    if (user == null || name.isEmpty) {
      _message('Please enter your name.');
      return;
    }

    setState(() => _isSaving = true);
    try {
      await UserService().updateName(uid: user.uid, name: name);
      await user.updateDisplayName(name);
      if (mounted) _message('Name updated successfully.');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _openSellerAccount() async {
    if (!_hasCompletedSellerAccount) {
      // Do not mutate roles here. Merely viewing seller onboarding must not
      // convert a buyer into a seller.
      await context.push('/seller-onboarding');
      if (mounted) await _loadUser();
      return;
    }

    if (mounted) context.go('/seller-dashboard');
  }

  Future<void> _sendPasswordReset() async {
    final email = _firebaseUser?.email;
    if (email == null || email.isEmpty) return;
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      if (mounted) _message('Password reset email sent to $email.');
    } on FirebaseAuthException catch (e) {
      if (mounted) _message(e.message ?? 'Unable to send password reset email.');
    }
  }

  Future<void> _signOut() async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Sign out?'),
        content: const Text('You will need to sign in again to access your account.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
    if (yes != true) return;
    await FirebaseAuth.instance.signOut();
    if (mounted) context.go('/welcome');
  }

  void _message(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return _isSellerView ? _sellerSettings() : _buyerSettings();
  }

  Widget _sellerSettings() => Scaffold(
        backgroundColor: _cream,
        appBar: AppBar(
          backgroundColor: _cream,
          surfaceTintColor: _cream,
          elevation: 0,
          title: const Text(
            'Seller Profile',
            style: TextStyle(
              color: _navy,
              fontFamily: 'serif',
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 30),
          children: [
            _profileHeader('Seller'),
            const SizedBox(height: 20),
            _item(Icons.shopping_bag_outlined, 'Shop on Brand Next Door', () => context.go('/buyer-home')),
            _item(Icons.storefront_outlined, 'Business Information', () => context.push('/seller-brand')),
            _item(Icons.inventory_2_outlined, 'Manage Products', () => context.push('/my-listings')),
            _item(Icons.people_outline, 'Followers', () => context.push('/seller-followers')),
            _item(Icons.lock_reset, 'Reset Password', _sendPasswordReset),
            const SizedBox(height: 14),
            _signOutTile(),
          ],
        ),
      );

  Widget _buyerSettings() => Scaffold(
        backgroundColor: _cream,
        appBar: AppBar(
          backgroundColor: _cream,
          surfaceTintColor: _cream,
          elevation: 0,
          title: const Text(
            'Profile',
            style: TextStyle(
              color: _navy,
              fontFamily: 'serif',
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 30),
          children: [
            _profileHeader('Buyer'),
            const SizedBox(height: 20),
            _item(Icons.receipt_long_outlined, 'My Orders', () => context.push('/buyer-orders')),
            _item(Icons.favorite_border, 'Saved Items', () => context.push('/saved-items')),
            _item(Icons.star_border, 'My Reviews', () => context.push('/buyer-orders')),
            _item(Icons.location_on_outlined, 'My Addresses', () => _message('Address management is coming next.')),
            _item(Icons.credit_card_outlined, 'Payment Methods', () => _message('Payment methods will be available with checkout integration.')),
            _item(
              Icons.storefront_outlined,
              _hasCompletedSellerAccount
                  ? 'Go to Seller Account'
                  : 'Sell on Brand Next Door',
              _openSellerAccount,
            ),
            _item(Icons.lock_reset, 'Reset Password', _sendPasswordReset),
            const SizedBox(height: 14),
            _signOutTile(),
          ],
        ),
        bottomNavigationBar: NavigationBar(
          backgroundColor: Colors.white,
          selectedIndex: 3,
          onDestinationSelected: (i) {
            if (i == 0) context.go('/buyer-home');
            if (i == 1) context.push('/marketplace');
            if (i == 2) context.push('/messages?role=buyer');
          },
          destinations: const [
            NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Home'),
            NavigationDestination(icon: Icon(Icons.search), label: 'Explore'),
            NavigationDestination(icon: Icon(Icons.chat_bubble_outline), label: 'Messages'),
            NavigationDestination(icon: Icon(Icons.person), label: 'Profile'),
          ],
        ),
      );

  Widget _profileHeader(String fallback) {
    final name = _nameController.text.trim().isEmpty
        ? fallback
        : _nameController.text.trim();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE6DED2)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 34,
            backgroundColor: const Color(0xFFE6D3B5),
            child: Text(
              name[0].toUpperCase(),
              style: const TextStyle(
                color: _navy,
                fontSize: 24,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    color: _navy,
                    fontFamily: 'serif',
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  _firebaseUser?.email ?? '',
                  style: const TextStyle(
                    color: Color(0xFF7A858B),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: _editName,
            icon: const Icon(Icons.edit_outlined, color: _navy),
          ),
        ],
      ),
    );
  }

  Future<void> _editName() async {
    final controller = TextEditingController(text: _nameController.text);
    final value = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: _cream,
        surfaceTintColor: _cream,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Edit name',
          style: TextStyle(color: _navy, fontFamily: 'serif', fontWeight: FontWeight.w700),
        ),
        content: TextField(
          controller: controller,
          style: const TextStyle(color: _navy),
          decoration: InputDecoration(
            labelText: 'Name',
            filled: true,
            fillColor: Colors.white,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE6DED2)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFC99245), width: 1.5),
            ),
          ),
        ),
        actions: [
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              foregroundColor: _navy,
              side: const BorderSide(color: Color(0xFFC99245)),
            ),
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFC99245),
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(dialogContext, controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (value == null || value.isEmpty) return;
    _nameController.text = value;
    await _saveName();
    if (mounted) setState(() {});
  }

  Widget _item(IconData icon, String title, VoidCallback onTap) => Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE6DED2)),
        ),
        child: ListTile(
          leading: Icon(icon, color: _navy),
          title: Text(
            title,
            style: const TextStyle(color: _navy, fontWeight: FontWeight.w600),
          ),
          trailing: const Icon(Icons.chevron_right, color: Color(0xFF8C969B)),
          onTap: onTap,
        ),
      );

  Widget _signOutTile() => ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        tileColor: Colors.white,
        leading: const Icon(Icons.logout, color: Colors.red),
        title: const Text(
          'Sign Out',
          style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600),
        ),
        onTap: _signOut,
      );
}
