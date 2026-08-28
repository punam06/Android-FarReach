import 'package:flutter/material.dart';

class SupportChatSheet extends StatefulWidget {
  const SupportChatSheet({super.key, required this.onNavigate});

  final ValueChanged<int> onNavigate;

  @override
  State<SupportChatSheet> createState() => _SupportChatSheetState();
}

class _SupportChatSheetState extends State<SupportChatSheet> {
  final _input = TextEditingController();
  final _messages = <_ChatMessage>[
    const _ChatMessage(
      text: 'Hi! I can help you find a destination, plan a budget, check weather, or manage saved places.',
      fromUser: false,
    ),
  ];

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
  Widget build(BuildContext context) => SafeArea(
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
                  backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                  child: Icon(Icons.support_agent_outlined, color: Theme.of(context).colorScheme.onPrimaryContainer),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('FarReach guide', style: Theme.of(context).textTheme.titleLarge),
                      Text('Instant help for exploring the app', style: Theme.of(context).textTheme.bodySmall),
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
                  .map((suggestion) => ActionChip(label: Text(suggestion), onPressed: () => _send(suggestion)))
                  .toList(),
            ),
            const SizedBox(height: 14),
            Expanded(
              child: ListView.builder(
                reverse: true,
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final message = _messages[_messages.length - index - 1];
                  return Align(
                    alignment: message.fromUser ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 340),
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                      decoration: BoxDecoration(
                        color: message.fromUser
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        message.text,
                        style: TextStyle(color: message.fromUser ? Theme.of(context).colorScheme.onPrimary : null),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _input,
              textInputAction: TextInputAction.send,
              onSubmitted: _send,
              decoration: InputDecoration(
                hintText: 'Ask how to get started...',
                suffixIcon: IconButton(
                  tooltip: 'Send message',
                  onPressed: () => _send(_input.text),
                  icon: const Icon(Icons.send_outlined),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );

  void _send(String text) {
    final question = text.trim();
    if (question.isEmpty) return;
    _input.clear();
    setState(() {
      _messages.add(_ChatMessage(text: question, fromUser: true));
      _messages.add(_ChatMessage(text: _replyFor(question), fromUser: false));
    });
  }

  String _replyFor(String question) {
    final normalized = question.toLowerCase();
    if (normalized.contains('saved') || normalized.contains('bookmark')) {
      widget.onNavigate(2);
      return 'I opened Saved. Tap a heart on any destination to keep it here for later.';
    }
    if (normalized.contains('map') || normalized.contains('where')) {
      widget.onNavigate(1);
      return 'I opened Spots. Use it to browse destinations by location, then open a place for details.';
    }
    if (normalized.contains('budget') || normalized.contains('cost') || normalized.contains('price')) {
      return 'Open a destination, then tap Budget. Choose dates, people, transport, lodging, food, and guide options to see the estimate.';
    }
    if (normalized.contains('weather') || normalized.contains('safe') || normalized.contains('safety')) {
      return 'Open a destination and use the weather section. Pick a date to see the forecast, rain probability, and a Good to go or Use caution suggestion.';
    }
    if (normalized.contains('account') || normalized.contains('login') || normalized.contains('sign')) {
      widget.onNavigate(3);
      return 'I opened Profile. Sign in there to sync saved places and make bookings.';
    }
    if (normalized.contains('destination') || normalized.contains('choose') || normalized.contains('start')) {
      widget.onNavigate(0);
      return 'Start in Explore. Filter by category, open a destination, then check weather, budget, and availability.';
    }
    return 'Try Explore to find a place, Spots to browse locations, Saved to revisit places, or Profile for your account.';
  }
}

class _ChatMessage {
  const _ChatMessage({required this.text, required this.fromUser});

  final String text;
  final bool fromUser;
}
