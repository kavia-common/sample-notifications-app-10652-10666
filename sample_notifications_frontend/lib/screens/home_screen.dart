import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../notifications/notification_service.dart';
import '../notifications/push_manager.dart';

class HomeScreen extends StatefulWidget {
  /// PUBLIC_INTERFACE
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? _snackMessage;

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

  Future<void> _copyToken(String token) async {
    await Clipboard.setData(ClipboardData(text: token));
    if (!mounted) return;
    setState(() {
      _snackMessage = 'FCM token copied to clipboard';
    });
  }

  Future<void> _refreshToken() async {
    // Triggers a new getToken() call and updates PushManager.tokenNotifier.
    await PushManager.instance.getToken();
    if (!mounted) return;
    setState(() {
      _snackMessage = 'Token refreshed (if available)';
    });
  }

  @override
  Widget build(BuildContext context) {
    final String? snackMessage = _snackMessage;
    if (snackMessage != null) {
      // Show snackbars from build (not after await) to avoid "context across async gap".
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(snackMessage)),
        );
        if (mounted) {
          setState(() {
            _snackMessage = null;
          });
        }
      });
    }

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
                    Row(
                      children: <Widget>[
                        const Expanded(
                          child: Text(
                            'FCM device token',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                        TextButton.icon(
                          onPressed: _refreshToken,
                          icon: const Icon(Icons.refresh, size: 18),
                          label: const Text('Refresh'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ValueListenableBuilder<String?>(
                      valueListenable: PushManager.instance.tokenNotifier,
                      builder: (BuildContext context, String? token, Widget? child) {
                        final bool hasToken = token != null && token.isNotEmpty;

                        final String displayText = hasToken
                            ? token
                            : 'Fetching token…\n'
                                'If this stays empty, FCM may not be available on this device/emulator '
                                '(e.g., missing Google Play services).';

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: <Widget>[
                            SelectableText(
                              displayText,
                              style: TextStyle(
                                fontSize: 13,
                                height: 1.25,
                                color: hasToken ? null : Theme.of(context).colorScheme.error,
                              ),
                            ),
                            const SizedBox(height: 12),
                            FilledButton.icon(
                              onPressed: hasToken ? () => _copyToken(token) : null,
                              icon: const Icon(Icons.copy),
                              label: const Text('Copy token'),
                            ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Paste this token into Firebase Console → Messaging → Send test message.',
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
