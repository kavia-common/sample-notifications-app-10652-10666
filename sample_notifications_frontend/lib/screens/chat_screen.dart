import 'package:flutter/material.dart';

class ChatScreen extends StatelessWidget {
  /// PUBLIC_INTERFACE
  const ChatScreen({super.key, required this.threadId});

  final String? threadId;

  @override
  Widget build(BuildContext context) {
    final String thread = (threadId == null || threadId!.isEmpty) ? 'unknown' : threadId!;
    return Scaffold(
      appBar: AppBar(title: const Text('Chat')),
      body: Center(
        child: Text(
          'Chat screen\nthreadId=$thread\n(deep link: myapp://chat?threadId=...)',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
