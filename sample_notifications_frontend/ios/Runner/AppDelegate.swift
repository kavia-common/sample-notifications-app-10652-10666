import UIKit
import Flutter
import flutter_local_notifications

@UIApplicationMain
class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {

    // iOS local-notifications-only POC notes:
    // - No APNs/FCM setup required.
    // - We still must request notification permissions in Dart, and we must set up
    //   the UNUserNotificationCenter delegate so notifications can present while
    //   the app is in the foreground.
    //
    // flutter_local_notifications also recommends setting a plugin registrant
    // callback for background isolates (e.g., scheduled notifications).

    GeneratedPluginRegistrant.register(with: self)

    if #available(iOS 10.0, *) {
      // Required for foreground notification presentation on iOS 10+.
      UNUserNotificationCenter.current().delegate = self as UNUserNotificationCenterDelegate
    }

    FlutterLocalNotificationsPlugin.setPluginRegistrantCallback { registry in
      GeneratedPluginRegistrant.register(with: registry)
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
