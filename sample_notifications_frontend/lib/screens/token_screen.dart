import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../notifications/push_manager.dart';

class TokenScreen extends StatefulWidget {
  /// PUBLIC_INTERFACE
  const TokenScreen({super.key});

  @override
  State<TokenScreen> createState() => _TokenScreenState();
}

class _TokenScreenState extends State<TokenScreen> {
  String? _snackMessage;

  Future<void> _copyToken(String token) async {
    await Clipboard.setData(ClipboardData(text: token));
    if (!mounted) return;
    setState(() {
      _snackMessage = 'FCM token copied to clipboard';
    });
  }

  Future<void> _refreshToken() async {
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
        title: const Text('Device Token'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: <Widget>[
            Text(
              'Use this screen to copy the FCM token for testing push notifications.',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withAlpha(180),
              ),
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
