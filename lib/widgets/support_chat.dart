import 'package:flutter/material.dart';

import '../state/app_controller.dart';

class SupportChatSheet extends StatefulWidget {
  const SupportChatSheet({
    super.key,
    required this.controller,
    required this.onNavigate,
  });

  final AppController controller;
  final ValueChanged<int> onNavigate;

  @override
  State<SupportChatSheet> createState() => _SupportChatSheetState();
}

class _SupportChatSheetState extends State<SupportChatSheet> {
  final _input = TextEditingController();
  final _messages = <_ChatMessage>[
    const _ChatMessage(
      text:
          'Hi! I can help you find a destination, plan a budget, check weather, or manage saved places.',
      fromUser: false,
    ),
  ];
  bool _sending = false;

  static const _suggestions = [
    'Help me choose a destination',
    'How do I check trip safety?',
    'Where is the budget calculator?',
    'Show my saved places',
  ];

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          16,
          0,
          16,
          16 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height * .72,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: scheme.primaryContainer,
                    child: Icon(
                      Icons.support_agent_outlined,
                      color: scheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'FarReach guide',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        Text(
                          'Instant help for exploring the app',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Close support chat',
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _suggestions
                    .map(
                      (suggestion) => ActionChip(
                        label: Text(suggestion),
                        onPressed: _sending ? null : () => _send(suggestion),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 14),
              Expanded(
                child: ListView.builder(
                  reverse: true,
                  itemCount: _messages.length + (_sending ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (_sending && index == 0) {
                      return const _TypingBubble();
                    }
                    final messageIndex =
                        _messages.length - 1 - (index - (_sending ? 1 : 0));
                    final message = _messages[messageIndex];
                    return Align(
                      alignment: message.fromUser
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                        constraints: const BoxConstraints(maxWidth: 340),
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 11,
                        ),
                        decoration: BoxDecoration(
                          color: message.fromUser
                              ? scheme.primary
                              : scheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          message.text,
                          style: TextStyle(
                            color: message.fromUser
                                ? scheme.onPrimary
                                : scheme.onSurface,
                            fontSize: 15,
                            height: 1.35,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _input,
                enabled: !_sending,
                textInputAction: TextInputAction.send,
                style: TextStyle(color: scheme.onSurface, fontSize: 15),
                onSubmitted: _send,
                decoration: InputDecoration(
                  hintText: 'Ask about trips, weather, or booking...',
                  hintStyle: TextStyle(color: scheme.onSurfaceVariant),
                  suffixIcon: IconButton(
                    tooltip: 'Send message',
                    onPressed: _sending ? null : () => _send(_input.text),
                    icon: const Icon(Icons.send_outlined),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _send(String text) async {
    final question = text.trim();
    if (question.isEmpty || _sending) return;
    _input.clear();
    final history = _messages
        .map(
          (message) => {
            'role': message.fromUser ? 'user' : 'model',
            'text': message.text,
          },
        )
        .toList();
    setState(() {
      _messages.add(_ChatMessage(text: question, fromUser: true));
      _sending = true;
    });

    String reply;
    final navigationReply = _navigationReply(question);
    if (navigationReply != null) {
      reply = navigationReply;
    } else {
      try {
        reply = await widget.controller.chatReply(question, history: history);
      } catch (_) {
        reply = _fallbackReply(question);
      }
    }

    if (!mounted) return;
    setState(() {
      _messages.add(_ChatMessage(text: reply, fromUser: false));
      _sending = false;
    });
  }

  String? _navigationReply(String question) {
    final normalized = question.toLowerCase();
    if (normalized.contains('saved') || normalized.contains('bookmark')) {
      widget.onNavigate(2);
      return 'I opened Saved. Tap a heart on any destination to keep it here for later.';
    }
    if (normalized.contains('show my bookings') ||
        normalized.contains('my bookings') ||
        normalized.contains('my trips')) {
      widget.onNavigate(3);
      return 'I opened Profile, where your bookings and saved places live.';
    }
    if (normalized.contains('map') ||
        normalized.contains('spots') ||
        normalized.contains('location')) {
      widget.onNavigate(1);
      return 'I opened Spots. Use it to browse destinations by location, then open a place for details.';
    }
    if (normalized.contains('account') ||
        normalized.contains('login') ||
        normalized.contains('log in') ||
        normalized.contains('sign in') ||
        normalized.contains('sign up')) {
      widget.onNavigate(3);
      return 'I opened Profile. Sign in there to sync saved places and make bookings.';
    }
    if (normalized.contains('destination') ||
        normalized.contains('choose a place') ||
        normalized.contains('get started')) {
      widget.onNavigate(0);
      return 'Start in Explore. Filter by category, open a destination, then check weather, budget, and availability.';
    }
    return null;
  }

  String _fallbackReply(String question) {
    final normalized = question.toLowerCase();
    if (normalized.contains('budget') ||
        normalized.contains('cost') ||
        normalized.contains('price')) {
      return 'Open a destination, then tap Budget. Choose dates, people, transport, lodging, food, and guide options to see the estimate.';
    }
    if (normalized.contains('weather') ||
        normalized.contains('safe') ||
        normalized.contains('safety')) {
      return 'Open a destination and use the weather section. Pick a date to see the forecast, rain probability, and a Good to go or Use caution suggestion.';
    }
    return 'Try Explore to find a place, Spots to browse locations, Saved to revisit places, or Profile for your account.';
  }
}

class _TypingBubble extends StatelessWidget {
  const _TypingBubble();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'Thinking...',
              style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatMessage {
  const _ChatMessage({required this.text, required this.fromUser});

  final String text;
  final bool fromUser;
}
