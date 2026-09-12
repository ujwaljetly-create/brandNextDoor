import 'package:flutter/material.dart';

class DashboardStatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final VoidCallback? onTap;
  final String? changeLabel;

  const DashboardStatCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    this.onTap,
    this.changeLabel,
  });

  @override
  Widget build(BuildContext context) {
    const navy = Color(0xFF0C2430);
    const gold = Color(0xFFC99245);

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE6DED2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3E7D4),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, color: gold, size: 19),
                  ),
                  const Spacer(),
                  if (onTap != null)
                    const Icon(Icons.chevron_right, color: Color(0xFF8B9398), size: 20),
                ],
              ),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: navy,
                  fontSize: 24,
                  height: 1,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF59666D),
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (changeLabel != null)
                Text(
                  changeLabel!,
                  style: const TextStyle(
                    color: Color(0xFF15936D),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
