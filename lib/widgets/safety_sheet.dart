import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../data/emergency_directory.dart';
import '../models/destination.dart';

/// Place-wise safety tools and emergency contacts for a single destination.
class SafetySheet extends StatelessWidget {
  const SafetySheet({super.key, required this.destination});

  final Destination destination;

  static Future<void> show(BuildContext context, Destination destination) =>
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        builder: (_) => SafetySheet(destination: destination),
      );

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final note = EmergencyDirectory.noteFor(destination);
    final actions = EmergencyDirectory.actionsFor(destination);
    final tips = EmergencyDirectory.tipsFor(destination);
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          0,
          20,
          20 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height * .88,
          child: ListView(
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: scheme.errorContainer,
                    child: Icon(
                      Icons.health_and_safety_outlined,
                      color: scheme.onErrorContainer,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Safety & emergency',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        Text(
                          destination.location,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: scheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Card(
                color: scheme.errorContainer,
                child: ListTile(
                  leading: Icon(
                    Icons.warning_amber_rounded,
                    color: scheme.onErrorContainer,
                  ),
                  title: Text(
                    'In an emergency call 999',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: scheme.onErrorContainer,
                    ),
                  ),
                  subtitle: Text(
                    'Police, fire and ambulance respond to a single number across Bangladesh.',
                    style: TextStyle(color: scheme.onErrorContainer),
                  ),
                  trailing: FilledButton(
                    onPressed: () => _call(context, '999'),
                    child: const Text('Call'),
                  ),
                ),
              ),
              if (note != null) ...[
                const SizedBox(height: 12),
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.info_outline),
                    title: Text('About ${destination.division}'),
                    subtitle: Text(note),
                  ),
                ),
              ],
              const SizedBox(height: 20),
              Text(
                'Emergency hotlines',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              ...EmergencyDirectory.nationalHotlines.map(
                (contact) => Card(
                  child: ListTile(
                    leading: Icon(_iconFor(contact.icon), color: scheme.primary),
                    title: Text(contact.label),
                    subtitle: contact.description == null
                        ? null
                        : Text(contact.description!),
                    trailing: TextButton.icon(
                      onPressed: () => _call(context, contact.number),
                      icon: const Icon(Icons.call, size: 18),
                      label: Text(contact.number),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Find help near ${destination.name}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              ...actions.map(
                (action) => Card(
                  child: ListTile(
                    leading: Icon(
                      _iconFor(action.icon),
                      color: scheme.primary,
                    ),
                    title: Text(action.label),
                    subtitle: Text(action.query),
                    trailing: const Icon(Icons.open_in_new),
                    onTap: () => _openSearch(context, action.query),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text('Safety tips', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              ...tips.map(
                (tip) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.check_circle_outline,
                        size: 18,
                        color: scheme.primary,
                      ),
                      const SizedBox(width: 10),
                      Expanded(child: Text(tip)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Numbers and availability can change. Confirm locally on arrival.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }

  static IconData _iconFor(EmergencyIcon icon) => switch (icon) {
    EmergencyIcon.phone => Icons.call,
    EmergencyIcon.police => Icons.local_police_outlined,
    EmergencyIcon.ambulance => Icons.local_hospital_outlined,
    EmergencyIcon.fire => Icons.local_fire_department_outlined,
    EmergencyIcon.women => Icons.volunteer_activism_outlined,
    EmergencyIcon.info => Icons.info_outline,
    EmergencyIcon.tourist => Icons.tour_outlined,
  };

  Future<void> _call(BuildContext context, String number) async {
    final uri = Uri(
      scheme: 'tel',
      path: number.replaceAll(RegExp(r'[^0-9+]'), ''),
    );
    final messenger = ScaffoldMessenger.of(context);
    try {
      final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched) throw Exception('not launched');
    } catch (_) {
      messenger.showSnackBar(
        SnackBar(content: Text('Call $number from your phone.')),
      );
    }
  }

  Future<void> _openSearch(BuildContext context, String query) async {
    final uri = Uri.https('www.google.com', '/maps/search/', {
      'api': '1',
      'query': query,
    });
    final messenger = ScaffoldMessenger.of(context);
    try {
      final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched) throw Exception('not launched');
    } catch (_) {
      messenger.showSnackBar(
        SnackBar(content: Text('Search online for "$query".')),
      );
    }
  }
}
