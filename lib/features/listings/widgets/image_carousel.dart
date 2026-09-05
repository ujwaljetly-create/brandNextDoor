import 'package:flutter/material.dart';

class ImageCarousel extends StatefulWidget {
  final List<String> images;

  const ImageCarousel({
    super.key,
    required this.images,
  });

  @override
  State<ImageCarousel> createState() =>
      _ImageCarouselState();
}

class _ImageCarouselState
    extends State<ImageCarousel> {
  final PageController _controller =
      PageController();

  int currentPage = 0;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 320,
          child: PageView.builder(
            controller: _controller,
            itemCount: widget.images.length,
            onPageChanged: (index) {
              setState(() {
                currentPage = index;
              });
            },
            itemBuilder: (context, index) {
              return Image.network(
                widget.images[index],
                fit: BoxFit.cover,
              );
            },
          ),
        ),

        const SizedBox(height: 10),

        Row(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: List.generate(
            widget.images.length,
            (index) {
              return Container(
                margin:
                    const EdgeInsets.symmetric(
                  horizontal: 4,
                ),
                width: currentPage == index
                    ? 14
                    : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: currentPage == index
                      ? Colors.deepPurple
                      : Colors.grey,
                  borderRadius:
                      BorderRadius.circular(
                    20,
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}