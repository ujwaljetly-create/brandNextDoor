import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../../models/brand_model.dart';
import '../services/brand_service.dart';

class BrandProfileScreen
    extends StatefulWidget {
  const BrandProfileScreen({
    super.key,
  });

  @override
  State<BrandProfileScreen>
      createState() =>
          _BrandProfileScreenState();
}

class _BrandProfileScreenState
    extends State<BrandProfileScreen> {
  final _formKey =
      GlobalKey<FormState>();

  final brandNameController =
      TextEditingController();

  final descriptionController =
      TextEditingController();

  bool deliveryAvailable = true;

  bool isLoading = false;

  Future<void> saveBrand() async {
  if (!_formKey.currentState!.validate()) {
    return;
  }

  try {
    setState(() {
      isLoading = true;
    });

    final user =
        FirebaseAuth.instance.currentUser;

    if (user == null) {
      throw Exception(
        'User not logged in',
      );
    }

    final brand = BrandModel(
      brandId: const Uuid().v4(),
      sellerId: user.uid,
      brandName:
          brandNameController.text.trim(),
      description:
          descriptionController.text.trim(),
      logoUrl: '',
      bannerUrl: '',
      city: '',
      deliveryAvailable:
          deliveryAvailable,
      rating: 0,
      totalReviews: 0,
    );

    await BrandService()
        .createBrand(
      brand,
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context)
        .showSnackBar(
      const SnackBar(
        content: Text(
          'Brand Created Successfully',
        ),
      ),
    );

    context.go(
      '/seller-dashboard',
    );
  } catch (e) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content:
            Text(e.toString()),
      ),
    );
  } finally {
    if (mounted) {
      setState(() {
        isLoading = false;
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
          'Create Brand',
        ),
      ),
      body: SingleChildScrollView(
        padding:
            const EdgeInsets.all(
          24,
        ),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller:
                    brandNameController,
                decoration:
                    const InputDecoration(
                  labelText:
                      'Brand Name',
                ),
                validator:
                    (value) {
                  if (value == null ||
                      value
                          .isEmpty) {
                    return 'Required';
                  }

                  return null;
                },
              ),

              const SizedBox(
                height: 20,
              ),

              TextFormField(
                controller:
                    descriptionController,
                maxLines: 5,
                decoration:
                    const InputDecoration(
                  labelText:
                      'Brand Description',
                ),
              ),

              const SizedBox(
                height: 20,
              ),

              SwitchListTile(
                value:
                    deliveryAvailable,
                title: const Text(
                  'Delivery Available',
                ),
                onChanged:
                    (value) {
                  setState(() {
                    deliveryAvailable =
                        value;
                  });
                },
              ),

              const SizedBox(
                height: 30,
              ),

              SizedBox(
                width:
                    double.infinity,
                height: 55,
                child:
                    ElevatedButton(
                  onPressed:
                      isLoading
                          ? null
                          : saveBrand,
                  child:
                      isLoading
                          ? const CircularProgressIndicator()
                          : const Text(
                              'Create Brand',
                            ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}