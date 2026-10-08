import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/destination.dart';
import '../services/api_client.dart';
import '../state/app_controller.dart';
import '../widgets/destination_image.dart';
import 'travel_tools_screen.dart';

class DestinationDetailScreen extends StatefulWidget {
  const DestinationDetailScreen({
    super.key,
    required this.controller,
    required this.destination,
  });

  final AppController controller;
  final Destination destination;

  @override
  State<DestinationDetailScreen> createState() =>
      _DestinationDetailScreenState();
}

class _DestinationDetailScreenState extends State<DestinationDetailScreen> {
  late Future<WeatherInfo> _weather;

  @override
  void initState() {
    super.initState();
    _weather = widget.controller.weatherFor(widget.destination);
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: widget.controller,
    builder: (context, _) => Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 360,
            actions: [
              IconButton.filledTonal(
                tooltip: widget.controller.isSaved(widget.destination)
                    ? 'Remove from saved'
                    : 'Save destination',
                onPressed: _toggleSaved,
                icon: Icon(
                  widget.controller.isSaved(widget.destination)
                      ? Icons.favorite
                      : Icons.favorite_border,
                ),
              ),
              const SizedBox(width: 12),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Hero(
                    tag:
                        'destination-${widget.destination.id}-${widget.destination.name}',
                    child: DestinationImage(
                      destination: widget.destination,
                      baseUrl: widget.controller.api.baseUrl,
                    ),
                  ),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Color(0xD9001711)],
                        stops: [0.35, 1],
                      ),
                    ),
                  ),
                  Positioned(
                    left: 24,
                    right: 24,
                    bottom: 28,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _Label(text: widget.destination.category),
                        const SizedBox(height: 10),
                        Text(
                          widget.destination.name,
                          style: Theme.of(context).textTheme.displaySmall
                              ?.copyWith(color: Colors.white),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(
                              Icons.location_on_outlined,
                              color: Colors.white,
                              size: 20,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                widget.destination.location,
                                style: Theme.of(context).textTheme.bodyLarge
                                    ?.copyWith(color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 960),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 36),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _FactCard(
                              icon: Icons.payments_outlined,
                              label: 'Budget',
                              value: widget.destination.budget,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _FactCard(
                              icon: Icons.category_outlined,
                              label: 'Best for',
                              value: widget.destination.category,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _FactCard(
                              icon: Icons.route_outlined,
                              label: 'Area',
                              value: widget.destination.division.isEmpty
                                  ? 'Bangladesh'
                                  : widget.destination.division,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 30),
                      _Section(
                        title: 'Why go',
                        child: Text(
                          widget.destination.description.isEmpty
                              ? 'Discover local landscapes, culture, food, and stories at ${widget.destination.name}.'
                              : widget.destination.description,
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ),
                      if (widget.destination.history.isNotEmpty) ...[
                        const SizedBox(height: 26),
                        _Section(
                          title: 'Story of the place',
                          child: Text(
                            widget.destination.history,
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                        ),
                      ],
                      const SizedBox(height: 26),
                      _Section(
                        title: 'Plan with confidence',
                        child: _WeatherCard(
                          weather: _weather,
                          onRetry: () => setState(
                            () => _weather = widget.controller.weatherFor(
                              widget.destination,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 26),
                      _Section(
                        title: 'Useful next steps',
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final stack = constraints.maxWidth < 560;
                            final actions = [
                              OutlinedButton.icon(
                                onPressed: _openMap,
                                icon: const Icon(Icons.directions_outlined),
                                label: const Text('Open in Maps'),
                              ),
                              OutlinedButton.icon(
                                onPressed: _showHotels,
                                icon: const Icon(Icons.hotel_outlined),
                                label: const Text('Suggested stays'),
                              ),
                            ];
                            return stack
                                ? Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      actions.first,
                                      const SizedBox(height: 10),
                                      actions.last,
                                    ],
                                  )
                                : Row(
                                    children: [
                                      Expanded(child: actions.first),
                                      const SizedBox(width: 12),
                                      Expanded(child: actions.last),
                                    ],
                                  );
                          },
                        ),
                      ),
                      const SizedBox(height: 22),
                      OutlinedButton.icon(
                        onPressed: widget.destination.id <= 0
                            ? null
                            : () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => BudgetScreen(
                                    api: widget.controller.api,
                                    destination: widget.destination,
                                  ),
                                ),
                              ),
                        icon: const Icon(Icons.calculate_outlined),
                        label: const Text('Budget calculator'),
                      ),
                      const SizedBox(height: 12),
                      Card(
                        color: Theme.of(context).colorScheme.primaryContainer,
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.eco_outlined,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onPrimaryContainer,
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Travel gently',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.copyWith(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onPrimaryContainer,
                                          ),
                                    ),
                                    const SizedBox(height: 5),
                                    Text(
                                      'Respect local communities, carry reusable water, and leave natural places as you found them.',
                                      style: TextStyle(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onPrimaryContainer,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            border: Border(
              top: BorderSide(
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
            ),
          ),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Row(
            children: [
              IconButton.outlined(
                tooltip: widget.controller.isSaved(widget.destination)
                    ? 'Remove from saved'
                    : 'Save destination',
                onPressed: _toggleSaved,
                icon: Icon(
                  widget.controller.isSaved(widget.destination)
                      ? Icons.favorite
                      : Icons.favorite_border,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed: _showBooking,
                  icon: const Icon(Icons.calendar_month_outlined),
                  label: const Text('Plan & book trip'),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );

  Future<void> _toggleSaved() async {
    final adding = !widget.controller.isSaved(widget.destination);
    await widget.controller.toggleSaved(widget.destination);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(adding ? 'Saved for later.' : 'Removed from saved.'),
      ),
    );
  }

  Future<void> _openMap() async {
    final destination = widget.destination;
    final query = Uri.encodeComponent(
      '${destination.name}, ${destination.location}',
    );
    final uri = destination.hasCoordinates
        ? Uri.parse(
            'geo:${destination.latitude},${destination.longitude}?q=$query',
          )
        : Uri.parse('https://www.google.com/maps/search/?api=1&query=$query');
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication) &&
        mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No map application was available.')),
      );
    }
  }

  Future<void> _showHotels() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => StaysScreen(
          api: widget.controller.api,
          destination: widget.destination,
        ),
      ),
    );
  }

  Future<void> _showBooking() async {
    if (widget.destination.id <= 0) {
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          icon: const Icon(Icons.cloud_off_outlined),
          title: const Text('Connect before booking'),
          content: const Text(
            'This is an offline guide. Refresh the live destination catalog before confirming a booking.',
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Got it'),
            ),
          ],
        ),
      );
      return;
    }
    if (!widget.controller.isAuthenticated) {
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          icon: const Icon(Icons.lock_outline),
          title: const Text('Sign in to book'),
          content: const Text(
            'Open the Profile tab, sign in or create an account, then return to confirm your trip.',
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Got it'),
            ),
          ],
        ),
      );
      return;
    }
    final booking = await showModalBottomSheet<Booking>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => _BookingSheet(
        controller: widget.controller,
        destination: widget.destination,
      ),
    );
    if (booking != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Trip booked for ${booking.date}.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}

class _Label extends StatelessWidget {
  const _Label({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.92),
      borderRadius: BorderRadius.circular(99),
    ),
    child: Text(
      text,
      style: Theme.of(context).textTheme.labelMedium
          ?.copyWith(color: Colors.black87, fontWeight: FontWeight.w700),
    ),
  );
}

class _FactCard extends StatelessWidget {
  const _FactCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 16),
      child: Column(
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 9),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelLarge,
          ),
          const SizedBox(height: 2),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    ),
  );
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(title, style: Theme.of(context).textTheme.headlineMedium),
      const SizedBox(height: 12),
      child,
    ],
  );
}

class _WeatherCard extends StatelessWidget {
  const _WeatherCard({required this.weather, required this.onRetry});

  final Future<WeatherInfo> weather;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => FutureBuilder<WeatherInfo>(
    future: weather,
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const Card(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Row(
              children: [
                CircularProgressIndicator(),
                SizedBox(width: 18),
                Text('Checking local weather…'),
              ],
            ),
          ),
        );
      }
      if (snapshot.hasError) {
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                const Icon(Icons.cloud_off_outlined),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text('Weather is unavailable right now.'),
                ),
                TextButton(onPressed: onRetry, child: const Text('Retry')),
              ],
            ),
          ),
        );
      }
      final data = snapshot.requireData;
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Icon(
                Icons.wb_sunny_outlined,
                size: 48,
                color: Theme.of(context).colorScheme.tertiary,
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${data.temperature.round()}°C · ${_capitalize(data.description)}',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'Humidity ${data.humidity}%  •  Wind ${data.windKmh.round()} km/h',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

class _BookingSheet extends StatefulWidget {
  const _BookingSheet({required this.controller, required this.destination});

  final AppController controller;
  final Destination destination;

  @override
  State<_BookingSheet> createState() => _BookingSheetState();
}

class _BookingSheetState extends State<_BookingSheet> {
  DateTime? _date;
  int _persons = 1;
  bool _submitting = false;
  String? _error;

  Map<String, dynamic>? _quote;
  bool _quoteLoading = false;
  int _quoteGeneration = 0;

  Future<void> _refreshQuote() async {
    final generation = ++_quoteGeneration;
    setState(() {
      _quote = null;
      _error = null;
      _quoteLoading = _date != null;
    });
    if (_date == null) return;
    try {
      final data = await widget.controller.api.requestJson(
        '/api/bookings/quote',
        method: 'POST',
        body: {
          'spot_id': widget.destination.id,
          'persons': _persons,
          'booking_date': dateOnly(_date!),
        },
      );
      if (mounted && generation == _quoteGeneration) {
        setState(
          () => _quote = Map<String, dynamic>.from(data['quote'] as Map),
        );
      }
    } on ApiFailure catch (e) {
      if (mounted && generation == _quoteGeneration) {
        setState(() => _error = e.message);
      }
    } finally {
      if (mounted && generation == _quoteGeneration) {
        setState(() => _quoteLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) => SafeArea(
    child: Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        0,
        20,
        20 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Plan ${widget.destination.name}',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 6),
          const Text('Choose a future date and the number of travelers.'),
          const SizedBox(height: 22),
          OutlinedButton.icon(
            onPressed: _submitting ? null : _pickDate,
            icon: const Icon(Icons.calendar_today_outlined),
            label: Text(
              _date == null
                  ? 'Choose travel date'
                  : '${_date!.day}/${_date!.month}/${_date!.year}',
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              const Expanded(child: Text('Travelers')),
              IconButton.outlined(
                tooltip: 'Remove traveler',
                onPressed: !_submitting && _persons > 1
                    ? () {
                        setState(() => _persons--);
                        _refreshQuote();
                      }
                    : null,
                icon: const Icon(Icons.remove),
              ),
              SizedBox(
                width: 48,
                child: Text(
                  '$_persons',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              IconButton.outlined(
                tooltip: 'Add traveler',
                onPressed: !_submitting && _persons < 20
                    ? () {
                        setState(() => _persons++);
                        _refreshQuote();
                      }
                    : null,
                icon: const Icon(Icons.add),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Card(
            child: ListTile(
              leading: const Icon(Icons.receipt_long_outlined),
              title: const Text('Server package quote'),
              subtitle: const Text(
                'Package reservation only; stays and transport are separate.',
              ),
              trailing: Text(
                _quoteLoading
                    ? 'Loading…'
                    : (_quote == null ? 'Choose date' : '৳${_quote!['total']}'),
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 10),
            Text(
              _error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _submitting || _quoteLoading || _quote == null
                  ? null
                  : _submit,
              child: _submitting
                  ? const SizedBox.square(
                      dimension: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Confirm booking'),
            ),
          ),
        ],
      ),
    ),
  );

  Future<void> _pickDate() async {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    final value = await showDatePicker(
      context: context,
      firstDate: DateTime(tomorrow.year, tomorrow.month, tomorrow.day),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDate: _date ?? tomorrow,
    );
    if (value != null && mounted) {
      setState(() => _date = value);
      await _refreshQuote();
    }
  }

  Future<void> _submit() async {
    if (_date == null) {
      setState(() => _error = 'Choose a travel date first.');
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final booking = await widget.controller.createBooking(
        destination: widget.destination,
        date: _date!,
        persons: _persons,
      );
      if (mounted) Navigator.pop(context, booking);
    } on ApiFailure catch (error) {
      if (mounted) setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }
}

String _capitalize(String value) => value.isEmpty
    ? value
    : '${value[0].toUpperCase()}${value.substring(1).toLowerCase()}';
