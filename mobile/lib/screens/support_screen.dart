import 'package:flutter/material.dart';

import '../services/api_client.dart';
import '../state/app_controller.dart';
import 'travel_tools_screen.dart';

class TicketsScreen extends StatefulWidget {
  const TicketsScreen({
    super.key,
    required this.controller,
    this.admin = false,
  });
  final AppController controller;
  final bool admin;
  @override
  State<TicketsScreen> createState() => _TicketsScreenState();
}

class _TicketsScreenState extends State<TicketsScreen> {
  List<dynamic> _tickets = [];
  bool _busy = true;
  String? _error;
  int _page = 1, _total = 0;
  String get _root => widget.admin ? '/api/admin/tickets' : '/api/user/tickets';
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
          _tickets = data['tickets'] as List;
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
      title: Text(widget.admin ? 'Support inbox' : 'My tickets'),
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
                      CreateTicketScreen(controller: widget.controller),
                ),
              );
              if (created == true && mounted) {
                _page = 1;
                _load();
              }
            },
            icon: const Icon(Icons.add),
            label: const Text('Create ticket'),
          ),
    body: _busy
        ? const Center(child: CircularProgressIndicator())
        : RefreshIndicator(
            onRefresh: _load,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
              children: [
                if (_error != null)
                  Text(
                    _error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                if (_tickets.isEmpty && _error == null)
                  const ListTile(
                    title: Text('No tickets yet'),
                    subtitle: Text(
                      'Create a ticket for support or a custom trip request.',
                    ),
                  ),
                ..._tickets.map((raw) {
                  final item = Map<String, dynamic>.from(raw as Map);
                  return Card(
                    child: ListTile(
                      leading: const Icon(Icons.confirmation_number_outlined),
                      title: Text('${item['subject']}'),
                      subtitle: Text(
                        '${item['reference']}\n${optionLabel('${item['category']}')} · ${optionLabel('${item['status']}')}',
                      ),
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => TicketDetailScreen(
                              api: widget.controller.api,
                              id: item['id'] as int,
                              admin: widget.admin,
                            ),
                          ),
                        );
                        if (mounted) _load();
                      },
                    ),
                  );
                }),
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

class CreateTicketScreen extends StatefulWidget {
  const CreateTicketScreen({super.key, required this.controller});
  final AppController controller;
  @override
  State<CreateTicketScreen> createState() => _CreateTicketScreenState();
}

class _CreateTicketScreenState extends State<CreateTicketScreen> {
  final _form = GlobalKey<FormState>();
  final _subject = TextEditingController();
  final _description = TextEditingController();
  String _category = 'general';
  int? _bookingId;
  bool _busy = false;
  String? _error;
  @override
  void dispose() {
    _subject.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.controller.api.requestJson(
        '/api/user/tickets',
        method: 'POST',
        body: {
          'subject': _subject.text.trim(),
          'description': _description.text.trim(),
          'category': _category,
          if (_bookingId != null) 'booking_id': _bookingId,
        },
      );
      if (mounted) Navigator.pop(context, true);
    } on ApiFailure catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Create ticket')),
    body: Form(
      key: _form,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          DropdownButtonFormField<String>(
            initialValue: _category,
            decoration: const InputDecoration(labelText: 'Category'),
            items: ['general', 'booking', 'custom_trip', 'account', 'payment']
                .map(
                  (v) =>
                      DropdownMenuItem(value: v, child: Text(optionLabel(v))),
                )
                .toList(),
            onChanged: _busy ? null : (v) => setState(() => _category = v!),
          ),
          const SizedBox(height: 14),
          DropdownButtonFormField<int>(
            initialValue: _bookingId,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Related booking (optional)',
            ),
            items: widget.controller.bookings
                .map(
                  (b) => DropdownMenuItem(
                    value: b.id,
                    child: Text(
                      '#${b.id} ${b.spotName}',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                )
                .toList(),
            validator: (v) => _category == 'booking' && v == null
                ? 'Select your booking'
                : null,
            onChanged: _busy ? null : (v) => setState(() => _bookingId = v),
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _subject,
            enabled: !_busy,
            maxLength: 150,
            decoration: const InputDecoration(labelText: 'Subject'),
            validator: (v) =>
                v?.trim().isEmpty != false ? 'Enter a subject' : null,
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _description,
            enabled: !_busy,
            maxLength: 5000,
            minLines: 5,
            maxLines: 10,
            decoration: InputDecoration(
              labelText: 'Details',
              hintText: _category == 'custom_trip'
                  ? 'Destination, dates, travelers, budget, and special requests'
                  : 'Describe your request',
            ),
            validator: (v) =>
                v?.trim().isEmpty != false ? 'Enter details' : null,
          ),
          if (_error != null)
            Text(
              _error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          FilledButton(
            onPressed: _busy ? null : _submit,
            child: Text(_busy ? 'Creating…' : 'Create ticket'),
          ),
        ],
      ),
    ),
  );
}

class TicketDetailScreen extends StatefulWidget {
  const TicketDetailScreen({
    super.key,
    required this.api,
    required this.id,
    this.admin = false,
  });
  final ApiClient api;
  final int id;
  final bool admin;
  @override
  State<TicketDetailScreen> createState() => _TicketDetailScreenState();
}

class _TicketDetailScreenState extends State<TicketDetailScreen> {
  Map<String, dynamic>? _ticket;
  List<dynamic> _messages = [];
  final _message = TextEditingController();
  bool _busy = true;
  String? _error;
  String get _path =>
      '/api/${widget.admin ? 'admin' : 'user'}/tickets/${widget.id}';
  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _message.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final data = await widget.api.requestJson(_path);
      if (mounted) {
        setState(() {
          _ticket = Map<String, dynamic>.from(data['ticket'] as Map);
          _messages = data['messages'] as List;
        });
      }
    } on ApiFailure catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _mutate(
    String suffix,
    Map<String, dynamic> body,
    String method,
  ) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.api.requestJson(
        '$_path/$suffix',
        method: method,
        body: body,
      );
      _message.clear();
      if (mounted) await _load();
    } on ApiFailure catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Ticket details'),
      actions: [
        IconButton(
          onPressed: _busy ? null : _load,
          icon: const Icon(Icons.refresh),
        ),
      ],
    ),
    body: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        if (_busy) const Center(child: CircularProgressIndicator()),
        if (_error != null)
          Text(
            _error!,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        if (_ticket != null) ...[
          Text(
            '${_ticket!['subject']}',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          SelectableText('${_ticket!['reference']}'),
          Text('Status: ${optionLabel('${_ticket!['status']}')}'),
          const SizedBox(height: 12),
          Text('${_ticket!['description']}'),
          if (_ticket!['booking_id'] != null)
            Text('Related booking: #${_ticket!['booking_id']}'),
          const Divider(height: 32),
          ..._messages.map(
            (m) => Card(
              child: ListTile(
                title: Text('${m['author_name']} · ${m['author_role']}'),
                subtitle: Text('${m['message']}\n${m['created_at']}'),
              ),
            ),
          ),
          if (!['closed', 'resolved'].contains(_ticket!['status'])) ...[
            TextField(
              controller: _message,
              enabled: !_busy,
              minLines: 2,
              maxLines: 5,
              maxLength: 5000,
              decoration: const InputDecoration(labelText: 'Reply'),
            ),
            FilledButton(
              onPressed: _busy
                  ? null
                  : () {
                      if (_message.text.trim().isNotEmpty) {
                        _mutate('messages', {
                          'message': _message.text.trim(),
                        }, 'POST');
                      }
                    },
              child: const Text('Send reply'),
            ),
          ],
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            children:
                (widget.admin
                        ? ['open', 'in_progress', 'resolved', 'closed']
                        : ['open', 'closed'])
                    .where((s) => s != _ticket!['status'])
                    .map(
                      (s) => OutlinedButton(
                        onPressed: _busy
                            ? null
                            : () => _mutate('status', {'status': s}, 'PUT'),
                        child: Text(s == 'open' ? 'Reopen' : optionLabel(s)),
                      ),
                    )
                    .toList(),
          ),
        ],
      ],
    ),
  );
}

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key, required this.controller});
  final AppController controller;
  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _input = TextEditingController();
  final _scroll = ScrollController();
  List<dynamic> _messages = [];
  bool _busy = true;
  String? _error;
  bool _ticketAction = false;
  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final data = await widget.controller.api.requestJson(
        '/api/chatbot/messages',
      );
      if (mounted) setState(() => _messages = data['messages'] as List);
      _scrollToEnd();
    } on ApiFailure catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _scrollToEnd() => WidgetsBinding.instance.addPostFrameCallback((_) {
    if (mounted && _scroll.hasClients) {
      _scroll.animateTo(
        _scroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    }
  });
  Future<void> _send() async {
    final message = _input.text.trim();
    if (message.isEmpty || _busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final data = await widget.controller.api.requestJson(
        '/api/chatbot/messages',
        method: 'POST',
        body: {'message': message},
      );
      if (mounted) {
        setState(() {
          _messages.addAll([
            {'role': 'user', 'message': message},
            {'role': 'assistant', 'message': data['reply']},
          ]);
          _ticketAction = data['action'] == 'create_ticket';
          _input.clear();
        });
      }
      _scrollToEnd();
    } on ApiFailure catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Travel assistant'),
      actions: [
        IconButton(
          tooltip: 'Clear conversation',
          icon: const Icon(Icons.delete_outline),
          onPressed: _busy
              ? null
              : () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (c) => AlertDialog(
                      title: const Text('Clear conversation?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(c, false),
                          child: const Text('Keep'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(c, true),
                          child: const Text('Clear'),
                        ),
                      ],
                    ),
                  );
                  if (confirm != true || !mounted) return;
                  setState(() => _busy = true);
                  try {
                    await widget.controller.api.requestJson(
                      '/api/chatbot/messages',
                      method: 'DELETE',
                    );
                    if (mounted) {
                      _ticketAction = false;
                      await _load();
                    }
                  } on ApiFailure catch (e) {
                    if (mounted) setState(() => _error = e.message);
                  } finally {
                    if (mounted) setState(() => _busy = false);
                  }
                },
        ),
      ],
    ),
    body: Column(
      children: [
        const Padding(
          padding: EdgeInsets.all(12),
          child: Text(
            'A local assistant for FarReach destinations, budgets, bookings and support.',
          ),
        ),
        Expanded(
          child: ListView(
            controller: _scroll,
            padding: const EdgeInsets.all(16),
            children: [
              if (_messages.isEmpty && !_busy)
                const Text(
                  'Ask about budgets, stays, your bookings, or a destination.',
                ),
              ..._messages.map(
                (m) => Align(
                  alignment: m['role'] == 'user'
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: Card(
                    color: m['role'] == 'user'
                        ? Theme.of(context).colorScheme.primaryContainer
                        : null,
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Text('${m['message']}'),
                    ),
                  ),
                ),
              ),
              if (_ticketAction)
                OutlinedButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          CreateTicketScreen(controller: widget.controller),
                    ),
                  ),
                  child: const Text('Create support ticket'),
                ),
              if (_busy) const Center(child: CircularProgressIndicator()),
              if (_error != null)
                Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
            ],
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _input,
                    enabled: !_busy,
                    maxLength: 1000,
                    decoration: const InputDecoration(
                      hintText: 'Ask FarReach',
                      counterText: '',
                    ),
                    onSubmitted: (_) => _send(),
                  ),
                ),
                IconButton(
                  onPressed: _busy ? null : _send,
                  tooltip: 'Send message',
                  icon: const Icon(Icons.send),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}
