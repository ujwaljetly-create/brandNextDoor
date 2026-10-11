import 'package:flutter/material.dart';

/// Transparency labels describe how the current feature works, not a paid tier.
enum AiAssistanceLevel { fullAi, partialAi, manual }

class AiDisclosure extends StatelessWidget {
  final AiAssistanceLevel level;
  final String detail;
  final bool compact;

  const AiDisclosure({
    super.key,
    required this.level,
    required this.detail,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    const navy = Color(0xFF0C2430);
    const gold = Color(0xFFC99245);
    final title = switch (level) {
      AiAssistanceLevel.fullAi => 'Full AI',
      AiAssistanceLevel.partialAi => 'Partial AI',
      AiAssistanceLevel.manual => 'Manual',
    };
    final icon = switch (level) {
      AiAssistanceLevel.fullAi => Icons.auto_awesome,
      AiAssistanceLevel.partialAi => Icons.tune,
      AiAssistanceLevel.manual => Icons.edit_outlined,
    };
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(compact ? 11 : 14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFAF1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE8D6B8)),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, color: gold, size: 19),
        const SizedBox(width: 9),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(color: navy, fontWeight: FontWeight.w800, fontSize: 13)),
          const SizedBox(height: 3),
          Text(detail, style: const TextStyle(color: Color(0xFF5F6B71), fontSize: 12, height: 1.35)),
        ])),
      ]),
    );
  }
}
