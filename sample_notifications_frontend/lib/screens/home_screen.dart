import 'package:flutter/material.dart';

import '../notifications/notification_service.dart';
import '../notifications/push_manager.dart';

class HomeScreen extends StatefulWidget {
  /// PUBLIC_INTERFACE
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? _token;
  String? _tokenError;

  @override
  void initState() {
    super.initState();
    _loadToken();
  }

  Future<void> _loadToken() async {
    // Async context rule: do not use context after await.
    final String? token = await PushManager.instance.getToken();
    if (!mounted) return;
    setState(() {
      _token = token;
      _tokenError = token == null || token.isEmpty
          ? 'Token unavailable (common on emulators/preview without Google Play services).'
          : null;
    });
  }

  Future<void> _triggerLocalTestNotification() async {
    // No UI calls after await except primitive state changes (we do none).
    await NotificationService.instance.showNotificationFromData(<String, dynamic>{
      'title': 'New message',
      'body': 'You have a new chat message',
      'defaultDeepLink': 'myapp://chat?threadId=42',
      'actionTitles': 'Open Chat,Open Orders',
      'actionDeepLinks': 'myapp://chat?threadId=42,myapp://orders',
      'notificationId': '9876',
      'category': 'chat',
    });
  }

  @override
  Widget build(BuildContext context) {
    final String tokenDisplay = _tokenError ?? (_token ?? 'Fetching token…');

    return Scaffold(
      appBar: AppBar(
        title: const Text('sample_notifications_frontend'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: <Widget>[
            const Text(
              'Actionable notifications + deep links demo',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _triggerLocalTestNotification,
              child: const Text('Trigger local test notification (2 actions)'),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    const Text(
                      'FCM token',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    SelectableText(
                      tokenDisplay,
                      style: TextStyle(
                        fontSize: 12,
                        color: _tokenError == null ? null : Theme.of(context).colorScheme.error,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Tip: Use the local trigger above to test actions without a server.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurface.withAlpha(170),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
