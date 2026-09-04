# App icon source

Place the source icon here as `app_icon.png` before running the icon generator.

Required spec:
- File name: `app_icon.png`
- Size: 1024x1024 px
- No alpha/transparency channel (flat background, fully opaque)
- No rounded corners / no baked-in padding — iOS and Android both apply their
  own mask, so a square, edge-to-edge image is correct here

Once the file is in place, run from the project root:

```
flutter pub get
flutter pub run flutter_launcher_icons
```

This regenerates the Android (`android/app/src/main/res/mipmap-*`) and iOS
(`ios/Runner/Assets.xcassets/AppIcon.appiconset`) icon sets from this source
image, per the `flutter_launcher_icons:` config in `pubspec.yaml`.
