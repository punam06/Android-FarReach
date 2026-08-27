import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/widgets/common_widgets.dart';
import 'bookings_provider.dart';

/// Lists the signed-in user's bookings.
class BookingsScreen extends StatefulWidget {
  const BookingsScreen({super.key});

  @override
  State<BookingsScreen> createState() => _BookingsScreenState();
}

class _BookingsScreenState extends State<BookingsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BookingsProvider>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BookingsProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('My Bookings')),
      body: provider.loading
          ? const LoadingIndicator()
          : provider.error != null
              ? ErrorView(message: provider.error!, onRetry: provider.load)
              : provider.bookings.isEmpty
                  ? const EmptyView(
                      message: 'You have no bookings yet.\n'
                          'Book a destination to see it here.')
                  : RefreshIndicator(
                      onRefresh: provider.load,
                      child: ListView.separated(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(16),
                        itemCount: provider.bookings.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final booking = provider.bookings[index];
                          final date = DateTime.tryParse(booking.createdAt);
                          return Card(
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: booking.status == 'confirmed'
                                    ? Colors.green.shade100
                                    : Colors.orange.shade100,
                                child: Icon(
                                  booking.status == 'confirmed'
                                      ? Icons.check_circle
                                      : Icons.schedule,
                                  color: booking.status == 'confirmed'
                                      ? Colors.green
                                      : Colors.deepOrange,
                                ),
                              ),
                              title: Text(
                                booking.spotName.isEmpty
                                    ? 'Booking #${booking.id}'
                                    : booking.spotName,
                              ),
                              subtitle: Text(
                                date == null
                                    ? booking.type
                                    : '${booking.type} • '
                                        '${DateFormat.yMMMd().format(date)}',
                              ),
                              trailing: booking.amount > 0
                                  ? Text(
                                      '৳${NumberFormat.decimalPattern().format(booking.amount)}')
                                  : null,
                              onLongPress: () async {
                                final ok = await provider.cancel(booking);
                                if (context.mounted) {
                                  showSnack(
                                    context,
                                    ok ? 'Booking cancelled' : 'Cancel failed',
                                    error: !ok,
                                  );
                                }
                              },
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}

