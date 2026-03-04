# iOS (Flutter) local notifications POC setup (no APNs / no Apple Developer account required)

This Flutter app is configured to demonstrate **local notifications on iOS** using `flutter_local_notifications`.

Key goal of this POC:
- Show local notification UI/behavior on iOS **without** setting up APNs/FCM or requiring an Apple Developer account.

## What was configured

### 1) AppDelegate
`ios/Runner/AppDelegate.swift` is configured to:
- Set `UNUserNotificationCenter.current().delegate` so notifications can present while the app is in the foreground (iOS 10+)
- Register a `FlutterLocalNotificationsPlugin.setPluginRegistrantCallback(...)` to support background isolates used by the plugin

### 2) Info.plist
`ios/Runner/Info.plist` includes:
- `NSUserNotificationUsageDescription` so the system permission prompt has a rationale string

### 3) Dart initialization
`lib/main.dart`:
- Initializes `flutter_local_notifications` with `DarwinInitializationSettings`
- Requests iOS permissions via `IOSFlutterLocalNotificationsPlugin.requestPermissions(...)`

## How to run on iOS

1. From the Flutter project root:
   - `flutter pub get`
2. Open iOS workspace:
   - `open ios/Runner.xcworkspace`
3. Select a simulator (or a device) and run.

## Notes / limitations

- iOS Simulator support for notifications varies by iOS version. If you do not see alerts in simulator, test on a physical device.
- This is **local notifications only**. Remote push notifications on iOS still require:
  - Apple Developer account + signing
  - APNs configuration
  - Push Notifications capability enabled in Xcode
  - Background Modes -> Remote notifications (if needed)
  - Firebase iOS configuration and APNs key/certs for FCM delivery
