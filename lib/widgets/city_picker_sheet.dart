import 'dart:async';

import 'package:flutter/material.dart';

import '../services/location/city_location_service.dart';

class CityPickerSheet extends StatefulWidget {
  final String initialCity;

  const CityPickerSheet({
    super.key,
    this.initialCity = '',
  });

  static Future<CitySuggestion?> show(
    BuildContext context, {
    String initialCity = '',
  }) {
    return showModalBottomSheet<CitySuggestion>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => CityPickerSheet(initialCity: initialCity),
    );
  }

  @override
  State<CityPickerSheet> createState() => _CityPickerSheetState();
}

class _CityPickerSheetState extends State<CityPickerSheet> {
  static const _navy = Color(0xFF0C2430);
  static const _gold = Color(0xFFC99245);

  final _service = CityLocationService();
  late final TextEditingController _controller;
  Timer? _debounce;
  bool _loading = false;
  List<CitySuggestion> _suggestions = const [];

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialCity);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 450), () async {
      if (!mounted) return;
      setState(() => _loading = true);
      final results = await _service.searchCities(value);
      if (!mounted) return;
      setState(() {
        _suggestions = results;
        _loading = false;
      });
    });
  }

  Future<void> _useCurrentLocation() async {
    setState(() => _loading = true);
    final city = await _service.currentCity();
    if (!mounted) return;
    setState(() => _loading = false);
    if (city == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to determine your current city. Check location permissions and GPS.'),
        ),
      );
      return;
    }
    Navigator.pop(context, city);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          0,
          20,
          20 + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 520),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Choose your city',
                style: TextStyle(
                  color: _navy,
                  fontFamily: 'serif',
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Use GPS or start typing a city and select a matching location.',
                style: TextStyle(color: Color(0xFF6F7A80), fontSize: 12),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _loading ? null : _useCurrentLocation,
                  icon: const Icon(Icons.my_location),
                  label: const Text('Use current location'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _navy,
                    side: const BorderSide(color: _gold),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _controller,
                autofocus: false,
                textCapitalization: TextCapitalization.words,
                onChanged: _onChanged,
                decoration: InputDecoration(
                  hintText: 'Start typing a city...',
                  prefixIcon: const Icon(Icons.location_on_outlined),
                  suffixIcon: _loading
                      ? const Padding(
                          padding: EdgeInsets.all(14),
                          child: SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      : null,
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              if (_suggestions.isEmpty && _controller.text.trim().length >= 2 && !_loading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 18),
                  child: Center(child: Text('No matching cities found yet.')),
                )
              else
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: _suggestions.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (_, index) {
                      final suggestion = _suggestions[index];
                      return ListTile(
                        leading: const Icon(Icons.location_city_outlined, color: _navy),
                        title: Text(
                          suggestion.city,
                          style: const TextStyle(
                            color: _navy,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        subtitle: Text(
                          [suggestion.region, suggestion.country]
                              .where((e) => e.isNotEmpty)
                              .join(', '),
                        ),
                        onTap: () => Navigator.pop(context, suggestion),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
