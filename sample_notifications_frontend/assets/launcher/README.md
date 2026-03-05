# Launcher icon source

Place your launcher icon source image at:

- `assets/launcher/icon.png`

Recommended format:
- **PNG**, **1024x1024**
- Keep important content centered with padding (iOS will apply rounding / Android may mask).
- If the icon has transparency, consider adjusting `adaptive_icon_background` in `pubspec.yaml`.

## Generate icons

From `sample-notifications-app-10652-10666/sample_notifications_frontend`:

```bash
flutter pub get
flutter pub run flutter_launcher_icons
```

This will update:
- Android mipmap icons under `android/app/src/main/res/mipmap-*`
- iOS AppIcon assets under `ios/Runner/...` (when the iOS project structure exists)
"""
