# EMAPI Flutter Demo

Flutter demo for scanning a Bluetooth printer, connecting through the PSDK `ConnectedDevice` adapter, and calling the EMAPI SDK facade.

> 📖 **开发接入文档**：详见 [DEV_GUIDE.md](./DEV_GUIDE.md)，包含完整的接入步骤、API 说明、架构设计与常见问题。

This demo targets Android (Classic + BLE) and iOS (BLE) Bluetooth.

## Run

All PSDK dependencies are published on pub.dev — no sibling `psdk` repo needed.

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

- All `psdk_*` packages are hosted on pub.dev; no local path overrides required.
- Android uses classic Bluetooth; iOS uses BLE.
- OTA reads bytes from the file path entered in the app before running start, chunk transfer, finish, and upgrade commands.
- Enable **模拟模式** (simulation mode) in Settings to test without real hardware.
