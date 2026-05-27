# EMAPI iOS Objective-C Demo

Native Objective-C iOS demo for the PSDK EMAPI SDK. It mirrors the Flutter
EMAPI demo under `emapi-demo/flutter` with scan/settings/function screens,
request/result/report logs, simulation mode, WiFi file transfer, OTA, and ESC
print entry points.

## SDK Layout

The demo references local PSDK Objective-C headers from:

```text
../../../psdk/objectivec/fruits/emapi
../../../psdk/objectivec/fruits/esc
../../../psdk/objectivec/device/adapter
```

If your checkout layout is different, update the Xcode header and framework
search paths before building. The current execution environment may not include
final CocoaPods, compiled iOS SDK artifacts, or a Bluetooth connected-device
adapter. The sample keeps those boundaries isolated in `EMAPIDemoController`
and `EMAPIDemoESCBuilder`.

## Run

Create or open an iOS Objective-C app target with the files in
`EMAPIIOSDemo/`, then add the local EMAPI SDK sources or published framework
when available. Required iOS permissions:

```xml
<key>NSBluetoothAlwaysUsageDescription</key>
<string>用于扫描并连接 EMAPI 蓝牙打印机</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>用于选择 ESC 打印图片</string>
```

Once dependencies are available, validate with:

```sh
pod install
xcodebuild -workspace EMAPIIOSDemo.xcworkspace -scheme EMAPIIOSDemo -configuration Debug -sdk iphonesimulator build
```

## Notes

- Simulation mode generates a simulated Bluetooth printer and simulated EMAPI
  command/report results without hardware.
- Real-device EMAPI operations call the Objective-C `EMAPIPrinter` facade
  directly.
- ESC image conversion is isolated in `EMAPIDemoESCBuilder`; replace the local
  placeholder branch only if the Objective-C ESC package is unavailable.
