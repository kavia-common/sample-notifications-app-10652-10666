import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ChatScreen extends StatefulWidget {
  /// PUBLIC_INTERFACE
  const ChatScreen({super.key, this.threadId});

  final String? threadId;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatMessage {
  const _ChatMessage({
    required this.id,
    required this.text,
    required this.timestamp,
    required this.isMe,
  });

  final String id;
  final String text;
  final DateTime timestamp;
  final bool isMe;
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _composerController = TextEditingController();
  final ScrollController _listController = ScrollController();

  // Local-only demo data. This keeps the UI functional without adding backend deps.
  final List<_ChatMessage> _messages = <_ChatMessage>[];

  // Prevent re-entrant navigation when both PopScope and AppBar back (or rapid
  // repeated back presses) try to trigger navigation.
  bool _isExiting = false;

  @override
  void initState() {
    super.initState();

    // Seed a couple of messages so the UI doesn't look empty on first open.
    final DateTime now = DateTime.now();
    _messages.addAll(<_ChatMessage>[
      _ChatMessage(
        id: 'seed_1',
        text:
            'Hi! This is a sample chat UI.\nDeep links can open a specific thread.',
        timestamp: now.subtract(const Duration(minutes: 2)),
        isMe: false,
      ),
      _ChatMessage(
        id: 'seed_2',
        text: 'Try sending a message using the input below.',
        timestamp: now.subtract(const Duration(minutes: 1)),
        isMe: false,
      ),
    ]);
  }

  @override
  void dispose() {
    _composerController.dispose();
    _listController.dispose();
    super.dispose();
  }

  String get _threadLabel {
    final String? t = widget.threadId;
    if (t == null || t.isEmpty) return 'unknown';
    return t;
  }

  void _sendCurrentText() {
    final String text = _composerController.text.trim();
    if (text.isEmpty) return;

    final DateTime now = DateTime.now();
    setState(() {
      _messages.add(
        _ChatMessage(
          id: 'local_${now.microsecondsSinceEpoch}',
          text: text,
          timestamp: now,
          isMe: true,
        ),
      );
      _composerController.clear();
    });

    // Scroll after the new frame is laid out (no async/await used).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_listController.hasClients) return;
      _listController.animateTo(
        0, // reversed list -> 0 is bottom
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    });
  }

  void _exitToHome(BuildContext context) {
    // IMPORTANT:
    // For go_router apps, using Navigator.canPop/maybePop here can be misleading
    // because go_router manages a separate route stack. In some deep-link
    // scenarios, that can create a loop where "back" never resolves and can
    // lead to an ANR after repeated presses.
    //
    // Requirement: Back from Chat should always land on Home.
    if (_isExiting) return;
    _isExiting = true;
    context.go('/');
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;

    return PopScope(
      // We fully handle "back" ourselves to avoid inconsistent behavior between
      // the system back gesture and the AppBar leading button.
      canPop: false,
      onPopInvokedWithResult: (bool didPop, Object? result) {
        if (didPop) return;
        _exitToHome(context);
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            tooltip: 'Back',
            icon: const Icon(Icons.arrow_back),
            onPressed: () => _exitToHome(context),
          ),
          title: const Text('Chat'),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(28),
            child: Padding(
              padding: const EdgeInsets.only(left: 16, right: 16, bottom: 10),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'threadId=$_threadLabel',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: colors.onSurface.withAlpha(160),
                      ),
                ),
              ),
            ),
          ),
        ),
        body: SafeArea(
          child: Column(
            children: <Widget>[
              Expanded(
                child: _MessageList(
                  controller: _listController,
                  messages: _messages,
                ),
              ),
              const Divider(height: 1),
              _Composer(
                controller: _composerController,
                onSend: _sendCurrentText,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MessageList extends StatelessWidget {
  const _MessageList({
    required this.controller,
    required this.messages,
  });

  final ScrollController controller;
  final List<_ChatMessage> messages;

  @override
  Widget build(BuildContext context) {
    if (messages.isEmpty) {
      return const Center(
        child: Text('No messages yet.'),
      );
    }

    // Reverse so the newest message is near the bottom like a typical chat.
    return ListView.builder(
      controller: controller,
      reverse: true,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      itemCount: messages.length,
      itemBuilder: (BuildContext context, int index) {
        final _ChatMessage msg = messages[messages.length - 1 - index];
        return _MessageBubble(message: msg);
      },
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message});

  final _ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;

    final Alignment align = message.isMe ? Alignment.centerRight : Alignment.centerLeft;
    final Color bubbleColor = message.isMe ? colors.primary : colors.surface;
    final Color textColor = message.isMe ? colors.onPrimary : colors.onSurface;

    final BorderRadius radius = BorderRadius.only(
      topLeft: const Radius.circular(14),
      topRight: const Radius.circular(14),
      bottomLeft: Radius.circular(message.isMe ? 14 : 4),
      bottomRight: Radius.circular(message.isMe ? 4 : 14),
    );

    return Align(
      alignment: align,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 320),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 6),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: bubbleColor,
            borderRadius: radius,
            border: message.isMe
                ? null
                : Border.all(
                    color: colors.outlineVariant.withAlpha(140),
                  ),
          ),
          child: Text(
            message.text,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: textColor,
                ),
          ),
        ),
      ),
    );
  }
}

class _Composer extends StatelessWidget {
  const _Composer({
    required this.controller,
    required this.onSend,
  });

  final TextEditingController controller;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      child: Row(
        children: <Widget>[
          Expanded(
            child: TextField(
              controller: controller,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => onSend(),
              decoration: InputDecoration(
                hintText: 'Message…',
                filled: true,
                fillColor: colors.surface,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide(
                    color: colors.outlineVariant.withAlpha(160),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide(
                    color: colors.outlineVariant.withAlpha(160),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide(
                    color: colors.primary.withAlpha(220),
                    width: 1.5,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          IconButton.filled(
            onPressed: onSend,
            icon: const Icon(Icons.send),
            tooltip: 'Send',
          ),
        ],
      ),
    );
  }
}
