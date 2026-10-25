import 'package:flutter/material.dart';

/// Phase 1 shell. Meta OAuth and publishing are intentionally disabled until
/// app review, server-side token exchange and permission checks are ready.
class SocialStudioScreen extends StatefulWidget {
  const SocialStudioScreen({super.key});

  @override
  State<SocialStudioScreen> createState() => _SocialStudioScreenState();
}

class _SocialStudioScreenState extends State<SocialStudioScreen> {
  static const navy = Color(0xFF0C2430);
  static const gold = Color(0xFFC99245);
  static const cream = Color(0xFFF8F3EA);

  final _idea = TextEditingController();
  final _caption = TextEditingController();
  bool facebook = false;
  bool instagram = false;

  @override
  void dispose() {
    _idea.dispose();
    _caption.dispose();
    super.dispose();
  }

  void _notReady(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$feature will be available after secure Meta account integration.')),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: cream,
        appBar: AppBar(
          backgroundColor: cream,
          foregroundColor: navy,
          title: const Text('AI Social Studio', style: TextStyle(fontWeight: FontWeight.w800)),
        ),
        body: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Text('Grow your brand on social media',
                style: TextStyle(color: navy, fontSize: 23, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            const Text('Plan promotions, prepare captions, and eventually publish to your connected Facebook Page and Instagram professional account.',
                style: TextStyle(color: Color(0xFF65727A))),
            const SizedBox(height: 22),
            _section('Your social accounts', [
              _account('Facebook Page', Icons.facebook, facebook, () => _notReady('Facebook connection')),
              _account('Instagram professional', Icons.camera_alt_outlined, instagram, () => _notReady('Instagram connection')),
              const Padding(
                padding: EdgeInsets.all(12),
                child: Text('Accounts are not connected yet. No posts will be published from this screen.',
                    style: TextStyle(color: Color(0xFF65727A), fontSize: 12)),
              ),
            ]),
            const SizedBox(height: 20),
            _section('Post workspace', [
              const Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: Text('Start drafting a promotion. AI generation and publishing will be enabled after backend integration.',
                    style: TextStyle(color: Color(0xFF65727A))),
              ),
              TextField(
                controller: _idea,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'What would you like to promote?',
                  hintText: 'e.g. New handmade candles available this weekend',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () => _notReady('AI post generation'),
                icon: const Icon(Icons.auto_awesome),
                label: const Text('Generate with AI — coming soon'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _caption,
                maxLines: 5,
                decoration: const InputDecoration(
                  labelText: 'Caption draft',
                  hintText: 'Write your caption here',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: null,
                icon: const Icon(Icons.send_outlined),
                label: const Text('Publish — connect accounts first'),
              ),
              const SizedBox(height: 6),
              const Text('Drafts are not saved yet. Publishing is disabled until the Meta connection is verified.',
                  style: TextStyle(fontSize: 12, color: Color(0xFF65727A))),
            ]),
            const SizedBox(height: 20),
            _section('Engagement', [
              const ListTile(
                leading: Icon(Icons.insights_outlined, color: gold),
                title: Text('Likes, comments and insights'),
                subtitle: Text('Engagement data will appear after accounts are connected and permissions are approved.'),
              ),
            ]),
          ],
        ),
      );

  Widget _section(String title, List<Widget> children) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE6DED2)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text(title, style: const TextStyle(color: navy, fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 14),
          ...children,
        ]),
      );

  Widget _account(String title, IconData icon, bool connected, VoidCallback onTap) =>
      ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Icon(icon, color: navy),
        title: Text(title),
        subtitle: Text(connected ? 'Connected' : 'Not connected'),
        trailing: TextButton(onPressed: onTap, child: const Text('Connect')),
      );
}
