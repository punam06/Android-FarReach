import 'package:flutter/material.dart';

import '../models/destination.dart';
import '../services/api_client.dart';
import '../state/app_controller.dart';
import 'travel_tools_screen.dart';

class BookingManagementScreen extends StatefulWidget {
  const BookingManagementScreen({
    super.key,
    required this.controller,
    required this.booking,
  });
  final AppController controller;
  final Booking booking;
  @override
  State<BookingManagementScreen> createState() =>
      _BookingManagementScreenState();
}

class _BookingManagementScreenState extends State<BookingManagementScreen> {
  Map<String, dynamic>? _ticket, _quote;
  String? _error;
  bool _busy = true;
  DateTime? _date;
  late final TextEditingController _persons;
  @override
  void initState() {
    super.initState();
    _persons = TextEditingController(text: '${widget.booking.persons}');
    _date = DateTime.tryParse(widget.booking.date);
    _load();
  }

  @override
  void dispose() {
    _persons.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _busy = true;
      _error = null;
      _quote = null;
    });
    try {
      final data = await widget.controller.api.requestJson(
        '/api/user/bookings/${widget.booking.id}/ticket',
      );
      if (mounted) {
        setState(() {
          _ticket = Map<String, dynamic>.from(data['ticket'] as Map);
          _date = DateTime.tryParse('${_ticket!['booking_date']}');
          _persons.text = '${_ticket!['persons']}';
        });
      }
    } on ApiFailure catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _quoteOrSave() async {
    if (_date == null) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      if (_quote == null) {
        final data = await widget.controller.api.requestJson(
          '/api/bookings/quote',
          method: 'POST',
          body: {
            'spot_id': _ticket!['spot_id'],
            'persons': int.tryParse(_persons.text),
            'booking_date': dateOnly(_date!),
          },
        );
        if (mounted) {
          setState(
            () => _quote = Map<String, dynamic>.from(data['quote'] as Map),
          );
        }
      } else {
        await widget.controller.updateBooking(
          widget.booking.id,
          dateOnly(_date!),
          int.parse(_persons.text),
        );
        if (mounted) {
          await _load();
          if (mounted) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('Booking updated.')));
          }
        }
      }
    } on ApiFailure catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Booking & receipt')),
    body: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        if (_busy) const Center(child: CircularProgressIndicator()),
        if (_error != null)
          Text(
            _error!,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        if (_ticket == null && !_busy)
          OutlinedButton(onPressed: _load, child: const Text('Retry')),
        if (_ticket != null) ...[
          Text(
            '${_ticket!['spot_name']}',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 14),
          SelectableText(
            'Reference: ${_ticket!['reference'] ?? 'Legacy booking #${widget.booking.id}'}',
          ),
          Text('Traveler: ${_ticket!['traveler_name']}'),
          Text(
            'Date: ${_ticket!['booking_date']} · ${_ticket!['persons']} traveler(s)',
          ),
          Text('Status: ${_ticket!['status']} · ৳${_ticket!['price']} BDT'),
          Text(
            _ticket!['valid'] == true
                ? 'Confirmed reservation receipt'
                : 'Receipt is not valid for a confirmed reservation',
          ),
          const SizedBox(height: 14),
          Text('${_ticket!['note']}'),
          const Divider(height: 32),
          if (_ticket!['can_modify'] == true) ...[
            const Text(
              'Reschedule or change travelers. Changes require at least 24 hours before travel in Asia/Dhaka.',
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: _busy
                  ? null
                  : () async {
                      final tomorrow = DateTime.now().add(
                        const Duration(days: 1),
                      );
                      final picked = await showDatePicker(
                        context: context,
                        firstDate: DateTime(
                          tomorrow.year,
                          tomorrow.month,
                          tomorrow.day,
                        ),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                        initialDate: _date,
                      );
                      if (picked != null && mounted) {
                        setState(() {
                          _date = picked;
                          _quote = null;
                        });
                      }
                    },
              child: Text(_date == null ? 'Choose date' : dateOnly(_date!)),
            ),
            TextField(
              controller: _persons,
              enabled: !_busy,
              keyboardType: TextInputType.number,
              onChanged: (_) => setState(() => _quote = null),
              decoration: const InputDecoration(labelText: 'Travelers (1–20)'),
            ),
            const SizedBox(height: 14),
            if (_quote != null)
              Text('Updated server price: ৳${_quote!['total']} BDT'),
            FilledButton(
              onPressed: _busy ? null : _quoteOrSave,
              child: Text(
                _quote == null ? 'Review new price' : 'Confirm booking changes',
              ),
            ),
            OutlinedButton(
              onPressed: _busy
                  ? null
                  : () async {
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (c) => AlertDialog(
                          title: const Text('Cancel booking?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(c, false),
                              child: const Text('Keep'),
                            ),
                            FilledButton(
                              onPressed: () => Navigator.pop(c, true),
                              child: const Text('Cancel booking'),
                            ),
                          ],
                        ),
                      );
                      if (confirmed != true || !mounted) return;
                      setState(() {
                        _busy = true;
                        _error = null;
                      });
                      try {
                        await widget.controller.cancelBooking(
                          widget.booking.id,
                        );
                        if (mounted) await _load();
                      } on ApiFailure catch (e) {
                        if (mounted) setState(() => _error = e.message);
                      } finally {
                        if (mounted) setState(() => _busy = false);
                      }
                    },
              child: const Text('Cancel booking'),
            ),
          ] else
            const Text(
              'This booking is outside the change window or has been cancelled. Create a support ticket for further help.',
            ),
        ],
      ],
    ),
  );
}
