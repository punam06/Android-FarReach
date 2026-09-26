import 'package:flutter/material.dart';

import '../models/destination.dart';
import '../state/app_controller.dart';
import '../widgets/destination_card.dart';
import 'destination_detail_screen.dart';

class SavedScreen extends StatelessWidget {
  const SavedScreen({super.key, required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: controller,
    builder: (context, _) {
      final destinations = controller.savedDestinations;
      return Scaffold(
        appBar: AppBar(
          title: const Text('Saved places'),
          actions: [
            if (controller.isAuthenticated)
              const Padding(
                padding: EdgeInsets.only(right: 16),
                child: Tooltip(
                  message: 'Synced with your account when online',
                  child: Icon(Icons.cloud_done_outlined),
                ),
              ),
          ],
        ),
        body: destinations.isEmpty
            ? const _EmptySaved()
            : LayoutBuilder(
                builder: (context, constraints) {
                  final columns = constraints.maxWidth >= 1050
                      ? 3
                      : (constraints.maxWidth >= 650 ? 2 : 1);
                  return CustomScrollView(
                    key: const PageStorageKey('saved-scroll'),
                    slivers: [
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 14),
                        sliver: SliverToBoxAdapter(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Your shortlist',
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineMedium,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                '${destinations.length} places available even when you are offline.',
                              ),
                            ],
                          ),
                        ),
                      ),
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                        sliver: SliverGrid.builder(
                          itemCount: destinations.length,
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: columns,
                                crossAxisSpacing: 16,
                                mainAxisSpacing: 16,
                                mainAxisExtent: 292,
                              ),
                          itemBuilder: (context, index) {
                            final destination = destinations[index];
                            return DestinationCard(
                              destination: destination,
                              baseUrl: controller.api.baseUrl,
                              isSaved: true,
                              onOpen: () => _open(context, destination),
                              onToggleSaved: () =>
                                  controller.toggleSaved(destination),
                            );
                          },
                        ),
                      ),
                    ],
                  );
                },
              ),
      );
    },
  );

  void _open(BuildContext context, Destination destination) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => DestinationDetailScreen(
          controller: controller,
          destination: destination,
        ),
      ),
    );
  }
}

class _EmptySaved extends StatelessWidget {
  const _EmptySaved();

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 92,
              height: 92,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.secondaryContainer,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.favorite_border, size: 42),
            ),
            const SizedBox(height: 22),
            Text(
              'Build your Bangladesh shortlist',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 10),
            const Text(
              'Tap the heart on any destination. Saved places stay available on this device and sync after you sign in.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    ),
  );
}
