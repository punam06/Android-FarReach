import 'package:flutter/material.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/widgets/common_widgets.dart';
import '../domain/spot.dart';

/// Details page for a single destination.
class SpotDetailScreen extends StatelessWidget {
  final Spot spot;

  const SpotDetailScreen({super.key, required this.spot});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 240,
            pinned: true,
            title: Text(spot.name),
            flexibleSpace: FlexibleSpaceBar(
              background: spot.image.isEmpty
                  ? Container(color: Colors.black12)
                  : Image.network(
                      ApiConstants.imageUrl(spot.image),
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          Container(color: Colors.black12),
                    ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList.list(
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (spot.category.isNotEmpty)
                      Chip(label: Text(spot.category)),
                    if (spot.budgetCategory.isNotEmpty)
                      Chip(label: Text('Budget: ${spot.budgetCategory}')),
                    if (spot.districtName.isNotEmpty)
                      Chip(label: Text(spot.districtName)),
                    if (spot.divisionName.isNotEmpty)
                      Chip(label: Text(spot.divisionName)),
                  ],
                ),
                const SizedBox(height: 16),
                if (spot.description.isNotEmpty) ...[
                  Text('About',
                      style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 6),
                  Text(spot.description),
                  const SizedBox(height: 16),
                ],
                if (spot.history.isNotEmpty) ...[
                  Text('History',
                      style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 6),
                  Text(spot.history),
                ],
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton.icon(
            icon: const Icon(Icons.book_online),
            label: const Text('Book this destination'),
            onPressed: () =>
                showSnack(context, 'Booking flow coming soon for ${spot.name}'),
          ),
        ),
      ),
    );
  }
}

