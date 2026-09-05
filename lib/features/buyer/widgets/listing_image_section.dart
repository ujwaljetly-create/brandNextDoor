import 'package:flutter/material.dart';

class ListingImageSection extends StatefulWidget {
  final List<String> images;

  const ListingImageSection({
    super.key,
    required this.images,
  });

  @override
  State<ListingImageSection> createState() =>
      _ListingImageSectionState();
}

class _ListingImageSectionState
    extends State<ListingImageSection> {
  int currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    if (widget.images.isEmpty) {
      return Container(
        height: 260,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius:
              BorderRadius.circular(20),
        ),
        child: const Center(
          child: Icon(
            Icons.image_outlined,
            size: 80,
            color: Colors.grey,
          ),
        ),
      );
    }

    return Column(
      children: [

        ClipRRect(
          borderRadius:
              BorderRadius.circular(20),
          child: AspectRatio(
            aspectRatio: 1.2,
            child: PageView.builder(
              itemCount:
                  widget.images.length,
              onPageChanged: (index) {
                setState(() {
                  currentIndex = index;
                });
              },
              itemBuilder:
                  (context, index) {
                return Image.network(
                  widget.images[index],
                  fit: BoxFit.cover,
                  errorBuilder:
                      (_, __, ___) {
                    return Container(
                      color: Colors
                          .grey.shade300,
                      child: const Center(
                        child: Icon(
                          Icons
                              .broken_image,
                          size: 60,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ),

        if (widget.images.length > 1)
          Padding(
            padding:
                const EdgeInsets.only(
              top: 12,
            ),
            child: Row(
              mainAxisAlignment:
                  MainAxisAlignment
                      .center,
              children: List.generate(
                widget.images.length,
                (index) {
                  return AnimatedContainer(
                    duration:
                        const Duration(
                      milliseconds: 250,
                    ),
                    margin:
                        const EdgeInsets
                            .symmetric(
                      horizontal: 4,
                    ),
                    height: 8,
                    width:
                        currentIndex ==
                                index
                            ? 24
                            : 8,
                    decoration:
                        BoxDecoration(
                      color:
                          currentIndex ==
                                  index
                              ? Theme.of(
                                      context)
                                  .colorScheme
                                  .primary
                              : Colors.grey,
                      borderRadius:
                          BorderRadius
                              .circular(
                        20,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
      ],
    );
  }
}