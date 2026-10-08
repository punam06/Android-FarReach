import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/destination.dart';
import '../services/api_client.dart';

String dateOnly(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
String optionLabel(String value) => value.replaceAll('_', ' ');

class BudgetScreen extends StatefulWidget {
  const BudgetScreen({super.key, required this.api, required this.destination});
  final ApiClient api;
  final Destination destination;
  @override
  State<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetScreen> {
  Map<String, dynamic>? _pricing;
  Map<String, dynamic>? _estimate;
  String? _error;
  bool _busy = true;
  String _origin = 'Dhaka',
      _hotel = 'normal',
      _food = 'standard',
      _guide = 'none',
      _transport = 'bus_nonac';
  final _persons = TextEditingController(text: '1');
  final _days = TextEditingController(text: '1');
  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _persons.dispose();
    _days.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final pricing = await widget.api.requestJson('/api/pricing');
      if (mounted) setState(() => _pricing = pricing);
    } on ApiFailure catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _calculate() async {
    setState(() {
      _busy = true;
      _error = null;
      _estimate = null;
    });
    try {
      final result = await widget.api.requestJson(
        '/api/budget/estimate',
        method: 'POST',
        body: {
          'spot_id': widget.destination.id,
          'origin': _origin,
          'persons': int.tryParse(_persons.text),
          'days': int.tryParse(_days.text),
          'hotel_tier': _hotel,
          'food_tier': _food,
          'guide_tier': _guide,
          'transport_mode': _transport,
        },
      );
      if (mounted) {
        setState(
          () =>
              _estimate = Map<String, dynamic>.from(result['estimate'] as Map),
        );
      }
    } on ApiFailure catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Widget _select(
    String label,
    String value,
    Iterable<dynamic> options,
    ValueChanged<String> change,
  ) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: DropdownButtonFormField<String>(
      initialValue: value,
      isExpanded: true,
      decoration: InputDecoration(labelText: label),
      items: options
          .map(
            (v) =>
                DropdownMenuItem(value: '$v', child: Text(optionLabel('$v'))),
          )
          .toList(),
      onChanged: _busy
          ? null
          : (v) {
              if (v != null) {
                setState(() {
                  change(v);
                  _estimate = null;
                });
              }
            },
    ),
  );
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Budget calculator')),
    body: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          widget.destination.name,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 12),
        const Text(
          'Planning estimates in BDT. One day means zero lodging nights. Package reservations have a separate price.',
        ),
        const SizedBox(height: 18),
        if (_pricing != null) ...[
          _select(
            'Origin district',
            _origin,
            _pricing!['districts'] as List,
            (v) => _origin = v,
          ),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _persons,
                  enabled: !_busy,
                  keyboardType: TextInputType.number,
                  onChanged: (_) => setState(() => _estimate = null),
                  decoration: const InputDecoration(
                    labelText: 'Travelers (1–20)',
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _days,
                  enabled: !_busy,
                  keyboardType: TextInputType.number,
                  onChanged: (_) => setState(() => _estimate = null),
                  decoration: const InputDecoration(labelText: 'Days (1–30)'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _select(
            'Accommodation',
            _hotel,
            (_pricing!['hotel_tiers'] as Map).keys,
            (v) => _hotel = v,
          ),
          _select(
            'Food',
            _food,
            (_pricing!['food_tiers'] as Map).keys,
            (v) => _food = v,
          ),
          _select(
            'Guide',
            _guide,
            (_pricing!['guide_tiers'] as Map).keys,
            (v) => _guide = v,
          ),
          _select(
            'Transport',
            _transport,
            _pricing!['transport_modes'] as List,
            (v) => _transport = v,
          ),
          FilledButton(
            onPressed: _busy ? null : _calculate,
            child: const Text('Calculate budget'),
          ),
        ] else if (!_busy)
          OutlinedButton(onPressed: _load, child: const Text('Retry')),
        if (_busy)
          const Padding(
            padding: EdgeInsets.all(20),
            child: Center(child: CircularProgressIndicator()),
          ),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              _error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        if (_estimate != null) ...[
          const SizedBox(height: 18),
          Card(
            child: Column(
              children: [
                ListTile(
                  title: const Text('Estimated trip total'),
                  trailing: Text('৳${_estimate!['total']}'),
                ),
                ListTile(
                  title: const Text('Per traveler'),
                  trailing: Text('৳${_estimate!['per_person']}'),
                ),
                ...(_estimate!['breakdown'] as Map).entries.map(
                  (e) => ListTile(
                    title: Text(optionLabel('${e.key}')),
                    trailing: Text('৳${e.value}'),
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${_estimate!['nights']} night(s) · ${_estimate!['distance_km']} km estimated route distance',
          ),
          const SizedBox(height: 10),
          Text('${_estimate!['note']}'),
        ],
      ],
    ),
  );
}

class StaysScreen extends StatefulWidget {
  const StaysScreen({super.key, required this.api, required this.destination});
  final ApiClient api;
  final Destination destination;
  @override
  State<StaysScreen> createState() => _StaysScreenState();
}

class _StaysScreenState extends State<StaysScreen> {
  DateTime _in = DateTime.now().add(const Duration(days: 1));
  DateTime _out = DateTime.now().add(const Duration(days: 2));
  final _persons = TextEditingController(text: '1');
  final _maxPrice = TextEditingController();
  List<dynamic> _stays = [];
  bool _busy = false;
  String? _error;
  @override
  void initState() {
    super.initState();
    _search();
  }

  @override
  void dispose() {
    _persons.dispose();
    _maxPrice.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    setState(() {
      _busy = true;
      _error = null;
      _stays = [];
    });
    try {
      final data = await widget.api.requestJson(
        '/api/hotels/search',
        method: 'POST',
        body: {
          'city': widget.destination.district,
          'destinationName': widget.destination.name,
          'category': widget.destination.category,
          'checkin': dateOnly(_in),
          'checkout': dateOnly(_out),
          'persons': int.tryParse(_persons.text),
          if (_maxPrice.text.isNotEmpty)
            'max_price': int.tryParse(_maxPrice.text),
        },
      );
      if (mounted) setState(() => _stays = data['hotels'] as List);
    } on ApiFailure catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _pick(bool checkIn) async {
    final value = await showDatePicker(
      context: context,
      initialDate: checkIn ? _in : _out,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (value == null || !mounted) return;
    setState(() {
      if (checkIn) {
        _in = value;
        if (!_out.isAfter(_in)) _out = _in.add(const Duration(days: 1));
      } else {
        _out = value;
      }
      _stays = [];
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Suggested stays')),
    body: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          widget.destination.name,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        const Text(
          'Catalog estimates per room per night. Availability and rates must be confirmed with the property.',
        ),
        const SizedBox(height: 12),
        OutlinedButton(
          onPressed: _busy ? null : () => _pick(true),
          child: Text('Check in: ${dateOnly(_in)}'),
        ),
        OutlinedButton(
          onPressed: _busy ? null : () => _pick(false),
          child: Text('Check out: ${dateOnly(_out)}'),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _persons,
          enabled: !_busy,
          keyboardType: TextInputType.number,
          onChanged: (_) => setState(() => _stays = []),
          decoration: const InputDecoration(labelText: 'Travelers (1–20)'),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _maxPrice,
          enabled: !_busy,
          keyboardType: TextInputType.number,
          onChanged: (_) => setState(() => _stays = []),
          decoration: const InputDecoration(
            labelText: 'Maximum nightly price (BDT, optional)',
          ),
        ),
        const SizedBox(height: 12),
        FilledButton(
          onPressed: _busy ? null : _search,
          child: const Text('Search stays'),
        ),
        if (_busy)
          const Padding(
            padding: EdgeInsets.all(20),
            child: Center(child: CircularProgressIndicator()),
          ),
        if (_error != null)
          Text(
            _error!,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        if (!_busy && _stays.isEmpty && _error == null)
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text('Search to see stays matching your filters.'),
          ),
        ..._stays.map((item) {
          final stay = Map<String, dynamic>.from(item as Map);
          return Card(
            child: ListTile(
              title: Text('${stay['name']}'),
              subtitle: Text(
                '৳${stay['price']} / room / night\n${stay['rooms']} room(s) × ${stay['nights']} night(s): ৳${stay['total_estimate']}\nAvailability: check with property',
              ),
              isThreeLine: true,
              trailing: IconButton(
                icon: const Icon(Icons.open_in_new),
                tooltip: 'Property website',
                onPressed: () async {
                  final uri = Uri.tryParse('${stay['url']}');
                  try {
                    if (uri == null ||
                        uri.scheme != 'https' ||
                        !uri.hasAuthority ||
                        !await launchUrl(
                          uri,
                          mode: LaunchMode.externalApplication,
                        )) {
                      throw const ApiFailure(
                        'Could not open property website.',
                      );
                    }
                  } catch (_) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Could not open property website.'),
                        ),
                      );
                    }
                  }
                },
              ),
            ),
          );
        }),
      ],
    ),
  );
}
