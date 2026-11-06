import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../data/destination_history.dart';
import '../data/local_guides.dart';
import '../models/destination.dart';
import '../services/api_client.dart';
import '../state/app_controller.dart';
import '../widgets/destination_image.dart';
import '../widgets/safety_sheet.dart';

class DestinationDetailScreen extends StatefulWidget {
  const DestinationDetailScreen({
    super.key,
    required this.controller,
    required this.destination,
    required this.onGoToProfile,
  });

  final AppController controller;
  final Destination destination;
  final VoidCallback onGoToProfile;

  @override
  State<DestinationDetailScreen> createState() =>
      _DestinationDetailScreenState();
}

class _DestinationDetailScreenState extends State<DestinationDetailScreen> {
  late Future<WeatherInfo> _weather;
  DateTime _weatherDate = DateTime.now().add(const Duration(days: 1));
  Future<WeatherForecast>? _forecast;

  @override
  void initState() {
    super.initState();
    _weather = widget.controller.weatherFor(widget.destination);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        widget.controller.recordDestinationView(widget.destination);
      }
    });
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
                tooltip: 'Safety & emergency',
                onPressed: () => SafetySheet.show(context, widget.destination),
                icon: const Icon(Icons.health_and_safety_outlined),
              ),
              const SizedBox(width: 8),
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
                          child: _StoryBody(destination: widget.destination),
                        ),
                      ],
                      const SizedBox(height: 26),
                      _Section(
                        title: 'Plan with confidence',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _WeatherCard(
                              weather: _weather,
                              onRetry: () => setState(
                                () => _weather = widget.controller.weatherFor(
                                  widget.destination,
                                ),
                              ),
                            ),
                            const SizedBox(height: 14),
                            OutlinedButton.icon(
                              onPressed: _pickWeatherDate,
                              icon: const Icon(Icons.calendar_month_outlined),
                              label: Text(
                                'Check ${_shortDate(_weatherDate)} weather and safety',
                              ),
                            ),
                            if (_forecast != null) ...[
                              const SizedBox(height: 12),
                              _TripWeatherAdvice(future: _forecast!),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 26),
                      _Section(
                        title: 'Safety & emergency',
                        child: Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Icon(
                                      Icons.health_and_safety_outlined,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.primary,
                                    ),
                                    const SizedBox(width: 12),
                                    const Expanded(
                                      child: Text(
                                        'Emergency hotlines plus nearby hospitals, police posts and other help for this place.',
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 14),
                                SizedBox(
                                  width: double.infinity,
                                  child: OutlinedButton.icon(
                                    onPressed: () => SafetySheet.show(
                                      context,
                                      widget.destination,
                                    ),
                                    icon: const Icon(
                                      Icons.open_in_new_outlined,
                                    ),
                                    label: const Text(
                                      'Open safety & emergency tools',
                                    ),
                                  ),
                                ),
                              ],
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
                                onPressed: _showAvailable,
                                icon: const Icon(Icons.travel_explore_outlined),
                                label: const Text('Browse services'),
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
                      Card(
                        color: Theme.of(context).colorScheme.primaryContainer,
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.eco_outlined,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onPrimaryContainer,
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
                                            color: Theme.of(
                                              context,
                                            ).colorScheme.onPrimaryContainer,
                                          ),
                                    ),
                                    const SizedBox(height: 5),
                                    Text(
                                      'Respect local communities, carry reusable water, and leave natural places as you found them.',
                                      style: TextStyle(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.onPrimaryContainer,
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
          padding: const EdgeInsets.fromLTRB(8, 10, 8, 10),
          child: Row(
            children: [
              _QuickAction(
                icon: Icons.person_search_outlined,
                label: 'Guides',
                onTap: _showGuides,
              ),
              _QuickAction(
                icon: Icons.savings_outlined,
                label: 'Budget',
                onTap: _showBudget,
              ),
              _QuickAction(
                icon: Icons.calendar_month_outlined,
                label: 'Bookings',
                onTap: _showBooking,
              ),
              _QuickAction(
                icon: Icons.inventory_2_outlined,
                label: 'Available',
                onTap: _showAvailable,
              ),
              _QuickAction(
                icon: Icons.star_outline,
                label: 'Reviews',
                onTap: _showReviews,
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

  Future<void> _pickWeatherDate() async {
    final date = await showDatePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDate: _weatherDate,
    );
    if (date == null) return;
    setState(() {
      _weatherDate = date;
      _forecast = widget.controller.forecastFor(widget.destination, date);
    });
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

  Future<void> _showGuides() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (context) => _FeaturePage(
          title: 'Local guides',
          child: _GuidesSheet(destination: widget.destination),
        ),
      ),
    );
  }

  Future<void> _showBudget() async {
    final result = await Navigator.of(context).push<_BudgetResult>(
      MaterialPageRoute(
        builder: (context) => _FeaturePage(
          title: 'Trip budget',
          child: _BudgetSheet(
            destination: widget.destination,
            weather: _weather,
          ),
        ),
      ),
    );
    if (result == null || !mounted) return;
    final checkIn = result.checkIn;
    await _showAvailable(
      initialDate: checkIn != null && checkIn.isAfter(DateTime.now())
          ? checkIn
          : null,
      initialPersons: result.persons,
    );
  }

  Future<void> _showAvailable({
    DateTime? initialDate,
    int? initialPersons,
  }) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (context) => _FeaturePage(
          title: 'Available services',
          child: _AvailableSheet(
            destination: widget.destination,
            initialDate: initialDate,
            initialPersons: initialPersons,
            hotelsFuture: widget.controller.hotelsFor(widget.destination),
            onConfirmBooking:
                ({DateTime? date, int? persons, String? packageName}) =>
                    _showBooking(
                      initialDate: date ?? initialDate,
                      initialPersons: persons ?? initialPersons,
                      initialPackageName: packageName,
                    ),
          ),
        ),
      ),
    );
  }

  Future<void> _showReviews() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (context) => _FeaturePage(
          title: 'Traveler reviews',
          child: _ReviewsSheet(
            future: widget.controller.reviewsFor(widget.destination),
            destinationName: widget.destination.name,
          ),
        ),
      ),
    );
  }

  Future<void> _showBooking({
    DateTime? initialDate,
    int? initialPersons,
    String? initialPackageName,
  }) async {
    var destination = widget.destination;
    if (destination.id <= 0) {
      destination =
          widget.controller.liveDestinationFor(widget.destination) ??
          widget.destination;
    }
    if (destination.id <= 0) {
      // The bundled catalog has no server id. Try to fetch the live catalog
      // here so booking works as soon as the FarReach server is reachable.
      await widget.controller.refreshDestinations(silent: true);
      if (!mounted) return;
      destination =
          widget.controller.liveDestinationFor(widget.destination) ??
          widget.destination;
    }
    if (destination.id <= 0) {
      final retry = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          icon: const Icon(Icons.cloud_off_outlined),
          title: const Text('Server unreachable'),
          content: const Text(
            'Booking needs the live catalog from the FarReach server, which '
            'the app could not reach. Check that your device can reach the '
            'server, then try again.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Not now'),
            ),
            FilledButton.icon(
              onPressed: () => Navigator.pop(context, true),
              icon: const Icon(Icons.refresh),
              label: const Text('Try again'),
            ),
          ],
        ),
      );
      if (retry == true && mounted) {
        await _showBooking(
          initialDate: initialDate,
          initialPersons: initialPersons,
          initialPackageName: initialPackageName,
        );
      }
      return;
    }
    if (!widget.controller.isAuthenticated) {
      final goToSignIn = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          icon: const Icon(Icons.lock_outline),
          title: const Text('Sign in to book'),
          content: const Text(
            'Sign in or create an account to confirm this trip. It only takes a moment, and your bookings and saved places sync to your account.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Not now'),
            ),
            FilledButton.icon(
              onPressed: () => Navigator.pop(context, true),
              icon: const Icon(Icons.login),
              label: const Text('Sign in'),
            ),
          ],
        ),
      );
      if (goToSignIn == true && mounted) {
        Navigator.of(context).pop();
        widget.onGoToProfile();
      }
      return;
    }
    final booking = await Navigator.of(context).push<Booking>(
      MaterialPageRoute(
        builder: (context) => _FeaturePage(
          title: 'Confirm booking',
          child: _BookingSheet(
            controller: widget.controller,
            destination: destination,
            initialDate: initialDate,
            initialPersons: initialPersons,
            initialPackageName: initialPackageName,
          ),
        ),
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
      style: Theme.of(context).textTheme.labelMedium?.copyWith(
        color: Colors.black87,
        fontWeight: FontWeight.w700,
      ),
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

class _StoryBody extends StatelessWidget {
  const _StoryBody({required this.destination});

  final Destination destination;

  @override
  Widget build(BuildContext context) {
    final paragraphs = storyParagraphsFor(destination);
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainerLowest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.auto_stories_outlined,
                  size: 18,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'A three-part story',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.4,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            for (var index = 0; index < paragraphs.length; index++) ...[
              if (index > 0) const SizedBox(height: 18),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Container(
                      width: 24,
                      height: 24,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: index == 0
                            ? theme.colorScheme.primary
                            : theme.colorScheme.primaryContainer,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '${index + 1}',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: index == 0
                              ? theme.colorScheme.onPrimary
                              : theme.colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      paragraphs[index],
                      style: theme.textTheme.bodyLarge?.copyWith(
                        height: 1.68,
                        fontSize: index == 0 ? 16.5 : 15.5,
                        fontWeight: index == 0
                            ? FontWeight.w500
                            : FontWeight.w400,
                        color: index == 0
                            ? theme.colorScheme.onSurface
                            : theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
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

class _TripWeatherAdvice extends StatelessWidget {
  const _TripWeatherAdvice({required this.future});

  final Future<WeatherForecast> future;

  @override
  Widget build(BuildContext context) => FutureBuilder<WeatherForecast>(
    future: future,
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const Card(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                CircularProgressIndicator(),
                SizedBox(width: 14),
                Text('Checking this date...'),
              ],
            ),
          ),
        );
      }
      if (snapshot.hasError) {
        return const Card(
          child: ListTile(
            leading: Icon(Icons.cloud_off_outlined),
            title: Text('Date forecast unavailable'),
            subtitle: Text('Check local conditions again closer to your trip.'),
          ),
        );
      }
      final forecast = snapshot.requireData;
      final caution =
          forecast.precipitationProbability >= 60 || forecast.weatherCode >= 80;
      final title = caution
          ? 'Use caution for this date'
          : 'Good to go for this date';
      final message = caution
          ? 'Rain or storm conditions may affect outdoor plans. Keep a flexible schedule and check again before leaving.'
          : 'The forecast looks suitable for sightseeing. Carry water and check local advisories before departure.';
      final scheme = Theme.of(context).colorScheme;
      final background = caution
          ? scheme.errorContainer
          : scheme.primaryContainer;
      final foreground = caution
          ? scheme.onErrorContainer
          : scheme.onPrimaryContainer;
      return Card(
        color: background,
        child: ListTile(
          leading: Icon(
            caution ? Icons.warning_amber_rounded : Icons.check_circle_outline,
            color: foreground,
          ),
          title: Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(color: foreground),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              '${_shortDate(forecast.date)} · '
              '${forecast.minTemperature.round()}°-${forecast.maxTemperature.round()}°C · '
              'Rain ${forecast.precipitationProbability}%\n$message',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: foreground, height: 1.4),
            ),
          ),
        ),
      );
    },
  );
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Expanded(
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 5),
            Text(label, style: Theme.of(context).textTheme.labelMedium),
          ],
        ),
      ),
    ),
  );
}

class _FeaturePage extends StatelessWidget {
  const _FeaturePage({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(title), leading: const BackButton()),
    body: child,
  );
}

class _GuidesSheet extends StatelessWidget {
  const _GuidesSheet({required this.destination});

  final Destination destination;

  @override
  Widget build(BuildContext context) {
    final guides = localGuidesFor(destination);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Local guides',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 4),
            Text(
              'Recommended guides around ${destination.name}. Contact them directly to arrange a trip.',
            ),
            const SizedBox(height: 16),
            ...guides.map(
              (guide) => Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    child: Text(
                      guide.initials,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  title: Text(guide.name),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${guide.role} · based in ${guide.base}'),
                      const SizedBox(height: 2),
                      Text('✉️ ${guide.email}'),
                      Text('📞 ${guide.phone}'),
                    ],
                  ),
                  isThreeLine: true,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BudgetResult {
  const _BudgetResult({required this.checkIn, required this.persons});

  final DateTime? checkIn;
  final int persons;
}

class _BudgetSheet extends StatefulWidget {
  const _BudgetSheet({required this.destination, required this.weather});

  final Destination destination;
  final Future<WeatherInfo> weather;

  @override
  State<_BudgetSheet> createState() => _BudgetSheetState();
}

class _BudgetSheetState extends State<_BudgetSheet> {
  DateTime? _checkIn;
  DateTime? _checkOut;
  int _persons = 1;
  int _days = 3;
  String _origin = 'Dhaka';
  String _transport = 'bus_nonac';
  String _hotel = 'normal';
  String _food = 'standard';
  String _guide = 'none';

  int get _baseHotel => widget.destination.budget.toLowerCase() == 'high'
      ? 3500
      : widget.destination.budget.toLowerCase() == 'mid'
      ? 2000
      : 1200;

  int get _hotelCost =>
      (_baseHotel * (_hotelMultipliers[_hotel] ?? 100) / 100).round();
  int get _foodCost => _foodRates[_food] ?? 700;
  int get _guideCost => _guideRates[_guide] ?? 0;
  int get _travelCost => (_transportRates[_transport] ?? 150) * 2;
  int get _total =>
      (_hotelCost * _persons * (_days - 1).clamp(1, 30)) +
      (_foodCost * _persons * _days) +
      (_guideCost * _days) +
      (_localTransport * _persons * _days) +
      (_travelCost * _persons);
  int get _localTransport => widget.destination.budget.toLowerCase() == 'high'
      ? 2000
      : widget.destination.budget.toLowerCase() == 'mid'
      ? 1500
      : 900;

  static const _hotelMultipliers = {
    'normal': 100,
    'guesthouse': 70,
    'homestay': 65,
    'rest_house': 75,
    'beach_resort': 135,
    'hill_cottage': 115,
    'forest_lodge': 120,
    '3star': 150,
    '5star': 280,
    'boutique': 170,
    'luxury_suite': 350,
  };
  static const _foodRates = {
    'street': 250,
    'mess': 300,
    'breakfast': 350,
    'standard': 700,
    'family': 600,
    'fastfood': 550,
    'seafood': 900,
    'hill_cuisine': 750,
    'tea_garden': 650,
    'boat_meal': 800,
    'buffet': 850,
    'fine_dining': 1200,
    'resort_dining': 1000,
  };
  static const _guideRates = {
    'none': 0,
    'local': 500,
    'licensed': 900,
    'beach': 800,
    'hill': 1000,
    'forest': 1200,
    'eco': 750,
    'heritage': 700,
    'boat': 900,
    'tribal': 850,
    'translator': 1000,
    'private_vip': 1800,
  };
  static const _transportRates = {
    'bus_nonac': 150,
    'bus_ac': 300,
    'bus_sleeper': 450,
    'train_shovon': 120,
    'train_chair': 220,
    'train_ac': 400,
    'train_sleeper': 500,
    'launch_deck': 150,
    'launch_cabin': 650,
    'ferry': 180,
    'boat': 250,
    'microbus': 900,
    'private_car': 1200,
    'cng': 300,
    'jeep': 1400,
    'air': 2500,
  };

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          0,
          20,
          20 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height * .86,
          child: ListView(
            children: [
              Text(
                'Trip budget',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 4),
              Text('Build a complete estimate for ${widget.destination.name}.'),
              const SizedBox(height: 16),
              _BudgetDateRow(
                checkIn: _checkIn,
                checkOut: _checkOut,
                onCheckIn: () => _pickDate(true),
                onCheckOut: () => _pickDate(false),
              ),
              const SizedBox(height: 12),
              _BudgetDropdown(
                label: 'Your district',
                value: _origin,
                items: const [
                  'Dhaka',
                  'Chattogram',
                  'Rajshahi',
                  'Khulna',
                  'Sylhet',
                  'Rangamati',
                  'Cox\'s Bazar',
                  'Bandarban',
                  'Cumilla',
                  'Patuakhali',
                ],
                onChanged: (value) => setState(() => _origin = value),
              ),
              _BudgetDropdown(
                label: 'Vehicle / transport type',
                value: _transport,
                labels: _transportLabels,
                onChanged: (value) => setState(() => _transport = value),
              ),
              _BudgetDropdown(
                label: 'Hotel, lodging or resort',
                value: _hotel,
                labels: _hotelLabels,
                onChanged: (value) => setState(() => _hotel = value),
              ),
              _BudgetDropdown(
                label: 'Restaurant / food type',
                value: _food,
                labels: _foodLabels,
                onChanged: (value) => setState(() => _food = value),
              ),
              _BudgetDropdown(
                label: 'Guide service',
                value: _guide,
                labels: _guideLabels,
                onChanged: (value) => setState(() => _guide = value),
              ),
              _BudgetStepper(
                label: 'Number of people',
                value: _persons,
                min: 1,
                max: 20,
                onChanged: (value) => setState(() => _persons = value),
              ),
              _BudgetStepper(
                label: 'Trip duration (days)',
                value: _days,
                min: 1,
                max: 30,
                onChanged: (value) => setState(() => _days = value),
              ),
              Card(
                color: Theme.of(context).colorScheme.primaryContainer,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Estimate for $_persons traveler(s), $_days day(s)',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 12),
                      _EstimateRow(
                        label:
                            'Travel ($_origin to ${widget.destination.district})',
                        value: _travelCost * _persons,
                      ),
                      _EstimateRow(
                        label:
                            'Hotel (${_days - 1 < 1 ? 1 : _days - 1} night(s))',
                        value: _hotelCost * _persons * (_days - 1).clamp(1, 30),
                      ),
                      _EstimateRow(
                        label: 'Food and dining',
                        value: _foodCost * _persons * _days,
                      ),
                      _EstimateRow(
                        label: 'Guide service',
                        value: _guideCost * _days,
                      ),
                      _EstimateRow(
                        label: 'Local transport and activities',
                        value: _localTransport * _persons * _days,
                      ),
                      const Divider(height: 22),
                      _EstimateRow(
                        label: 'Total estimated cost',
                        value: _total,
                        emphasize: true,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Rates are estimates in BDT and can change by season and availability.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => Navigator.pop(
                    context,
                    _BudgetResult(checkIn: _checkIn, persons: _persons),
                  ),
                  icon: const Icon(Icons.room_service_outlined),
                  label: const Text('View available services'),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Browse hotels, transports, guides & services for this plan.',
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickDate(bool isCheckIn) async {
    final initial = isCheckIn ? _checkIn : _checkOut;
    final date = await showDatePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 730)),
      initialDate:
          initial ?? DateTime.now().add(Duration(days: isCheckIn ? 1 : 4)),
    );
    if (date == null) return;
    setState(() {
      if (isCheckIn) {
        _checkIn = date;
        if (_checkOut != null && !_checkOut!.isAfter(date)) _checkOut = null;
      } else if (_checkIn == null || date.isAfter(_checkIn!)) {
        _checkOut = date;
        if (_checkIn != null) _days = date.difference(_checkIn!).inDays + 1;
      }
    });
  }
}

class _BudgetDateRow extends StatelessWidget {
  const _BudgetDateRow({
    required this.checkIn,
    required this.checkOut,
    required this.onCheckIn,
    required this.onCheckOut,
  });

  final DateTime? checkIn;
  final DateTime? checkOut;
  final VoidCallback onCheckIn;
  final VoidCallback onCheckOut;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: OutlinedButton.icon(
          onPressed: onCheckIn,
          icon: const Icon(Icons.login_outlined),
          label: Text(checkIn == null ? 'Check-in' : _shortDate(checkIn!)),
        ),
      ),
      const SizedBox(width: 10),
      Expanded(
        child: OutlinedButton.icon(
          onPressed: onCheckOut,
          icon: const Icon(Icons.logout_outlined),
          label: Text(checkOut == null ? 'Check-out' : _shortDate(checkOut!)),
        ),
      ),
    ],
  );
}

class _BudgetDropdown extends StatelessWidget {
  const _BudgetDropdown({
    required this.label,
    required this.value,
    this.items,
    this.labels,
    required this.onChanged,
  });

  final String label;
  final String value;
  final List<String>? items;
  final Map<String, String>? labels;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final values = items ?? labels!.keys.toList();
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: DropdownButtonFormField<String>(
        initialValue: value,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        items: values
            .map(
              (item) => DropdownMenuItem(
                value: item,
                child: Text(
                  labels?[item] ?? item,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            )
            .toList(),
        onChanged: (next) {
          if (next != null) onChanged(next);
        },
      ),
    );
  }
}

class _BudgetStepper extends StatelessWidget {
  const _BudgetStepper({
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
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(child: Text(label)),
      IconButton.outlined(
        onPressed: value > min ? () => onChanged(value - 1) : null,
        icon: const Icon(Icons.remove),
      ),
      SizedBox(
        width: 38,
        child: Text(
          '$value',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleMedium,
        ),
      ),
      IconButton.outlined(
        onPressed: value < max ? () => onChanged(value + 1) : null,
        icon: const Icon(Icons.add),
      ),
    ],
  );
}

class _EstimateRow extends StatelessWidget {
  const _EstimateRow({
    required this.label,
    required this.value,
    this.emphasize = false,
  });

  final String label;
  final int value;
  final bool emphasize;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: emphasize ? Theme.of(context).textTheme.titleMedium : null,
          ),
        ),
        Text(
          '৳${_money(value)}',
          style: emphasize ? Theme.of(context).textTheme.titleLarge : null,
        ),
      ],
    ),
  );
}

class _AvailableSheet extends StatelessWidget {
  const _AvailableSheet({
    required this.destination,
    this.initialDate,
    this.initialPersons,
    required this.hotelsFuture,
    required this.onConfirmBooking,
  });

  final Destination destination;
  final DateTime? initialDate;
  final int? initialPersons;
  final Future<List<HotelRecommendation>> hotelsFuture;
  final void Function({DateTime? date, int? persons, String? packageName})
  onConfirmBooking;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: DefaultTabController(
        length: 4,
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Available services',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Select and book your preferred services online via web links, then confirm your trip with FarReach.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    if (initialDate != null) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.event_outlined,
                              size: 16,
                              color: Theme.of(
                                context,
                              ).colorScheme.onPrimaryContainer,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Planned travel: ${_shortDate(initialDate!)} · ${initialPersons ?? 1} traveler(s)',
                              style: Theme.of(context).textTheme.labelMedium
                                  ?.copyWith(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onPrimaryContainer,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const TabBar(
                isScrollable: true,
                tabs: [
                  Tab(icon: Icon(Icons.hotel_outlined), text: 'Hotels'),
                  Tab(
                    icon: Icon(Icons.directions_bus_outlined),
                    text: 'Travel Transports',
                  ),
                  Tab(icon: Icon(Icons.person_pin_outlined), text: 'Guiders'),
                  Tab(icon: Icon(Icons.category_outlined), text: 'Others'),
                ],
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    _AvailableHotelsTab(
                      destination: destination,
                      future: hotelsFuture,
                    ),
                    _AvailableTransportsTab(destination: destination),
                    _AvailableGuidersTab(destination: destination),
                    _AvailableOthersTab(
                      destination: destination,
                      onBookPackage: (pkg) {
                        Navigator.pop(context);
                        onConfirmBooking(
                          date: initialDate,
                          persons: initialPersons,
                          packageName: pkg,
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
          bottomNavigationBar: Container(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              border: Border(
                top: BorderSide(
                  color: Theme.of(context).colorScheme.outlineVariant,
                ),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.check_circle_outline,
                      size: 18,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Ready to secure your plan? Confirm in FarReach:',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      onConfirmBooking(
                        date: initialDate,
                        persons: initialPersons,
                      );
                    },
                    icon: const Icon(Icons.verified_outlined),
                    label: const Text('Confirm Booking via FarReach'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AvailableHotelsTab extends StatelessWidget {
  const _AvailableHotelsTab({required this.destination, required this.future});

  final Destination destination;
  final Future<List<HotelRecommendation>> future;

  @override
  Widget build(BuildContext context) {
    final searchUri = Uri.parse(
      'https://www.booking.com/searchresults.html?ss=${Uri.encodeComponent('${destination.name} ${destination.district}')}',
    );
    final gozayaanUri = Uri.parse('https://www.gozayaan.com/hotel');
    final agodaUri = Uri.parse(
      'https://www.agoda.com/search?text=${Uri.encodeComponent(destination.name)}',
    );

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
      children: [
        Card(
          color: Theme.of(
            context,
          ).colorScheme.secondaryContainer.withValues(alpha: 0.5),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.language_outlined,
                      size: 20,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Book Online via Hotel Portals',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                const Text(
                  'Search real-time room availability and book securely across leading platforms:',
                  style: TextStyle(fontSize: 13),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ActionChip(
                      avatar: const Icon(Icons.open_in_new, size: 16),
                      label: const Text('Booking.com'),
                      onPressed: () => _openWebUri(context, searchUri),
                    ),
                    ActionChip(
                      avatar: const Icon(Icons.open_in_new, size: 16),
                      label: const Text('GoZayaan Hotels'),
                      onPressed: () => _openWebUri(context, gozayaanUri),
                    ),
                    ActionChip(
                      avatar: const Icon(Icons.open_in_new, size: 16),
                      label: const Text('Agoda'),
                      onPressed: () => _openWebUri(context, agodaUri),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        Text(
          'Recommended stays near ${destination.name}',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        FutureBuilder<List<HotelRecommendation>>(
          future: future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: CircularProgressIndicator()),
              );
            }
            final hotels = snapshot.data ?? const [];
            if (hotels.isEmpty) {
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      const Text(
                        'No specific hotel listings returned right now. You can check available options directly on hotel booking sites:',
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: () => _openWebUri(context, searchUri),
                        icon: const Icon(Icons.open_in_new),
                        label: Text('Search hotels in ${destination.name}'),
                      ),
                    ],
                  ),
                ),
              );
            }
            return Column(
              children: hotels.map((hotel) {
                final hotelUri =
                    _safeWebUri(hotel.url) ??
                    Uri.parse(
                      'https://www.google.com/search?q=${Uri.encodeComponent('${hotel.name} ${destination.name}')}',
                    );
                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CircleAvatar(
                              radius: 20,
                              backgroundColor: Theme.of(
                                context,
                              ).colorScheme.primaryContainer,
                              child: Text(
                                hotel.rating.toStringAsFixed(1),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onPrimaryContainer,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    hotel.name,
                                    style: Theme.of(
                                      context,
                                    ).textTheme.titleMedium,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '৳${hotel.price} / night · ${hotel.availability}',
                                    style: TextStyle(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.primary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        if (hotel.note.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            hotel.note,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () => _openWebUri(context, hotelUri),
                            icon: const Icon(Icons.open_in_new, size: 16),
                            label: const Text('Book / View hotel online'),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }
}

class _AvailableTransportsTab extends StatelessWidget {
  const _AvailableTransportsTab({required this.destination});

  final Destination destination;

  @override
  Widget build(BuildContext context) {
    final transports = [
      _TransportOption(
        title: 'Bangladesh Railway e-Ticketing',
        subtitle: 'Intercity AC, chair & sleeper train tickets nationwide',
        icon: Icons.train_outlined,
        url: 'https://eticket.railway.gov.bd',
        tag: 'Train',
      ),
      _TransportOption(
        title: 'Shohoz Bus Booking',
        subtitle: 'AC & non-AC coach tickets (Green Line, Hanif, Shyamoli)',
        icon: Icons.directions_bus_outlined,
        url: 'https://www.shohoz.com/bus-tickets',
        tag: 'Bus',
      ),
      _TransportOption(
        title: 'GoZayaan Domestic Flights',
        subtitle: 'Compare & book domestic air tickets to nearest airport',
        icon: Icons.flight_outlined,
        url: 'https://www.gozayaan.com/flight',
        tag: 'Air',
      ),
      _TransportOption(
        title: 'Shohoz Launch & Ferry',
        subtitle: 'River passenger vessels, cabin & deck ticket bookings',
        icon: Icons.directions_boat_outlined,
        url: 'https://www.shohoz.com/launch',
        tag: 'River',
      ),
      _TransportOption(
        title: 'Private Car & Microbus Hire',
        subtitle: 'Dedicated sedans and group minivans with drivers',
        icon: Icons.directions_car_outlined,
        url:
            'https://www.google.com/search?q=${Uri.encodeComponent('rent a car ${destination.name} ${destination.district}')}',
        tag: 'Private',
      ),
      _TransportOption(
        title: 'Local Jeep / Chander Gari',
        subtitle: '4x4 tourist jeeps for hill trekking and sightseeing',
        icon: Icons.terrain_outlined,
        url:
            'https://www.google.com/search?q=${Uri.encodeComponent('tourist jeep booking ${destination.name}')}',
        tag: 'Local',
      ),
    ];

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
      children: [
        Card(
          color: Theme.of(
            context,
          ).colorScheme.primaryContainer.withValues(alpha: 0.4),
          child: const Padding(
            padding: EdgeInsets.all(12),
            child: Row(
              children: [
                Icon(Icons.info_outline, size: 20),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Book travel tickets directly on official web channels, then return to FarReach to finalize your trip schedule.',
                    style: TextStyle(fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        ...transports.map((t) {
          final uri = Uri.parse(t.url);
          return Card(
            margin: const EdgeInsets.only(bottom: 10),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Theme.of(
                  context,
                ).colorScheme.surfaceContainerHighest,
                child: Icon(
                  t.icon,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              title: Text(
                t.title,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(t.subtitle),
              ),
              trailing: IconButton.filledTonal(
                tooltip: 'Book / View website',
                icon: const Icon(Icons.open_in_new, size: 18),
                onPressed: () => _openWebUri(context, uri),
              ),
              isThreeLine: true,
            ),
          );
        }),
      ],
    );
  }
}

class _TransportOption {
  const _TransportOption({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.url,
    required this.tag,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final String url;
  final String tag;
}

class _AvailableGuidersTab extends StatelessWidget {
  const _AvailableGuidersTab({required this.destination});

  final Destination destination;

  @override
  Widget build(BuildContext context) {
    final guides = localGuidesFor(destination);
    final bpcUri = Uri.parse('https://parjatan.gov.bd/');
    final guideDirectoryUri = Uri.parse(
      'https://www.google.com/search?q=${Uri.encodeComponent('tourist guides in ${destination.name} Bangladesh')}',
    );

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
      children: [
        Card(
          color: Theme.of(
            context,
          ).colorScheme.tertiaryContainer.withValues(alpha: 0.4),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Verified National Guide Directories',
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Access official certified tourist guides registered with government & tourism associations.',
                  style: TextStyle(fontSize: 13),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ActionChip(
                      avatar: const Icon(Icons.open_in_new, size: 16),
                      label: const Text('BPC Official Portal'),
                      onPressed: () => _openWebUri(context, bpcUri),
                    ),
                    ActionChip(
                      avatar: const Icon(Icons.open_in_new, size: 16),
                      label: const Text('Search Local Guides Online'),
                      onPressed: () => _openWebUri(context, guideDirectoryUri),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        Text(
          'Featured local guides around ${destination.name}',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        ...guides.map((guide) {
          final contactUri = Uri.parse(
            'https://www.google.com/search?q=${Uri.encodeComponent('${guide.name} tour guide ${guide.base}')}',
          );
          return Card(
            margin: const EdgeInsets.only(bottom: 10),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        child: Text(
                          guide.initials,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              guide.name,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            Text(
                              '${guide.role} · based in ${guide.base}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '✉️ ${guide.email}',
                    style: const TextStyle(fontSize: 13),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '📞 ${guide.phone}',
                    style: const TextStyle(fontSize: 13),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => _openWebUri(context, contactUri),
                      icon: const Icon(Icons.open_in_new, size: 16),
                      label: const Text('Connect / View guide profile'),
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}

class _AvailableOthersTab extends StatelessWidget {
  const _AvailableOthersTab({
    required this.destination,
    required this.onBookPackage,
  });

  final Destination destination;
  final ValueChanged<String> onBookPackage;

  @override
  Widget build(BuildContext context) {
    final foodUri = Uri.parse(
      'https://www.google.com/search?q=${Uri.encodeComponent('best restaurants and street food in ${destination.name}')}',
    );
    final activityUri = Uri.parse(
      'https://www.google.com/search?q=${Uri.encodeComponent('things to do sightseeing activities in ${destination.name}')}',
    );
    final emergencyUri = Uri.parse(
      'https://www.google.com/search?q=${Uri.encodeComponent('hospitals emergency medical services near ${destination.name}')}',
    );

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.restaurant_outlined,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Local Dining & Cuisine',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Explore traditional delicacies, authentic food stalls and popular restaurants at ${destination.name}.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: () => _openWebUri(context, foodUri),
                  icon: const Icon(Icons.open_in_new, size: 16),
                  label: const Text('Find restaurants online'),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.local_activity_outlined,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Activities & Sightseeing',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Boat tours, trekking permits, scuba diving and cultural heritage activities.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: () => _openWebUri(context, activityUri),
                  icon: const Icon(Icons.open_in_new, size: 16),
                  label: const Text('Explore activities online'),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.medical_services_outlined,
                      color: Theme.of(context).colorScheme.error,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Nearby Medical & Emergency',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Hospital directories, pharmacies and emergency medical facilities.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: () => _openWebUri(context, emergencyUri),
                  icon: const Icon(Icons.open_in_new, size: 16),
                  label: const Text('Search medical help online'),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 18),
        Text(
          'FarReach Curated Tour Packages',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        ..._specialPackages.map(
          (package) => Card(
            margin: const EdgeInsets.only(bottom: 10),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    package.name,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${package.duration} · ৳${_money(package.pricePerPerson)} / person',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    package.includes,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.tonalIcon(
                      onPressed: () => onBookPackage(package.name),
                      icon: const Icon(Icons.shopping_bag_outlined, size: 18),
                      label: const Text('Select this package for FarReach'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

const _transportLabels = {
  'bus_nonac': 'Bus - Non-AC',
  'bus_ac': 'Bus - AC coach',
  'bus_sleeper': 'Bus - Sleeper / business class',
  'train_shovon': 'Train - Shovon (non-AC)',
  'train_chair': 'Train - Chair / first seat',
  'train_ac': 'Train - AC chair / cabin',
  'train_sleeper': 'Train - Sleeper / cabin',
  'launch_deck': 'Launch - Deck',
  'launch_cabin': 'Launch - Cabin',
  'ferry': 'Ferry / Ro-Ro',
  'boat': 'Boat / engine boat',
  'microbus': 'Microbus / private minivan',
  'private_car': 'Private car / rent-a-car',
  'cng': 'CNG / auto-rickshaw',
  'jeep': 'Hill Jeep / 4x4',
  'air': 'Domestic flight',
};
const _hotelLabels = {
  'normal': 'Normal / economy hotel',
  'guesthouse': 'Guesthouse / lodging house',
  'homestay': 'Homestay / cottage / boat cabin',
  'rest_house': 'Government rest house / motel',
  'beach_resort': 'Beach resort / sea-view hotel',
  'hill_cottage': 'Hill cottage / mountain resort',
  'forest_lodge': 'Forest lodge / eco resort',
  '3star': '3-star hotel / resort',
  'boutique': 'Boutique hotel / eco resort',
  '5star': '5-star luxury hotel / resort',
  'luxury_suite': 'Luxury suite / premium villa',
};
const _foodLabels = {
  'street': 'Street food / local snacks',
  'mess': 'Local mess / student canteen',
  'breakfast': 'Tea stall / breakfast stop',
  'standard': 'Standard restaurant dining',
  'family': 'Family restaurant / local diner',
  'fastfood': 'Fast food / cafe',
  'seafood': 'Seafood restaurant',
  'hill_cuisine': 'Hill cuisine / tribal meal',
  'tea_garden': 'Tea garden meal',
  'boat_meal': 'Boat / launch meal',
  'buffet': 'Hotel buffet dining',
  'fine_dining': 'Fine dining / premium restaurant',
  'resort_dining': 'Resort dining / sea-view dinner',
};
const _guideLabels = {
  'none': 'No guide / self-explore',
  'local': 'Local spot guide',
  'licensed': 'Professional licensed guide',
  'beach': 'Beach guide',
  'hill': 'Hill trek guide',
  'forest': 'Forest / Sundarbans guide',
  'eco': 'Eco-tour guide',
  'heritage': 'Heritage guide',
  'boat': 'Haor / boat guide',
  'tribal': 'Tribal / community guide',
  'translator': 'Translator / language support',
  'private_vip': 'Private VIP guide',
};

const _specialPackages = [
  _SpecialPackage(
    name: 'Weekend Explorer',
    duration: '2 days · 1 night',
    pricePerPerson: 4800,
    includes: 'Transport, standard hotel, guide, breakfast, local activities',
  ),
  _SpecialPackage(
    name: 'Family Comfort Package',
    duration: '3 days · 2 nights',
    pricePerPerson: 8900,
    includes: 'AC transport, family hotel, meals, guided highlights',
  ),
  _SpecialPackage(
    name: 'Premium Relax Package',
    duration: '3 days · 2 nights',
    pricePerPerson: 13500,
    includes: 'Premium stay, private transfer, dedicated guide, activities',
  ),
  _SpecialPackage(
    name: 'Eco Adventure Package',
    duration: '4 days · 3 nights',
    pricePerPerson: 11200,
    includes: 'Eco lodge, nature guide, trekking/boat activities, meals',
  ),
];
const _bookablePackages = [
  'Standard package',
  'Weekend Explorer',
  'Family Comfort Package',
  'Premium Relax Package',
  'Eco Adventure Package',
];

class _SpecialPackage {
  const _SpecialPackage({
    required this.name,
    required this.duration,
    required this.pricePerPerson,
    required this.includes,
  });

  final String name;
  final String duration;
  final int pricePerPerson;
  final String includes;
}

class _ReviewsSheet extends StatelessWidget {
  const _ReviewsSheet({required this.future, required this.destinationName});

  final Future<List<Review>> future;
  final String destinationName;

  @override
  Widget build(BuildContext context) => SafeArea(
    child: Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.7,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Reviews', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 4),
            Text('What travelers say about $destinationName.'),
            const SizedBox(height: 16),
            Expanded(
              child: FutureBuilder<List<Review>>(
                future: future,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return const Center(
                      child: Text('Reviews are unavailable right now.'),
                    );
                  }
                  final reviews = snapshot.data ?? const [];
                  if (reviews.isEmpty) {
                    return const Center(
                      child: Text('No reviews yet. Be the first to share one.'),
                    );
                  }
                  return ListView.separated(
                    itemCount: reviews.length,
                    separatorBuilder: (_, _) => const Divider(),
                    itemBuilder: (context, index) {
                      final review = reviews[index];
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  review.userName,
                                  style: Theme.of(
                                    context,
                                  ).textTheme.titleMedium,
                                ),
                              ),
                              Text(
                                '${'★' * review.rating}${'☆' * (5 - review.rating)}',
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                            ],
                          ),
                          if (review.createdAt.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Text(
                                review.createdAt,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ),
                          const SizedBox(height: 6),
                          Text(review.text.isEmpty ? '—' : review.text),
                          if (review.adminReply.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Theme.of(
                                  context,
                                ).colorScheme.secondaryContainer,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                'Admin response: ${review.adminReply}',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ),
                          ],
                        ],
                      );
                    },
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

class _BookingSheet extends StatefulWidget {
  const _BookingSheet({
    required this.controller,
    required this.destination,
    this.initialDate,
    this.initialPersons,
    this.initialPackageName,
  });

  final AppController controller;
  final Destination destination;
  final DateTime? initialDate;
  final int? initialPersons;
  final String? initialPackageName;

  @override
  State<_BookingSheet> createState() => _BookingSheetState();
}

class _BookingSheetState extends State<_BookingSheet> {
  DateTime? _date;
  int _persons = 1;
  String _packageName = 'Standard package';
  bool _submitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _date = widget.initialDate;
    _persons = (widget.initialPersons ?? 1).clamp(1, 20);
    final initialPackage = widget.initialPackageName?.trim();
    if (initialPackage != null && initialPackage.isNotEmpty) {
      _packageName = initialPackage;
    }
  }

  int get _estimate {
    final rate = switch (widget.destination.budget.toLowerCase()) {
      'high' => 1700,
      'mid' => 1250,
      _ => 800,
    };
    final packageMultiplier = switch (_packageName) {
      'Standard package' => 1.0,
      'Weekend Explorer' => 1.15,
      'Family Comfort Package' => 1.35,
      'Premium Relax Package' => 1.8,
      'Eco Adventure Package' => 1.5,
      _ => 1.2,
    };
    return (rate * _persons * packageMultiplier).round();
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
            onPressed: _pickDate,
            icon: const Icon(Icons.calendar_today_outlined),
            label: Text(
              _date == null
                  ? 'Choose travel date'
                  : '${_date!.day}/${_date!.month}/${_date!.year}',
            ),
          ),
          const SizedBox(height: 14),
          DropdownButtonFormField<String>(
            initialValue: _packageName,
            decoration: const InputDecoration(
              labelText: 'Package',
              border: OutlineInputBorder(),
            ),
            items: _bookablePackages
                .map(
                  (item) => DropdownMenuItem<String>(
                    value: item,
                    child: Text(item, overflow: TextOverflow.ellipsis),
                  ),
                )
                .toList(),
            onChanged: (value) {
              if (value != null) setState(() => _packageName = value);
            },
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              const Expanded(child: Text('Travelers')),
              IconButton.outlined(
                tooltip: 'Remove traveler',
                onPressed: _persons > 1
                    ? () => setState(() => _persons--)
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
                onPressed: _persons < 20
                    ? () => setState(() => _persons++)
                    : null,
                icon: const Icon(Icons.add),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Card(
            child: ListTile(
              leading: const Icon(Icons.receipt_long_outlined),
              title: const Text('Estimated package total'),
              subtitle: Text(
                'Package: $_packageName\nFinal price is calculated by the server.',
              ),
              isThreeLine: true,
              trailing: Text(
                '৳$_estimate',
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
              onPressed: _submitting ? null : _submit,
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
    final minimumDate = DateTime.now().add(const Duration(days: 3));
    final firstDate = DateTime(
      minimumDate.year,
      minimumDate.month,
      minimumDate.day,
    );
    final value = await showDatePicker(
      context: context,
      firstDate: firstDate,
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDate: _date != null && !_date!.isBefore(firstDate)
          ? _date!
          : firstDate,
    );
    if (value != null) setState(() => _date = value);
  }

  Future<void> _submit() async {
    if (_date == null) {
      setState(() => _error = 'Choose a travel date first.');
      return;
    }
    final minimumDate = DateTime.now().add(const Duration(days: 3));
    final firstDate = DateTime(
      minimumDate.year,
      minimumDate.month,
      minimumDate.day,
    );
    if (_date!.isBefore(firstDate)) {
      setState(
        () => _error = 'Bookings must be made at least 3 days before travel.',
      );
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
        packageName: _packageName,
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

Uri? _safeWebUri(String value) {
  final uri = Uri.tryParse(value.trim());
  if (uri == null || !uri.hasAuthority) return null;
  return (uri.scheme == 'https' || uri.scheme == 'http') ? uri : null;
}

Future<void> _openWebUri(BuildContext context, Uri uri) async {
  try {
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open this link.')),
      );
    }
  } catch (_) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open this link.')),
      );
    }
  }
}

String _shortDate(DateTime date) => '${date.day}/${date.month}/${date.year}';

String _money(int value) {
  final text = value.toString();
  final buffer = StringBuffer();
  for (var index = 0; index < text.length; index++) {
    if (index > 0 && (text.length - index) % 3 == 0) buffer.write(',');
    buffer.write(text[index]);
  }
  return buffer.toString();
}
