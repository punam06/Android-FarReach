import 'package:flutter/material.dart';

import '../models/destination.dart';
import '../state/app_controller.dart';
import '../widgets/destination_card.dart';
import '../widgets/destination_image.dart';
import 'destination_detail_screen.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key, required this.controller});

  final AppController controller;

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  final _searchController = TextEditingController();
  String _query = '';
  String _category = 'All';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: widget.controller,
    builder: (context, _) {
      final all = widget.controller.destinations;
      final categories =
          <String>{
              'All',
              ...all.map((item) => item.category),
            }.where((item) => item.isNotEmpty).toList()
            ..sort((a, b) => a == 'All' ? -1 : a.compareTo(b));
      final query = _query.toLowerCase();
      final filtered = all.where((item) {
        final matchesCategory =
            _category == 'All' || item.category == _category;
        final haystack =
            '${item.name} ${item.district} ${item.division} ${item.category}'
                .toLowerCase();
        return matchesCategory && (query.isEmpty || haystack.contains(query));
      }).toList();

      final width = MediaQuery.sizeOf(context).width;
      final columns = width >= 1180 ? 3 : (width >= 720 ? 2 : 1);
      final largeText = MediaQuery.textScalerOf(context).scale(1) > 1.3;
      return RefreshIndicator(
        onRefresh: widget.controller.refreshDestinations,
        child: CustomScrollView(
          key: const PageStorageKey('explore-scroll'),
          slivers: [
            SliverAppBar(
              pinned: true,
              expandedHeight: largeText ? 272 : 240,
              backgroundColor: const Color(0xFF075E4A),
              foregroundColor: Colors.white,
              surfaceTintColor: Colors.transparent,
              scrolledUnderElevation: 0,
              title: const Text('FarReach'),
              actions: [
                IconButton(
                  tooltip: 'Refresh destinations',
                  onPressed: widget.controller.loading
                      ? null
                      : widget.controller.refreshDestinations,
                  icon: const Icon(Icons.refresh),
                ),
                const SizedBox(width: 8),
              ],
              flexibleSpace: FlexibleSpaceBar(
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    DestinationImage(
                      destination: all.isEmpty
                          ? fallbackDestinations.first
                          : all.first,
                      baseUrl: widget.controller.api.baseUrl,
                    ),
                    const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Color(0x9900110D),
                            Color(0x3300110D),
                            Color(0xE6001E17),
                          ],
                          stops: [0, 0.42, 1],
                        ),
                      ),
                    ),
                    Positioned(
                      left: 24,
                      right: 24,
                      top:
                          MediaQuery.paddingOf(context).top +
                          kToolbarHeight +
                          8,
                      bottom: 22,
                      child: Align(
                        alignment: Alignment.bottomLeft,
                        child: Semantics(
                          header: true,
                          label: 'Find your next Bangladesh story. Local places, practical planning, memorable journeys.',
                          excludeSemantics: true,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Find your next\nBangladesh story',
                                maxLines: 2,
                                overflow: TextOverflow.fade,
                                style: Theme.of(context).textTheme.headlineLarge
                                    ?.copyWith(
                                      color: Colors.white,
                                      height: 1.02,
                                    ),
                              ),
                              if (!largeText) ...[
                                const SizedBox(height: 8),
                                Text(
                                  'Local places, practical planning, memorable journeys.',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(color: Colors.white),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (widget.controller.loading)
              const SliverToBoxAdapter(child: LinearProgressIndicator()),
            if (widget.controller.offline)
              SliverToBoxAdapter(
                child: _OfflineBanner(
                  updatedAt: widget.controller.lastUpdated,
                  onRetry: widget.controller.refreshDestinations,
                ),
              ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
              sliver: SliverToBoxAdapter(
                child: TextField(
                  controller: _searchController,
                  textInputAction: TextInputAction.search,
                  onChanged: (value) => setState(() => _query = value.trim()),
                  decoration: InputDecoration(
                    hintText: 'Search places, districts, or divisions',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _query.isEmpty
                        ? null
                        : IconButton(
                            tooltip: 'Clear search',
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _query = '');
                            },
                            icon: const Icon(Icons.close),
                          ),
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 58,
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 6,
                  ),
                  scrollDirection: Axis.horizontal,
                  itemCount: categories.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final category = categories[index];
                    return ChoiceChip(
                      label: Text(category),
                      selected: category == _category,
                      onSelected: (_) => setState(() => _category = category),
                    );
                  },
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 14),
              sliver: SliverToBoxAdapter(
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Explore Bangladesh',
                            style: Theme.of(context).textTheme.headlineMedium,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${filtered.length} places matched to your trip',
                          ),
                        ],
                      ),
                    ),
                    if (_query.isNotEmpty || _category != 'All')
                      TextButton(
                        onPressed: _clearFilters,
                        child: const Text('Clear all'),
                      ),
                  ],
                ),
              ),
            ),
            if (filtered.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: _EmptySearch(onClear: _clearFilters),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                sliver: SliverGrid.builder(
                  itemCount: filtered.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: columns,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    mainAxisExtent: 292,
                  ),
                  itemBuilder: (context, index) {
                    final destination = filtered[index];
                    return DestinationCard(
                      destination: destination,
                      baseUrl: widget.controller.api.baseUrl,
                      isSaved: widget.controller.isSaved(destination),
                      onOpen: () => _open(destination),
                      onToggleSaved: () => _toggleSaved(destination),
                    );
                  },
                ),
              ),
          ],
        ),
      );
    },
  );

  void _clearFilters() {
    _searchController.clear();
    setState(() {
      _query = '';
      _category = 'All';
    });
  }

  void _open(Destination destination) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => DestinationDetailScreen(
          controller: widget.controller,
          destination: destination,
        ),
      ),
    );
  }

  Future<void> _toggleSaved(Destination destination) async {
    final adding = !widget.controller.isSaved(destination);
    final synced = await widget.controller.toggleSaved(destination);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          adding
              ? synced
                    ? 'Saved to your FarReach account.'
                    : 'Saved on this device.'
              : 'Removed from saved places.',
        ),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () => widget.controller.toggleSaved(destination),
        ),
      ),
    );
  }
}

class _OfflineBanner extends StatelessWidget {
  const _OfflineBanner({required this.updatedAt, required this.onRetry});

  final DateTime? updatedAt;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final updated = updatedAt == null
        ? 'using the built-in travel guide'
        : 'showing saved data from ${updatedAt!.day}/${updatedAt!.month}';
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Semantics(
        container: true,
        label: 'Offline — $updated.',
        child: Material(
          color: Theme.of(context).colorScheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(14),
          child: SizedBox(
            height: 52,
            child: Padding(
              padding: const EdgeInsets.only(left: 14, right: 4),
              child: Row(
                children: [
                  Icon(
                    Icons.cloud_off_outlined,
                    size: 20,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 9),
                  const Expanded(
                    child: Text(
                      'Offline guide active',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: onRetry,
                    icon: const Icon(Icons.refresh, size: 18),
                    label: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptySearch extends StatelessWidget {
  const _EmptySearch({required this.onClear});

  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.travel_explore,
            size: 64,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 18),
          Text(
            'No places found',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          const Text(
            'Try another spelling or remove a filter to see more of Bangladesh.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 18),
          FilledButton.tonal(
            onPressed: onClear,
            child: const Text('Clear filters'),
          ),
        ],
      ),
    ),
  );
}
