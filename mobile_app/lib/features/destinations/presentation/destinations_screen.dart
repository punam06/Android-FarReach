import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../auth/presentation/login_screen.dart';
import '../domain/spot.dart';
import '../presentation/spots_provider.dart';
import 'spot_detail_screen.dart';

/// Home screen listing all destinations fetched from /api/spots.
class DestinationsScreen extends StatefulWidget {
  const DestinationsScreen({super.key});

  @override
  State<DestinationsScreen> createState() => _DestinationsScreenState();
}

class _DestinationsScreenState extends State<DestinationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SpotsProvider>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SpotsProvider>();
    final spots = provider.spots;

    return Scaffold(
      appBar: AppBar(
        title: const Text('FarReach Tourism'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline),
            tooltip: 'Sign in',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const LoginScreen()),
            ),
          ),
        ],
      ),
      body: provider.loading
          ? const LoadingIndicator()
          : provider.error != null
              ? ErrorView(message: provider.error!, onRetry: () => provider.load())
              : RefreshIndicator(
                  onRefresh: () => provider.load(),
                  child: CustomScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: [
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                          child: TextField(
                            onChanged: provider.setQuery,
                            decoration: const InputDecoration(
                              hintText: 'Search destinations...',
                              prefixIcon: Icon(Icons.search),
                            ),
                          ),
                        ),
                      ),
                      SliverToBoxAdapter(
                        child: SizedBox(
                          height: 44,
                          child: ListView(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            children: provider.categories
                                .map((c) => Padding(
                                      padding: const EdgeInsets.only(right: 8),
                                      child: ChoiceChip(
                                        label: Text(c),
                                        selected: provider.category == c,
                                        onSelected: (_) => provider.setCategory(c),
                                        selectedColor: AppTheme.primary,
                                        labelStyle: TextStyle(
                                          color: provider.category == c
                                              ? Colors.white
                                              : null,
                                        ),
                                      ),
                                    ))
                                .toList(),
                          ),
                        ),
                      ),
                      if (spots.isEmpty)
                        const SliverFillRemaining(
                          hasScrollBody: false,
                          child: EmptyView(message: 'No destinations found.'),
                        )
                      else
                        _buildGrid(spots),
                    ],
                  ),
                ),
    );
  }

  Widget _buildGrid(List<Spot> spots) {
    return SliverPadding(
      padding: const EdgeInsets.all(16),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 260,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 0.78,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) => _SpotCard(spot: spots[index]),
          childCount: spots.length,
        ),
      ),
    );
  }
}

class _SpotCard extends StatelessWidget {
  final Spot spot;
  const _SpotCard({required this.spot});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => SpotDetailScreen(spot: spot)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: spot.image.isEmpty
                  ? Container(
                      color: Colors.black12,
                      child: const Icon(Icons.landscape, size: 48),
                    )
                  : Image.network(
                      ApiConstants.imageUrl(spot.image),
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: Colors.black12,
                        child: const Icon(Icons.broken_image, size: 40),
                      ),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    spot.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    [spot.districtName, spot.divisionName]
                        .where((s) => s.isNotEmpty)
                        .join(', '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

