import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/trip_request.dart';
import '../services/api_client.dart';
import '../state/app_controller.dart';

class TripRequestsScreen extends StatefulWidget {
  const TripRequestsScreen({
    super.key,
    required this.controller,
    this.admin = false,
  });
  final AppController controller;
  final bool admin;
  @override
  State<TripRequestsScreen> createState() => _TripRequestsScreenState();
}

class _TripRequestsScreenState extends State<TripRequestsScreen> {
  List<TripRequest> _trips = [];
  bool _busy = true;
  String? _error;
  int _page = 1, _total = 0;
  String get _root =>
      widget.admin ? '/api/admin/trip-requests' : '/api/user/trip-requests';
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final data = await widget.controller.api.requestJson(
        '$_root?page=$_page&limit=25',
      );
      if (mounted) {
        setState(() {
          _trips = (data['trips'] as List)
              .map((v) => TripRequest(Map<String, dynamic>.from(v as Map)))
              .toList();
          _total = (data['pagination'] as Map)['total'] as int;
        });
      }
    } on ApiFailure catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(widget.admin ? 'Trip operations' : 'My trip requests'),
      actions: [
        IconButton(
          onPressed: _busy ? null : _load,
          icon: const Icon(Icons.refresh),
        ),
      ],
    ),
    floatingActionButton: widget.admin
        ? null
        : FloatingActionButton.extended(
            onPressed: () async {
              final created = await Navigator.push<bool>(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      RequestTripScreen(controller: widget.controller),
                ),
              );
              if (created == true && mounted) {
                _page = 1;
                _load();
              }
            },
            icon: const Icon(Icons.add),
            label: const Text('Request a trip'),
          ),
    body: _busy
        ? const Center(child: CircularProgressIndicator())
        : RefreshIndicator(
            onRefresh: _load,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 110),
              children: [
                const Text(
                  'Request a trip, review an itemized quote, then track supplier confirmation. Payments are arranged separately with the travel team.',
                ),
                if (_error != null) _TripError(_error!),
                if (_trips.isEmpty && _error == null)
                  const Padding(
                    padding: EdgeInsets.all(24),
                    child: Text('No trip requests yet.'),
                  ),
                ..._trips.map(
                  (trip) => Card(
                    child: ListTile(
                      leading: const Icon(Icons.travel_explore),
                      title: Text('${trip.origin} → ${trip.destination}'),
                      subtitle: Text(
                        '${trip.startDate} – ${trip.endDate}\n${tripLabel(trip.status)} · ${trip.reference}',
                      ),
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => TripRequestDetailScreen(
                              api: widget.controller.api,
                              id: trip.id,
                              admin: widget.admin,
                            ),
                          ),
                        );
                        if (mounted) _load();
                      },
                    ),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: _page > 1
                          ? () {
                              _page--;
                              _load();
                            }
                          : null,
                      child: const Text('Previous'),
                    ),
                    Text('Page $_page'),
                    TextButton(
                      onPressed: _page * 25 < _total
                          ? () {
                              _page++;
                              _load();
                            }
                          : null,
                      child: const Text('Next'),
                    ),
                  ],
                ),
              ],
            ),
          ),
  );
}

class RequestTripScreen extends StatefulWidget {
  const RequestTripScreen({
    super.key,
    required this.controller,
    this.destination = '',
  });
  final AppController controller;
  final String destination;
  @override
  State<RequestTripScreen> createState() => _RequestTripScreenState();
}

class _RequestTripScreenState extends State<RequestTripScreen> {
  final _form = GlobalKey<FormState>();
  final _origin = TextEditingController(text: 'Dhaka'),
      _adults = TextEditingController(text: '1'),
      _children = TextEditingController(text: '0');
  final _budget = TextEditingController(),
      _requirements = TextEditingController();
  late final TextEditingController _destination, _name, _phone;
  String _service = 'package', _provider = 'farreach';
  DateTime? _start, _end;
  bool _busy = false;
  String? _error, _lastBody, _requestKey;
  @override
  void initState() {
    super.initState();
    _destination = TextEditingController(text: widget.destination);
    _name = TextEditingController(text: widget.controller.user?.name ?? '');
    _phone = TextEditingController(text: widget.controller.user?.phone ?? '');
  }

  @override
  void dispose() {
    for (final c in [
      _origin,
      _destination,
      _adults,
      _children,
      _budget,
      _requirements,
      _name,
      _phone,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  String _date(DateTime value) =>
      '${value.year}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';
  Future<void> _pick(bool start) async {
    final now = DateUtils.dateOnly(DateTime.now());
    final first = start
        ? now.add(const Duration(days: 1))
        : (_start ?? now.add(const Duration(days: 1)));
    final selected = await showDatePicker(
      context: context,
      firstDate: first,
      lastDate: now.add(const Duration(days: 365)),
      initialDate: start
          ? (_start ?? first)
          : (_end != null && !_end!.isBefore(first) ? _end! : first),
    );
    if (selected != null && mounted) {
      setState(() {
        if (start) {
          _start = selected;
          if (_end != null && _end!.isBefore(selected)) _end = null;
        } else {
          _end = selected;
        }
      });
    }
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    if (_start == null || _end == null) {
      setState(() => _error = 'Choose both travel dates.');
      return;
    }
    if (_end!.difference(_start!).inDays > 30 ||
        (_service == 'hotel' && _end == _start)) {
      setState(
        () => _error =
            'Trips can be up to 30 nights. Hotels require at least one night.',
      );
      return;
    }
    final adults = int.parse(_adults.text),
        children = int.parse(_children.text);
    if (adults + children > 20) {
      setState(() => _error = 'Choose at most 20 travelers.');
      return;
    }
    final body = <String, dynamic>{
      'origin': _origin.text.trim(),
      'destination': _destination.text.trim(),
      'service': _service,
      'provider': _provider,
      'start_date': _date(_start!),
      'end_date': _date(_end!),
      'adults': adults,
      'children': children,
      'budget_paisa': _budget.text.trim().isEmpty
          ? null
          : parseTripMoney(_budget.text),
      'contact_name': _name.text.trim(),
      'contact_phone': _phone.text.trim(),
      'requirements': _requirements.text.trim(),
    };
    final encoded = jsonEncode(body);
    if (_lastBody != encoded) {
      _lastBody = encoded;
      _requestKey = List.generate(
        24,
        (_) => Random.secure().nextInt(256).toRadixString(16).padLeft(2, '0'),
      ).join();
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final result = await widget.controller.api.requestJson(
        '/api/trip-requests',
        method: 'POST',
        body: body,
        headers: {'Idempotency-Key': _requestKey!},
      );
      if (mounted) {
        final id = (result['trip'] as Map)['id'] as int;
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                TripRequestDetailScreen(api: widget.controller.api, id: id),
          ),
        );
        if (mounted) Navigator.pop(context, true);
      }
    } on ApiFailure catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Widget _field(
    TextEditingController controller,
    String label, {
    int max = 150,
    bool optional = false,
    TextInputType? keyboard,
    String? Function(String?)? validator,
    int lines = 1,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: TextFormField(
      controller: controller,
      enabled: !_busy,
      maxLength: max,
      maxLines: lines,
      keyboardType: keyboard,
      decoration: InputDecoration(labelText: label),
      validator:
          validator ??
          (v) =>
              !optional && (v?.trim().isEmpty ?? true) ? 'Enter $label' : null,
    ),
  );
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Request a trip')),
    body: Form(
      key: _form,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'Tell us what you need. The travel team will send a quote for your review. Submitting this form does not reserve inventory or charge you.',
          ),
          const SizedBox(height: 18),
          DropdownButtonFormField<String>(
            initialValue: _service,
            decoration: const InputDecoration(labelText: 'Travel service'),
            items: ['package', 'hotel', 'flight', 'transport']
                .map(
                  (v) => DropdownMenuItem(value: v, child: Text(tripLabel(v))),
                )
                .toList(),
            onChanged: _busy ? null : (v) => setState(() => _service = v!),
          ),
          const SizedBox(height: 14),
          DropdownButtonFormField<String>(
            initialValue: _provider,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Preferred provider'),
            items: const [
              DropdownMenuItem(
                value: 'farreach',
                child: Text('FarReach travel team'),
              ),
              DropdownMenuItem(value: 'trip_com', child: Text('Trip.com')),
              DropdownMenuItem(value: 'gozayaan', child: Text('GoZayaan')),
            ],
            onChanged: _busy ? null : (v) => setState(() => _provider = v!),
          ),
          if (_provider != 'farreach') ...[
            const SizedBox(height: 8),
            const Text(
              'Your preference goes to the FarReach team. To book independently, open the provider’s website.',
            ),
            TextButton.icon(
              onPressed: _busy
                  ? null
                  : () async {
                      final uri = Uri.parse(
                        _provider == 'trip_com'
                            ? 'https://www.trip.com/'
                            : 'https://www.gozayaan.com/',
                      );
                      try {
                        if (!await launchUrl(
                              uri,
                              mode: LaunchMode.externalApplication,
                            ) &&
                            mounted) {
                          setState(
                            () =>
                                _error = 'Could not open the provider website.',
                          );
                        }
                      } catch (_) {
                        if (mounted) {
                          setState(
                            () =>
                                _error = 'Could not open the provider website.',
                          );
                        }
                      }
                    },
              icon: const Icon(Icons.open_in_new),
              label: const Text('Open provider website'),
            ),
          ],
          const SizedBox(height: 18),
          _field(_origin, 'Origin'),
          _field(_destination, 'Destination'),
          OutlinedButton(
            onPressed: _busy ? null : () => _pick(true),
            child: Text(
              _start == null
                  ? 'Choose departure date'
                  : 'Departure: ${_date(_start!)}',
            ),
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: _busy ? null : () => _pick(false),
            child: Text(
              _end == null
                  ? 'Choose return / checkout date'
                  : 'Return / checkout: ${_date(_end!)}',
            ),
          ),
          const SizedBox(height: 18),
          _field(
            _adults,
            'Adults',
            max: 2,
            keyboard: TextInputType.number,
            validator: (v) =>
                int.tryParse(v ?? '') != null &&
                    int.parse(v!) >= 1 &&
                    int.parse(v) <= 20
                ? null
                : 'Enter 1–20 adults',
          ),
          _field(
            _children,
            'Children',
            max: 2,
            keyboard: TextInputType.number,
            validator: (v) =>
                int.tryParse(v ?? '') != null &&
                    int.parse(v!) >= 0 &&
                    int.parse(v) <= 19
                ? null
                : 'Enter 0–19 children',
          ),
          _field(
            _budget,
            'Total budget in BDT (optional)',
            max: 11,
            optional: true,
            keyboard: const TextInputType.numberWithOptions(decimal: true),
            validator: (v) =>
                v?.trim().isEmpty == true || parseTripMoney(v ?? '') != null
                ? null
                : 'Enter an amount up to ৳10,000,000',
          ),
          _field(_name, 'Contact name', max: 100),
          _field(
            _phone,
            'Contact phone',
            max: 30,
            keyboard: TextInputType.phone,
          ),
          _field(
            _requirements,
            'Preferences and special requirements',
            max: 5000,
            optional: true,
            lines: 4,
          ),
          if (_error != null) _TripError(_error!),
          FilledButton(
            onPressed: _busy ? null : _submit,
            child: Text(_busy ? 'Submitting…' : 'Submit trip request'),
          ),
        ],
      ),
    ),
  );
}

class TripRequestDetailScreen extends StatefulWidget {
  const TripRequestDetailScreen({
    super.key,
    required this.api,
    required this.id,
    this.admin = false,
  });
  final ApiClient api;
  final int id;
  final bool admin;
  @override
  State<TripRequestDetailScreen> createState() =>
      _TripRequestDetailScreenState();
}

class _TripRequestDetailScreenState extends State<TripRequestDetailScreen> {
  TripDetail? _detail;
  String? _error;
  bool _busy = true;
  String get _path =>
      '${widget.admin ? '/api/admin/trip-requests' : '/api/user/trip-requests'}/${widget.id}';
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final data = await widget.api.requestJson(_path);
      if (mounted) setState(() => _detail = TripDetail(data));
    } on ApiFailure catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _action(String action, Map<String, dynamic> body) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.api.requestJson(
        '$_path/$action',
        method: 'POST',
        body: {'version': _detail!.trip.version, ...body},
      );
      await _load();
    } on ApiFailure catch (e) {
      // A conflict requires a new review. Never retry acceptance automatically.
      if (e.statusCode == 409 && mounted) await _load();
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _accept(TripQuote quote) async {
    final approved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Accept quote for ${tripMoney(quote.total)}?'),
        content: SingleChildScrollView(
          child: Text(
            '${quote.cancellationPolicy}\n\nBy accepting, you agree to this quote and its cancellation terms. The team must still confirm availability. No payment will be collected here.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Back'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Agree & accept'),
          ),
        ],
      ),
    );
    if (approved == true && mounted) {
      await _action('accept', {'quote_id': quote.id, 'accept_terms': true});
    }
  }

  Future<void> _cancel() async {
    final result = await _tripForm(
      context,
      title: _detail!.trip.status == 'confirmed'
          ? 'Request cancellation'
          : 'Cancel trip request',
      fields: const {'reason': 'Reason'},
      submit: 'Submit cancellation',
    );
    if (result != null && mounted) await _action('cancel', result);
  }

  Future<void> _publish() async {
    final result = await _tripForm(
      context,
      title: 'Publish itemized quote',
      fields: const {
        'line_items': 'One item per line: label | quantity | unit price in BDT',
        'itinerary': 'Itinerary and inclusions',
        'cancellation_policy': 'Cancellation and refund terms',
        'valid_hours': 'Valid for hours (1–168)',
      },
      submit: 'Publish quote',
      initial: const {'valid_hours': '24'},
      multiline: const {'line_items', 'itinerary', 'cancellation_policy'},
      validate: (fields) {
        try {
          _parseItems(fields['line_items']!);
        } on FormatException catch (e) {
          return e.message;
        }
        final hours = int.tryParse(fields['valid_hours']!);
        return hours == null || hours < 1 || hours > 168
            ? 'Enter 1–168 hours'
            : null;
      },
    );
    if (result != null && mounted) {
      await _action('quotes', {
        'line_items': _parseItems(result['line_items']!),
        'itinerary': result['itinerary'],
        'cancellation_policy': result['cancellation_policy'],
        'valid_hours': int.parse(result['valid_hours']!),
      });
    }
  }

  List<Map<String, dynamic>> _parseItems(String text) {
    final lines = text.trim().split('\n');
    if (lines.length > 20) {
      throw const FormatException('Use at most 20 line items');
    }
    final result = <Map<String, dynamic>>[];
    var total = 0;
    for (final line in lines) {
      final parts = line.split('|').map((v) => v.trim()).toList();
      if (parts.length != 3 || parts[0].isEmpty || parts[0].length > 150) {
        throw const FormatException(
          'Use label | quantity | unit price in BDT for each line',
        );
      }
      final quantity = int.tryParse(parts[1]), unit = parseTripMoney(parts[2]);
      if (quantity == null || quantity < 1 || quantity > 100 || unit == null) {
        throw const FormatException('Check quantities (1–100) and BDT amounts');
      }
      total += quantity * unit;
      if (total > 1000000000) {
        throw const FormatException('Quote total must be at most ৳10,000,000');
      }
      result.add({'label': parts[0], 'quantity': quantity, 'unit_paisa': unit});
    }
    return result;
  }

  Future<void> _confirm() async {
    final fields = await _tripForm(
      context,
      title: 'Record supplier confirmation',
      fields: const {
        'supplier_reference': 'Actual supplier confirmation reference',
        'confirmation_details':
            'Confirmed itinerary, property / transport and contact details',
      },
      multiline: const {'confirmation_details'},
      submit: 'Record confirmation',
    );
    if (fields != null && mounted) await _action('confirm', fields);
  }

  Future<void> _close(String status) async {
    final fields = await _tripForm(
      context,
      title: status == 'cancelled'
          ? 'Confirm supplier cancellation'
          : 'Reject trip request',
      fields: const {'reason': 'Reason and refund / cancellation outcome'},
      multiline: const {'reason'},
      submit: 'Confirm',
    );
    if (fields != null && mounted) {
      await _action('close', {'status': status, ...fields});
    }
  }

  @override
  Widget build(BuildContext context) {
    final detail = _detail, trip = detail?.trip, quote = detail?.currentQuote;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Trip request'),
        actions: [
          IconButton(
            onPressed: _busy ? null : _load,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _busy
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                if (_error != null) _TripError(_error!),
                if (trip != null) ...[
                  Text(
                    '${trip.origin} → ${trip.destination}',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  SelectableText(trip.reference),
                  Text(
                    '${trip.startDate} – ${trip.endDate}\n${trip.data['adults']} adults · ${trip.data['children']} children',
                  ),
                  const SizedBox(height: 12),
                  Chip(label: Text(tripLabel(trip.status))),
                  Text(
                    'Service: ${tripLabel('${trip.data['service']}')}\nProvider preference: ${tripLabel('${trip.data['provider']}')}\nContact: ${trip.data['contact_name']} · ${trip.data['contact_phone']}',
                  ),
                  if (trip.data['budget_paisa'] != null)
                    Text(
                      'Total budget: ${tripMoney(trip.data['budget_paisa'] as int)}',
                    ),
                  if ('${trip.data['requirements']}'.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Text('${trip.data['requirements']}'),
                    ),
                  const Text(
                    'Handled by the FarReach team. No automatic supplier booking or in-app payment.',
                  ),
                  if (quote != null)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'Quote: ${tripMoney(quote.total)}',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            ...quote.items.map(
                              (item) => Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  '${item['label']}\n${item['quantity']} × ${tripMoney(item['unit_paisa'] as int)} = ${tripMoney((item['quantity'] as int) * (item['unit_paisa'] as int))}',
                                ),
                              ),
                            ),
                            const SizedBox(height: 14),
                            Text(quote.itinerary),
                            const SizedBox(height: 12),
                            const Text('Cancellation terms'),
                            Text(quote.cancellationPolicy),
                            const SizedBox(height: 12),
                            Text(
                              'Expires: ${quote.expiresAt.toLocal()}${quote.expired ? ' (expired)' : ''}',
                            ),
                            if (trip.status == 'quoted' && !widget.admin)
                              FilledButton(
                                onPressed: quote.expired
                                    ? null
                                    : () => _accept(quote),
                                child: const Text('Review & accept quote'),
                              ),
                            if (trip.status == 'awaiting_confirmation')
                              const Text(
                                'You accepted this quote. Waiting for supplier confirmation.',
                              ),
                          ],
                        ),
                      ),
                    ),
                  if (trip.data['supplier_reference'] != null)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Supplier reference: ${trip.data['supplier_reference']}',
                            ),
                            const SizedBox(height: 8),
                            SelectableText(
                              '${trip.data['confirmation_details']}',
                            ),
                          ],
                        ),
                      ),
                    ),
                  if (!widget.admin && trip.canCancel)
                    OutlinedButton(
                      onPressed: _cancel,
                      child: Text(
                        trip.status == 'confirmed'
                            ? 'Request cancellation'
                            : 'Cancel trip request',
                      ),
                    ),
                  if (widget.admin &&
                      ['requested', 'quoted'].contains(trip.status))
                    FilledButton(
                      onPressed: _publish,
                      child: const Text('Publish quote'),
                    ),
                  if (widget.admin && trip.status == 'awaiting_confirmation')
                    FilledButton(
                      onPressed: _confirm,
                      child: const Text('Record supplier confirmation'),
                    ),
                  if (widget.admin &&
                      [
                        'requested',
                        'quoted',
                        'awaiting_confirmation',
                      ].contains(trip.status))
                    OutlinedButton(
                      onPressed: () => _close('rejected'),
                      child: const Text('Reject request'),
                    ),
                  if (widget.admin && trip.status == 'cancellation_requested')
                    FilledButton(
                      onPressed: () => _close('cancelled'),
                      child: const Text('Record supplier cancellation'),
                    ),
                  const SizedBox(height: 24),
                  Text(
                    'Status history',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  ...detail!.events.map(
                    (event) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.history),
                      title: Text('${event['message']}'),
                      subtitle: Text(
                        '${tripLabel('${event['actor_role']}')} · ${event['created_at']}',
                      ),
                    ),
                  ),
                ],
              ],
            ),
    );
  }
}

Future<Map<String, String>?> _tripForm(
  BuildContext context, {
  required String title,
  required Map<String, String> fields,
  required String submit,
  Map<String, String> initial = const {},
  Set<String> multiline = const {},
  String? Function(Map<String, String>)? validate,
}) async {
  final controllers = {
    for (final key in fields.keys)
      key: TextEditingController(text: initial[key] ?? ''),
  };
  final form = GlobalKey<FormState>();
  String? error;
  final result = await showDialog<Map<String, String>>(
    context: context,
    builder: (dialog) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: Text(title),
        content: SizedBox(
          width: 500,
          child: SingleChildScrollView(
            child: Form(
              key: form,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ...fields.entries.map(
                    (entry) => Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: TextFormField(
                        controller: controllers[entry.key],
                        maxLines: multiline.contains(entry.key) ? 4 : 1,
                        maxLength: entry.key == 'valid_hours'
                            ? 3
                            : entry.key == 'supplier_reference'
                            ? 100
                            : 5000,
                        decoration: InputDecoration(
                          labelText: entry.value,
                          alignLabelWithHint: true,
                        ),
                        validator: (v) =>
                            v?.trim().isNotEmpty == true ? null : 'Required',
                      ),
                    ),
                  ),
                  if (error != null) _TripError(error!),
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialog),
            child: const Text('Back'),
          ),
          FilledButton(
            onPressed: () {
              if (!form.currentState!.validate()) return;
              final values = controllers.map(
                (key, value) => MapEntry(key, value.text.trim()),
              );
              final failure = validate?.call(values);
              if (failure != null) {
                setState(() => error = failure);
                return;
              }
              Navigator.pop(dialog, values);
            },
            child: Text(submit),
          ),
        ],
      ),
    ),
  );
  // The route's closing animation still reads the controllers.
  await Future<void>.delayed(const Duration(milliseconds: 300));
  for (final controller in controllers.values) {
    controller.dispose();
  }
  return result;
}

class _TripError extends StatelessWidget {
  const _TripError(this.message);
  final String message;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 12),
    child: Text(
      message,
      style: TextStyle(color: Theme.of(context).colorScheme.error),
    ),
  );
}
