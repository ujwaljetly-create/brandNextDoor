import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../../models/brand_model.dart';
import '../../../widgets/city_picker_sheet.dart';
import '../services/brand_service.dart';

class BrandProfileScreen extends StatefulWidget {
  const BrandProfileScreen({super.key});

  @override
  State<BrandProfileScreen> createState() => _BrandProfileScreenState();
}

class _BrandProfileScreenState extends State<BrandProfileScreen> {
  static const _navy = Color(0xFF0C2430);
  static const _gold = Color(0xFFC99245);
  static const _cream = Color(0xFFF8F3EA);

  final _formKey = GlobalKey<FormState>();
  final brandNameController = TextEditingController();
  final descriptionController = TextEditingController();
  final cityController = TextEditingController();

  bool deliveryAvailable = true;
  bool isLoading = false;

  Future<void> _chooseCity() async {
    final result = await CityPickerSheet.show(
      context,
      initialCity: cityController.text.trim(),
    );
    if (result != null) {
      cityController.text = result.city;
      if (mounted) setState(() {});
    }
  }

  Future<void> saveBrand() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      setState(() => isLoading = true);
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not logged in');

      final brand = BrandModel(
        brandId: const Uuid().v4(),
        sellerId: user.uid,
        brandName: brandNameController.text.trim(),
        description: descriptionController.text.trim(),
        logoUrl: '',
        bannerUrl: '',
        city: cityController.text.trim(),
        deliveryAvailable: deliveryAvailable,
        rating: 0,
        totalReviews: 0,
      );

      await BrandService().createBrand(brand);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Brand Created Successfully')),
      );
      context.go('/seller-dashboard');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  void dispose() {
    brandNameController.dispose();
    descriptionController.dispose();
    cityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _cream,
      appBar: AppBar(
        backgroundColor: _cream,
        title: const Text(
          'Create Brand',
          style: TextStyle(
            color: _navy,
            fontFamily: 'serif',
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: brandNameController,
                decoration: const InputDecoration(labelText: 'Brand Name'),
                validator: (value) =>
                    value == null || value.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: descriptionController,
                maxLines: 5,
                decoration: const InputDecoration(labelText: 'Brand Description'),
              ),
              const SizedBox(height: 20),
              InkWell(
                onTap: _chooseCity,
                borderRadius: BorderRadius.circular(14),
                child: IgnorePointer(
                  child: TextFormField(
                    controller: cityController,
                    decoration: const InputDecoration(
                      labelText: 'City',
                      hintText: 'Use GPS or search for a city',
                      prefixIcon: Icon(Icons.location_on_outlined),
                      suffixIcon: Icon(Icons.map_outlined),
                    ),
                    validator: (value) =>
                        value == null || value.trim().isEmpty ? 'Required' : null,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              SwitchListTile(
                value: deliveryAvailable,
                activeThumbColor: _gold,
                title: const Text('Delivery Available'),
                onChanged: (value) =>
                    setState(() => deliveryAvailable = value),
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: _gold,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: isLoading ? null : saveBrand,
                  child: isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Create Brand'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
