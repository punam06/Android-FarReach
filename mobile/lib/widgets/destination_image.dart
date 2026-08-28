import 'package:flutter/material.dart';

import '../models/destination.dart';

class DestinationImage extends StatelessWidget {
  const DestinationImage({
    super.key,
    required this.destination,
    required this.baseUrl,
    this.fit = BoxFit.cover,
  });

  final Destination destination;
  final String baseUrl;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    final hasAsset = destination.assetPath.isNotEmpty;
    final placeholder = ColoredBox(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.landscape_outlined,
              size: 48,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 8),
            Text(
              'Photo unavailable',
              style: Theme.of(context).textTheme.labelMedium,
            ),
          ],
        ),
      ),
    );
    final fallback = hasAsset
        ? Image.asset(
            destination.assetPath,
            fit: fit,
            width: double.infinity,
            height: double.infinity,
            errorBuilder: (_, _, _) => placeholder,
          )
        : placeholder;
    final url = destination.imageUrl(baseUrl);
    return Semantics(
      image: true,
      label: 'View of ${destination.name}',
      child: url == null
          ? fallback
          : Image.network(
              url,
              fit: fit,
              width: double.infinity,
              height: double.infinity,
              frameBuilder: (context, child, frame, syncLoaded) =>
                  AnimatedOpacity(
                    opacity: syncLoaded || frame != null ? 1 : 0,
                    duration: const Duration(milliseconds: 250),
                    child: child,
                  ),
              loadingBuilder: (context, child, progress) => progress == null
                  ? child
                  : Stack(
                      fit: StackFit.expand,
                      children: [
                        fallback,
                        ColoredBox(color: Colors.black.withValues(alpha: 0.08)),
                        const Center(child: CircularProgressIndicator()),
                      ],
                    ),
              errorBuilder: (_, _, _) => fallback,
            ),
    );
  }
}
