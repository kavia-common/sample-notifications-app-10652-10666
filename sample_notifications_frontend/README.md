# sample_notifications_frontend

Flutter demo for **actionable notifications + deep-link navigation**:
- FCM receiving via `firebase_messaging`
- Local notifications + **action buttons** via `flutter_local_notifications`
- Deep links (`myapp://...`) via `uni_links`
- Navigation via `go_router`

## Deep links supported

- `myapp://orders` → `/orders`
- `myapp://chat?threadId=42` → `/chat?threadId=42`

## Local test (no server required)

1. Run the app
2. Tap: **“Trigger local test notification (2 actions)”**
3. In the notification:
   - Tap the notification body → navigates to Chat (`defaultDeepLink`)
   - Tap **Open Chat** → navigates to Chat with `threadId=42`
   - Tap **Open Orders** → navigates to Orders

This validates:
- foreground/background/terminated tap handling for local notifications
- action button routing

## FCM test (data payload)

Send a message with **data payload** keys like:

```json
{
  "title": "New message",
  "body": "You have a new chat message",
  "defaultDeepLink": "myapp://chat?threadId=42",
  "actionTitles": "Open Chat,Open Orders",
  "actionDeepLinks": "myapp://chat?threadId=42,myapp://orders",
  "notificationId": "9876",
  "category": "chat"
}
```

Notes:
- If `actionDeepLinks` is missing/empty, the app still routes via `defaultDeepLink` on main tap.
- Token retrieval may be unavailable on emulators/preview environments without Google Play services.

## Platform config included in-project

- Android: `AndroidManifest.xml`
  - `POST_NOTIFICATIONS` permission (Android 13+)
  - intent-filter for `myapp://...` deep links
  - default FCM channel id set to `hardik-channel`
- iOS: `Info.plist`
  - URL Types for `myapp` scheme
  - local notification usage description
- iOS categories/actions are registered via `flutter_local_notifications` initialization in Dart.
