# iOS (Flutter) scaffolding + Firebase Messaging setup

This Flutter app uses `firebase_core` / `firebase_messaging`. An `ios/` directory is required so you can add **Firebase iOS config**.

## 1) Where to put `GoogleService-Info.plist`
Place the file here:

- `ios/Runner/GoogleService-Info.plist`

Then, in Xcode, ensure it is added to the **Runner** target:
- Open `ios/Runner.xcworkspace`
- Drag `GoogleService-Info.plist` into the `Runner` group in Xcode
- In the file inspector, ensure **Target Membership** includes **Runner**

## 2) Required iOS project settings (Xcode -> Runner target)
For Firebase Cloud Messaging (FCM) to work on iOS:

### Capabilities
Enable:
- **Push Notifications**
- **Background Modes**
  - Check **Remote notifications**

### Signing
- Use a real Apple Developer Team
- Set a valid **Bundle Identifier** that matches the one registered in Firebase

### APNs key/certificate
- In Apple Developer portal, create and upload an APNs Auth Key to Firebase (recommended),
  or use certificates, then configure in Firebase console.
- Without APNs configured, iOS push notifications will not be delivered.

## 3) AppDelegate
`ios/Runner/AppDelegate.swift` calls:

- `FirebaseApp.configure()`

This is required for Firebase initialization on iOS.

## 4) CocoaPods
From the Flutter app root:

- `cd ios`
- `pod install`

FlutterFire plugins bring the Firebase pods automatically; you generally do NOT add Firebase pods manually.
