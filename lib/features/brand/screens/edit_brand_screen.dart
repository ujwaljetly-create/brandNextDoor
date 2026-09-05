import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../services/brand_service.dart';

class EditBrandScreen extends StatefulWidget {
  final Map<String, dynamic> brand;

  const EditBrandScreen({
    super.key,
    required this.brand,
  });

  @override
  State<EditBrandScreen> createState() =>
      _EditBrandScreenState();
}

class _EditBrandScreenState
    extends State<EditBrandScreen> {

  late TextEditingController
      brandController;

  late TextEditingController
      taglineController;

  late TextEditingController
      descriptionController;

  bool isSaving = false;

  @override
  void initState() {
    super.initState();

    brandController =
        TextEditingController(
      text:
          widget.brand['brandName'],
    );

    taglineController =
        TextEditingController(
      text:
          widget.brand['tagline'],
    );

    descriptionController =
        TextEditingController(
      text:
          widget.brand['description'],
    );
  }

  Future<void> save() async {
    try {
      setState(() {
        isSaving = true;
      });

      await BrandService()
          .updateBrand(
        brandId:
            widget.brand['brandId'],
        brandName:
            brandController.text,
        tagline:
            taglineController.text,
        description:
            descriptionController.text,
      );

      if (!mounted) return;

      context.pop(true);

    } finally {
      if (mounted) {
        setState(() {
          isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(
      BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:
            const Text(
          'Edit Brand',
        ),
      ),
      body: Padding(
        padding:
            const EdgeInsets.all(24),
        child: Column(
          children: [

            TextField(
              controller:
                  brandController,
              style:
                  const TextStyle(
                color:
                    Colors.white,
              ),
              decoration:
                  InputDecoration(
                labelText:
                    'Brand Name',
                border:
                    OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(
                    16,
                  ),
                ),
              ),
            ),

            const SizedBox(
              height: 16,
            ),

            TextField(
              controller:
                  taglineController,
              style:
                  const TextStyle(
                color:
                    Colors.white,
              ),
              decoration:
                  InputDecoration(
                labelText:
                    'Tagline',
                border:
                    OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(
                    16,
                  ),
                ),
              ),
            ),

            const SizedBox(
              height: 16,
            ),

            TextField(
              controller:
                  descriptionController,
              maxLines: 5,
              style:
                  const TextStyle(
                color:
                    Colors.white,
              ),
              decoration:
                  InputDecoration(
                labelText:
                    'Description',
                border:
                    OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(
                    16,
                  ),
                ),
              ),
            ),

            const SizedBox(
              height: 24,
            ),

            SizedBox(
              width:
                  double.infinity,
              child:
                  ElevatedButton(
                onPressed:
                    isSaving
                        ? null
                        : save,
                child:
                    isSaving
                        ? const CircularProgressIndicator()
                        : const Text(
                            'Save Changes',
                          ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}