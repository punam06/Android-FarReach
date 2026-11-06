import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../data/local_guides.dart';
import '../models/destination.dart';
import '../state/app_controller.dart';

class _BookingSite {
  const _BookingSite({
    required this.name,
    required this.kind,
    required this.description,
    required this.profileUrl,
    required this.manageUrl,
    required this.icon,
  });

  final String name;
  final String kind;
  final String description;
  final String profileUrl;
  final String manageUrl;
  final IconData icon;
}

List<_BookingSite> _sitesFor(Destination destination) {
  final place = destination.name;
  final area = destination.district.isEmpty ? place : destination.district;
  final hotelQuery = Uri.encodeComponent('$place $area');
  final transportQuery = Uri.encodeComponent('travel tickets to $place');

  return [
    _BookingSite(
      name: 'Booking.com',
      kind: 'Hotel booking',
      description: 'Rooms, resorts and guesthouses around $place.',
      profileUrl: 'https://www.booking.com/searchresults.html?ss=$hotelQuery',
      manageUrl: 'https://secure.booking.com/mybooking.html',
      icon: Icons.hotel_outlined,
    ),
    _BookingSite(
      name: 'Agoda',
      kind: 'Hotel booking',
      description: 'Compare hotel prices and manage your Agoda reservation.',
      profileUrl:
          'https://www.agoda.com/search?text=${Uri.encodeComponent(place)}',
      manageUrl: 'https://www.agoda.com/mybookings',
      icon: Icons.apartment_outlined,
    ),
    _BookingSite(
      name: 'GoZayaan',
      kind: 'Hotel & flights',
      description: 'Bangladeshi booking portal for hotels, flights and tours.',
      profileUrl: 'https://www.gozayaan.com/hotel',
      manageUrl: 'https://www.gozayaan.com/',
      icon: Icons.flight_takeoff_outlined,
    ),
    _BookingSite(
      name: 'ShareTrip',
      kind: 'Hotel booking',
      description: 'Local hotel and resort bookings across Bangladesh.',
      profileUrl: 'https://sharetrip.net/hotel',
      manageUrl: 'https://sharetrip.net/',
      icon: Icons.travel_explore_outlined,
    ),
    _BookingSite(
      name: 'Bangladesh Railway',
      kind: 'Travel transport',
      description: 'Intercity train tickets and journey schedule changes.',
      profileUrl: 'https://eticket.railway.gov.bd',
      manageUrl: 'https://eticket.railway.gov.bd',
      icon: Icons.train_outlined,
    ),
    _BookingSite(
      name: 'Shohoz',
      kind: 'Bus, launch & ferry',
      description: 'Coach, launch and ferry tickets for the journey to $place.',
      profileUrl: 'https://www.shohoz.com',
      manageUrl: 'https://www.shohoz.com',
      icon: Icons.directions_bus_outlined,
    ),
    _BookingSite(
      name: 'Local transport directory',
      kind: 'Travel transport',
      description: 'Find jeep, car and microbus operators near $place.',
      profileUrl:
          'https://www.google.com/search?q=${Uri.encodeComponent('transport operators $place $area')}',
      manageUrl:
          'https://www.google.com/search?q=${Uri.encodeComponent('book transport $transportQuery $area')}',
      icon: Icons.local_taxi_outlined,
    ),
  ];
}

/// Lets a traveler review the partner websites used for a booking, open their
/// profile or booking-management pages, edit the trip schedule, and reach the
/// recommended local guides.
class BookingModificationSheet extends StatefulWidget {
  const BookingModificationSheet({
    super.key,
    required this.controller,
    required this.booking,
  });

  final AppController controller;
  final Booking booking;

  static Future<void> show(
    BuildContext context, {
    required AppController controller,
    required Booking booking,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) =>
          BookingModificationSheet(controller: controller, booking: booking),
    );
  }

  @override
  State<BookingModificationSheet> createState() =>
      _BookingModificationSheetState();
}

class _BookingModificationSheetState extends State<BookingModificationSheet> {
  late final Destination _destination;
  late final List<_BookingSite> _sites;
  late DateTime _travelDate;
  late DateTime _checkIn;
  late DateTime _checkOut;
  int _siteIndex = 0;

  @override
  void initState() {
    super.initState();
    _destination =
        widget.controller.destinationForBooking(widget.booking.spotName) ??
        Destination(
          id: 0,
          name: widget.booking.spotName,
          category: 'Explore',
          description: '',
          history: '',
          district: '',
          division: '',
          budget: 'Mid',
          image: '',
          assetPath: '',
        );
    _sites = _sitesFor(_destination);
    final bookedDate = DateTime.tryParse(widget.booking.date);
    _travelDate = bookedDate ?? DateTime.now().add(const Duration(days: 3));
    _checkIn = _travelDate;
    _checkOut = _travelDate.add(const Duration(days: 2));
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.sizeOf(context).height * 0.88;
    return SizedBox(
      height: height,
      child: DefaultTabController(
        length: 3,
        child: Column(
          children: [
            _buildHeader(context),
            const TabBar(
              isScrollable: true,
              tabs: [
                Tab(icon: Icon(Icons.link_outlined), text: 'Booking sites'),
                Tab(icon: Icon(Icons.edit_calendar_outlined), text: 'Schedule'),
                Tab(icon: Icon(Icons.support_agent_outlined), text: 'Guides'),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _buildSites(context),
                  _buildSchedule(context),
                  _buildGuides(context),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 10, 20, 8),
    child: Column(
      children: [
        Center(
          child: Container(
            width: 42,
            height: 4,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.outlineVariant,
              borderRadius: BorderRadius.circular(99),
            ),
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Modify booking',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${widget.booking.spotName} · ${_formatDate(_travelDate)}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            Chip(
              avatar: const Icon(Icons.confirmation_number_outlined, size: 16),
              label: Text('#${widget.booking.id}'),
            ),
          ],
        ),
      ],
    ),
  );

  Widget _buildSites(BuildContext context) => ListView(
    padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
    children: [
      Card(
        color: Theme.of(
          context,
        ).colorScheme.secondaryContainer.withValues(alpha: 0.45),
        child: const Padding(
          padding: EdgeInsets.all(14),
          child: Row(
            children: [
              Icon(Icons.info_outline, size: 20),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Bookings are handled by the partner websites below. Open a '
                  'site profile to view its booking list, or use its booking '
                  'management page to change your stay or travel schedule.',
                  style: TextStyle(fontSize: 13),
                ),
              ),
            ],
          ),
        ),
      ),
      const SizedBox(height: 12),
      ..._sites.map(
        (site) => Card(
          margin: const EdgeInsets.only(bottom: 10),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: Theme.of(
                        context,
                      ).colorScheme.primaryContainer,
                      child: Icon(
                        site.icon,
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            site.name,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          Text(
                            site.kind,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  site.description,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _openLink(context, site.profileUrl),
                        icon: const Icon(Icons.person_outline, size: 16),
                        label: const Text('View profile'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: FilledButton.tonalIcon(
                        onPressed: () => _openLink(context, site.manageUrl),
                        icon: const Icon(Icons.open_in_new, size: 16),
                        label: const Text('My bookings'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    ],
  );

  Widget _buildSchedule(BuildContext context) => ListView(
    padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
    children: [
      Card(
        color: Theme.of(
          context,
        ).colorScheme.primaryContainer.withValues(alpha: 0.45),
        child: const Padding(
          padding: EdgeInsets.all(14),
          child: Row(
            children: [
              Icon(Icons.edit_calendar_outlined, size: 20),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Plan the new schedule here, then finish the change on the '
                  'website where you booked the travel or hotel.',
                  style: TextStyle(fontSize: 13),
                ),
              ),
            ],
          ),
        ),
      ),
      const SizedBox(height: 12),
      _scheduleTile(
        context,
        label: 'Travel date',
        icon: Icons.event_outlined,
        value: _travelDate,
        onTap: () => _pickDate(
          initial: _travelDate,
          onPicked: (picked) {
            _travelDate = picked;
            if (_checkIn.isBefore(picked)) _checkIn = picked;
            if (_checkOut.isBefore(_checkIn)) {
              _checkOut = _checkIn.add(const Duration(days: 2));
            }
          },
        ),
      ),
      _scheduleTile(
        context,
        label: 'Hotel check-in',
        icon: Icons.login_outlined,
        value: _checkIn,
        onTap: () => _pickDate(
          initial: _checkIn,
          onPicked: (picked) {
            _checkIn = picked;
            if (_checkOut.isBefore(_checkIn)) {
              _checkOut = _checkIn.add(const Duration(days: 1));
            }
          },
        ),
      ),
      _scheduleTile(
        context,
        label: 'Hotel check-out',
        icon: Icons.logout_outlined,
        value: _checkOut,
        onTap: () => _pickDate(
          initial: _checkOut,
          onPicked: (picked) {
            _checkOut = picked.isBefore(_checkIn)
                ? _checkIn.add(const Duration(days: 1))
                : picked;
          },
        ),
      ),
      const SizedBox(height: 12),
      Text('Booked website', style: Theme.of(context).textTheme.titleSmall),
      const SizedBox(height: 8),
      DropdownButtonFormField<int>(
        initialValue: _siteIndex,
        isExpanded: true,
        decoration: const InputDecoration(
          labelText: 'Open the website used for this booking',
          border: OutlineInputBorder(),
        ),
        items: [
          for (var index = 0; index < _sites.length; index++)
            DropdownMenuItem(
              value: index,
              child: Text('${_sites[index].name} · ${_sites[index].kind}'),
            ),
        ],
        onChanged: (value) => setState(() => _siteIndex = value ?? _siteIndex),
      ),
      const SizedBox(height: 12),
      Card(
        child: ListTile(
          leading: const Icon(Icons.receipt_long_outlined),
          title: const Text('Updated schedule plan'),
          subtitle: Text(
            'Travel ${_formatDate(_travelDate)} · '
            'stay ${_formatDate(_checkIn)} to ${_formatDate(_checkOut)} · '
            '${widget.booking.persons} traveler(s)',
          ),
        ),
      ),
      const SizedBox(height: 12),
      SizedBox(
        width: double.infinity,
        child: FilledButton.icon(
          onPressed: () => _openLink(context, _sites[_siteIndex].manageUrl),
          icon: const Icon(Icons.open_in_new),
          label: Text(
            'Open ${_sites[_siteIndex].name} to change schedule',
            textAlign: TextAlign.center,
          ),
        ),
      ),
      const SizedBox(height: 6),
      Text(
        'Your partner website sends the final confirmation after the change.',
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodySmall,
      ),
    ],
  );

  Widget _buildGuides(BuildContext context) {
    final guides = localGuidesFor(_destination);
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
      children: [
        Card(
          color: Theme.of(
            context,
          ).colorScheme.tertiaryContainer.withValues(alpha: 0.45),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                const Icon(Icons.support_agent_outlined, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Contact the local guides around ${_destination.name} '
                    'directly to adjust your tour or arrange a new itinerary.',
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        ...guides.map(
          (guide) => Card(
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
                  _contactRow(
                    context,
                    icon: Icons.mail_outline,
                    label: guide.email,
                    onTap: () => _openLink(context, 'mailto:${guide.email}'),
                  ),
                  _contactRow(
                    context,
                    icon: Icons.call_outlined,
                    label: guide.phone,
                    onTap: () => _openLink(
                      context,
                      'tel:${guide.phone.replaceAll(' ', '')}',
                    ),
                  ),
                  const SizedBox(height: 6),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () =>
                          _openLink(context, guide.profileUri.toString()),
                      icon: const Icon(Icons.person_search_outlined, size: 16),
                      label: const Text('View guide profile'),
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

  Widget _contactRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(8),
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 8),
          Expanded(child: Text(label, style: const TextStyle(fontSize: 13))),
          const Icon(Icons.chevron_right, size: 18),
        ],
      ),
    ),
  );

  Widget _scheduleTile(
    BuildContext context, {
    required String label,
    required IconData icon,
    required DateTime value,
    required VoidCallback onTap,
  }) => Card(
    margin: const EdgeInsets.only(bottom: 8),
    child: ListTile(
      leading: Icon(icon),
      title: Text(label),
      subtitle: Text(_formatDate(value)),
      trailing: const Icon(Icons.edit_outlined),
      onTap: onTap,
    ),
  );

  Future<void> _pickDate({
    required DateTime initial,
    required ValueChanged<DateTime> onPicked,
  }) async {
    final now = DateTime.now();
    final firstDate = DateTime(now.year, now.month, now.day);
    final picked = await showDatePicker(
      context: context,
      initialDate: initial.isBefore(firstDate) ? firstDate : initial,
      firstDate: firstDate,
      lastDate: firstDate.add(const Duration(days: 365)),
    );
    if (picked != null && mounted) {
      setState(() => onPicked(picked));
    }
  }

  Future<void> _openLink(BuildContext context, String value) async {
    final uri = Uri.tryParse(value.trim());
    if (uri == null) {
      _showLinkError(context);
      return;
    }
    try {
      final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!opened && context.mounted) _showLinkError(context);
    } catch (_) {
      if (context.mounted) _showLinkError(context);
    }
  }

  void _showLinkError(BuildContext context) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Could not open this link.')));
  }
}

String _formatDate(DateTime date) => '${date.day}/${date.month}/${date.year}';
