import 'package:flutter/material.dart';

class BrandStatusCard extends StatelessWidget {
  final bool brandExists;

  final String brandName;

  final String tagline;

  final String? logoUrl;

  final int completion;

  final VoidCallback onPressed;

  const BrandStatusCard({
    super.key,
    required this.brandExists,
    required this.brandName,
    required this.tagline,
    required this.logoUrl,
    required this.completion,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(
        20,
      ),
      decoration: BoxDecoration(
        borderRadius:
            BorderRadius.circular(
          24,
        ),
        gradient:
            const LinearGradient(
          colors: [
            Color(0xFF7B61FF),
            Color(0xFFE14DAD),
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [

          if (brandExists &&
              logoUrl != null &&
              logoUrl!.isNotEmpty)
            Center(
              child: Container(
                height: 90,
                width: 90,
                margin:
                    const EdgeInsets.only(
                  bottom: 16,
                ),
                child: ClipRRect(
                  borderRadius:
                      BorderRadius.circular(
                    20,
                  ),
                  child:
                      Image.network(
                    logoUrl!,
                    fit:
                        BoxFit.cover,
                  ),
                ),
              ),
            ),

          Text(
            brandExists
                ? brandName
                : 'Create Your Brand',
            style:
                const TextStyle(
              color:
                  Colors.white,
              fontSize: 24,
              fontWeight:
                  FontWeight.bold,
            ),
          ),

          const SizedBox(
            height: 8,
          ),

          Text(
            brandExists
                ? tagline
                : 'Build your brand using AI and start selling.',
            style:
                const TextStyle(
              color:
                  Colors.white70,
            ),
          ),

          const SizedBox(
            height: 20,
          ),

          if (brandExists) ...[
            Row(
              children: [
                const Text(
                  'Brand Completion',
                  style: TextStyle(
                    color:
                        Colors.white,
                  ),
                ),
                const Spacer(),
                Text(
                  '$completion%',
                  style:
                      const TextStyle(
                    color:
                        Colors.white,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
              ],
            ),

            const SizedBox(
              height: 10,
            ),

            ClipRRect(
              borderRadius:
                  BorderRadius.circular(
                20,
              ),
              child:
                  LinearProgressIndicator(
                value:
                    completion /
                        100,
                minHeight: 8,
              ),
            ),

            const SizedBox(
              height: 20,
            ),
          ],

          SizedBox(
            width:
                double.infinity,
            child:
                ElevatedButton(
              onPressed:
                  onPressed,
              child: Text(
                brandExists
                    ? 'Manage Brand'
                    : 'Create Brand',
              ),
            ),
          ),
        ],
      ),
    );
  }
}