import 'package:flutter/material.dart';

import '../models/destination.dart';
import '../services/api_client.dart';
import '../state/app_controller.dart';

/// AI trip planner: collects travel preferences, asks the Gemini-backed
/// `/api/planner` endpoint for an itinerary, and suggests matching places.
class TripPlannerSheet extends StatefulWidget {
  const TripPlannerSheet({
    super.key,
    required this.controller,
    required this.onOpenDestination,
  });

  final AppController controller;
  final ValueChanged<Destination> onOpenDestination;

  static Future<void> show(
    BuildContext context, {
    required AppController controller,
    required ValueChanged<Destination> onOpenDestination,
  }) => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => TripPlannerSheet(
      controller: controller,
      onOpenDestination: onOpenDestination,
    ),
  );

  @override
  State<TripPlannerSheet> createState() => _TripPlannerSheetState();
}

class _TripPlannerSheetState extends State<TripPlannerSheet> {
  static const _origins = [
    'Dhaka',
    'Chattogram',
    'Rajshahi',
    'Khulna',
    'Sylhet',
    'Barishal',
    'Rangpur',
    'Mymensingh',
  ];
  static const _budgets = ['Any', 'Low', 'Mid', 'High'];

  final _notes = TextEditingController();
  int _days = 3;
  int _travelers = 2;
  String _budget = 'Any';
  String _origin = 'Dhaka';
  final Set<String> _interests = {};
  String? _plan;
  String? _error;
  bool _loading = false;

  @override
  void dispose() {
    _notes.dispose();
    super.dispose();
  }

  List<String> get _categories {
    final values =
        widget.controller.destinations
            .map((destination) => destination.category.trim())
            .where((value) => value.isNotEmpty)
            .toSet()
            .toList()
          ..sort();
    return values;
  }

  List<Destination> get _suggestions {
    final matches = widget.controller.destinations.where((destination) {
      final matchesInterest =
          _interests.isEmpty || _interests.contains(destination.category);
      final matchesBudget =
          _budget == 'Any' ||
          destination.budget.toLowerCase() == _budget.toLowerCase();
      return matchesInterest && matchesBudget;
    }).toList();
    return matches.take(6).toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final suggestions = _plan == null ? const <Destination>[] : _suggestions;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          0,
          20,
          20 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height * .9,
          child: ListView(
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: scheme.primaryContainer,
                    child: Icon(
                      Icons.auto_awesome,
                      color: scheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'AI trip planner',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        Text(
                          'Tell us your preferences, get a day-by-day plan',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: scheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              _Stepper(
                label: 'Trip length (days)',
                value: _days,
                min: 1,
                max: 14,
                onChanged: (value) => setState(() => _days = value),
              ),
              _Stepper(
                label: 'Travelers',
                value: _travelers,
                min: 1,
                max: 20,
                onChanged: (value) => setState(() => _travelers = value),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: _origin,
                decoration: const InputDecoration(
                  labelText: 'Starting from',
                  prefixIcon: Icon(Icons.my_location_outlined),
                ),
                items: _origins
                    .map(
                      (origin) =>
                          DropdownMenuItem(value: origin, child: Text(origin)),
                    )
                    .toList(),
                onChanged: (value) =>
                    setState(() => _origin = value ?? _origin),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _budget,
                decoration: const InputDecoration(
                  labelText: 'Budget tier',
                  prefixIcon: Icon(Icons.savings_outlined),
                ),
                items: _budgets
                    .map(
                      (budget) =>
                          DropdownMenuItem(value: budget, child: Text(budget)),
                    )
                    .toList(),
                onChanged: (value) =>
                    setState(() => _budget = value ?? _budget),
              ),
              const SizedBox(height: 16),
              if (_categories.isNotEmpty) ...[
                Text('Interests', style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _categories
                      .map(
                        (category) => FilterChip(
                          label: Text(category),
                          selected: _interests.contains(category),
                          onSelected: (selected) => setState(() {
                            if (selected) {
                              _interests.add(category);
                            } else {
                              _interests.remove(category);
                            }
                          }),
                        ),
                      )
                    .toList(),
                ),
                const SizedBox(height: 16),
              ],
              TextField(
                controller: _notes,
                minLines: 2,
                maxLines: 3,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Anything else? (optional)',
                  hintText: 'e.g. travelling with kids, love seafood, avoid long drives',
                  prefixIcon: Icon(Icons.edit_note_outlined),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _loading ? null : _generate,
                  icon: _loading
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.auto_awesome),
                  label: Text(_loading ? 'Planning...' : 'Generate plan'),
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(
                  _error!,
                  style: TextStyle(color: scheme.error),
                ),
              ],
              if (_plan != null) ...[
                const SizedBox(height: 20),
                Text('Your itinerary', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                Card(
                  color: scheme.primaryContainer,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      _plan!,
                      style: TextStyle(
                        color: scheme.onPrimaryContainer,
                        height: 1.45,
                      ),
                    ),
                  ),
                ),
                if (suggestions.isNotEmpty) ...[
                  const SizedBox(height: 18),
                  Text(
                    'Suggested places',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  ...suggestions.map(
                    (destination) => Card(
                      child: ListTile(
                        leading: const Icon(Icons.place_outlined),
                        title: Text(destination.name),
                        subtitle: Text(
                          '${destination.location} · ${destination.budget} budget',
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => _open(destination),
                      ),
                    ),
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _generate() async {
    setState(() {
      _loading = true;
      _error = null;
      _plan = null;
    });
    try {
      final plan = await widget.controller.planTrip(
        days: _days,
        travelers: _travelers,
        budget: _budget == 'Any' ? 'Mid' : _budget,
        origin: _origin,
        interests: _interests.toList(),
        notes: _notes.text.trim(),
      );
      if (!mounted) return;
      setState(() => _plan = plan);
    } on ApiFailure catch (error) {
      if (mounted) setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _open(Destination destination) {
    Navigator.pop(context);
    widget.onOpenDestination(destination);
  }
}

class _Stepper extends StatelessWidget {
  const _Stepper({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  final String label;
  final int value;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      children: [
        Expanded(child: Text(label)),
        IconButton.outlined(
          tooltip: 'Decrease',
          onPressed: value > min ? () => onChanged(value - 1) : null,
          icon: const Icon(Icons.remove),
        ),
        SizedBox(
          width: 48,
          child: Text(
            '$value',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
        IconButton.outlined(
          tooltip: 'Increase',
          onPressed: value < max ? () => onChanged(value + 1) : null,
          icon: const Icon(Icons.add),
        ),
      ],
    ),
  );
}
