import 'package:flutter/material.dart';

import '../../brand/services/brand_service.dart';

class BrandInfoCard extends StatefulWidget {
  final String brandId;

  const BrandInfoCard({
    super.key,
    required this.brandId,
  });

  @override
  State<BrandInfoCard> createState() =>
      _BrandInfoCardState();
}

class _BrandInfoCardState
    extends State<BrandInfoCard> {

  bool isLoading = true;

  Map<String, dynamic>? brand;

  @override
  void initState() {
    super.initState();

    loadBrand();
  }

  Future<void> loadBrand() async {
    try {
      final result =
          await BrandService().getBrand(
        widget.brandId,
      );

      if (!mounted) return;

      setState(() {
        brand = result;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {

    if (isLoading) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Center(
            child:
                CircularProgressIndicator(),
          ),
        ),
      );
    }

    if (brand == null) {
      return const SizedBox();
    }

    final logoUrl =
        brand!['logoUrl'] ?? '';

    final rating =
        (brand!['rating'] ?? 0)
            .toDouble();

    final totalReviews =
        brand!['totalReviews'] ?? 0;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius:
            BorderRadius.circular(18),
      ),
      child: Padding(
        padding:
            const EdgeInsets.all(18),
        child: Row(
          children: [

            CircleAvatar(
              radius: 34,
              backgroundColor:
                  Colors.grey.shade200,
              backgroundImage:
                  logoUrl.isNotEmpty
                      ? NetworkImage(
                          logoUrl,
                        )
                      : null,
              child: logoUrl.isEmpty
                  ? const Icon(
                      Icons.store,
                      size: 34,
                    )
                  : null,
            ),

            const SizedBox(
              width: 18,
            ),

            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment
                        .start,
                children: [

                  Text(
                    brand!['brandName'] ??
                        '',
                    style:
                        const TextStyle(
                      fontSize: 20,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),

                  const SizedBox(
                    height: 6,
                  ),

                  if ((brand!['tagline'] ??
                          '')
                      .toString()
                      .isNotEmpty)
                    Text(
                      brand!['tagline'],
                      style:
                          TextStyle(
                        color: Colors
                            .grey
                            .shade600,
                      ),
                    ),

                  const SizedBox(
                    height: 10,
                  ),

                  Row(
                    children: [

                      const Icon(
                        Icons.star,
                        color:
                            Colors.amber,
                        size: 18,
                      ),

                      const SizedBox(
                        width: 4,
                      ),

                      Text(
                        rating
                            .toStringAsFixed(
                          1,
                        ),
                        style:
                            const TextStyle(
                          fontWeight:
                              FontWeight
                                  .bold,
                        ),
                      ),

                      const SizedBox(
                        width: 8,
                      ),

                      Text(
                        '($totalReviews reviews)',
                        style:
                            TextStyle(
                          color: Colors
                              .grey
                              .shade600,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(
                    height: 10,
                  ),

                  Container(
                    padding:
                        const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 5,
                    ),
                    decoration:
                        BoxDecoration(
                      color: Colors
                          .green
                          .withOpacity(
                        0.1,
                      ),
                      borderRadius:
                          BorderRadius.circular(
                        20,
                      ),
                    ),
                    child: const Text(
                      'AI Generated Brand',
                      style: TextStyle(
                        color:
                            Colors.green,
                        fontWeight:
                            FontWeight
                                .w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}