import UIKit
import Flutter
import FirebaseCore

@UIApplicationMain
class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {

    // Firebase iOS initialization.
    // Requires: ios/Runner/GoogleService-Info.plist to be present in the Xcode project.
    FirebaseApp.configure()

    // IMPORTANT for Firebase Messaging:
    // - iOS Push Notifications capability must be enabled for the Runner target.
    // - Background Modes -> Remote notifications should be enabled for the Runner target.
    // - On iOS 10+, the permission prompt is handled by firebase_messaging in Dart
    //   (via requestPermission), but iOS project capabilities are still required.

    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
