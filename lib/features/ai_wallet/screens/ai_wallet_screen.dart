import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AiWalletScreen extends StatefulWidget {
  const AiWalletScreen({super.key});
  @override
  State<AiWalletScreen> createState() => _AiWalletScreenState();
}

class _AiWalletScreenState extends State<AiWalletScreen> {
  static const navy = Color(0xFF0C2430);
  static const gold = Color(0xFFC99245);
  static const cream = Color(0xFFF8F3EA);
  late Future<Map<String, dynamic>> wallet;

  @override
  void initState() {
    super.initState();
    refresh();
  }

  void refresh() {
    wallet = _load();
    if (mounted) setState(() {});
  }

  Future<Map<String, dynamic>> _load() async {
    if (FirebaseAuth.instance.currentUser == null) throw Exception('Sign in to view your wallet.');
    final result = await FirebaseFunctions.instance.httpsCallable('getAiWallet').call();
    return Map<String, dynamic>.from(result.data as Map);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: cream,
    appBar: AppBar(
      backgroundColor: cream,
      surfaceTintColor: cream,
      title: const Text('AI Credits', style: TextStyle(color: navy, fontWeight: FontWeight.w800)),
      actions: [IconButton(onPressed: refresh, icon: const Icon(Icons.refresh, color: navy))],
    ),
    body: FutureBuilder<Map<String, dynamic>>(
      future: wallet,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          if (snapshot.hasError) {
            return Center(child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text('Could not load AI wallet. Deploy the Cloud Functions and try again.\n\n${snapshot.error}', textAlign: TextAlign.center),
            ));
          }
          return const Center(child: CircularProgressIndicator(color: gold));
        }
        final data = snapshot.data!;
        final costs = Map<String, dynamic>.from(data['costs'] as Map? ?? {});
        final history = List<dynamic>.from(data['history'] as List? ?? []);
        const labels = {
          'brand_identity': 'Brand identity',
          'brand_name': 'Brand name',
          'brand_tagline': 'Tagline',
          'brand_description': 'Brand description',
          'color_hex': 'Custom color',
          'logo': 'AI logo',
          'listing': 'AI listing',
          'market_tips': 'Market tips',
          'welcome_trial': 'Welcome trial',
        };
        return ListView(padding: const EdgeInsets.all(20), children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(color: navy, borderRadius: BorderRadius.circular(24)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Row(children: [Icon(Icons.auto_awesome, color: gold), SizedBox(width: 9), Text('AVAILABLE AI CREDITS', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w700))]),
              const SizedBox(height: 14),
              Text('${data['balance'] ?? 0}', style: const TextStyle(color: Colors.white, fontSize: 48, fontWeight: FontWeight.w800)),
              const Text('Credits are usage units, not OpenAI tokens or cash.', style: TextStyle(color: Colors.white70)),
            ]),
          ),
          const SizedBox(height: 10),
          const Text('New accounts receive a one-time 30-credit introductory allowance. Each AI generation deducts the feature cost shown below. Failed generations are refunded.', style: TextStyle(color: Color(0xFF5F6B71), fontSize: 12, height: 1.4)),
          const SizedBox(height: 20),
          const Text('Feature credit costs', style: TextStyle(color: navy, fontSize: 19, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          ...costs.entries.map((e) => Card(
            color: Colors.white,
            child: ListTile(
              title: Text(labels[e.key] ?? e.key),
              trailing: Text('${e.value} credits', style: const TextStyle(color: navy, fontWeight: FontWeight.w700)),
            ),
          )),
          const SizedBox(height: 18),
          const Text('Recent activity', style: TextStyle(color: navy, fontSize: 19, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          if (history.isEmpty) const Padding(
            padding: EdgeInsets.all(12),
            child: Text('No credit activity yet.'),
          ),
          ...history.map((entry) {
            final item = Map<String, dynamic>.from(entry as Map);
            final status = (item['status'] ?? '').toString();
            return ListTile(
              leading: const Icon(Icons.receipt_long_outlined, color: gold),
              title: Text(labels[item['feature']] ?? (item['feature'] ?? 'AI usage').toString()),
              subtitle: Text(status == 'refunded' ? 'Credits refunded' : status),
              trailing: Text('${(item['delta'] as num? ?? 0) > 0 ? '+' : ''}${item['delta'] ?? 0}', style: const TextStyle(fontWeight: FontWeight.w700)),
            );
          }),
          const SizedBox(height: 20),
          const Text('Credit purchases are not available yet. Pricing and payments will be introduced in Phase 3.', style: TextStyle(color: Color(0xFF6A7478), fontSize: 12)),
        ]);
      },
    ),
  );
}
