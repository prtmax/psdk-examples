# EMAPI Flutter Demo

Flutter demo for scanning a Bluetooth printer, connecting through the PSDK `ConnectedDevice` adapter, and calling the EMAPI SDK facade.

This demo currently targets Android Bluetooth. Future iOS, Windows, and OC demos can be added separately when those platform scopes are ready.

## Run

This demo uses local PSDK packages because `psdk_fruit_emapi` is not published
yet. Check out `psdk` as a sibling of `psdk-examples`; in other words, the PSDK
repo should be available at `/same-parent/psdk` so the default path dependencies
resolve:

```text
/same-parent/
  psdk/
  psdk-examples/
```

If your checkout layout is different, adjust the path dependencies that point to
`../../../psdk/...` in `pubspec.yaml` before running `flutter pub get`. Do not replace
them with hosted versions until the EMAPI package is published.

```sh
flutter pub get
flutter run
```

## Check

```sh
dart format .
flutter analyze
flutter test
flutter build apk --debug
```

## Notes

- Uses the local EMAPI SDK at `../../../psdk/dart/fruits/emapi`.
- Android uses classic Bluetooth through the local PSDK packages.
- OTA reads bytes from the file path entered in the app before running start, chunk transfer, finish, and upgrade commands.
