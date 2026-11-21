# Developer Guide (`cloud-print-demo`)

## 1. Architecture Overview

`cloud-print-demo` demonstrates all four `CloudPrinterFamily` tracks from `prtmax/psdk` in a single Material 3 Flutter app:

- `lib/main.dart`: `CloudPrintDemoApp` (`#256B75` / `#F6F8F6` Material 3 theme) and `CloudPrintDemoPage` (global `Sim` / `Real` mode switcher, `TabBar` keyed by `CloudPrinterFamily.values`, and `ProtocolInspectorDrawer` endDrawer).
- `lib/src/models/`:
  - `demo_mode.dart`: `DemoRunMode` (`simulation`, `realDevice`) and `CloudPrinterFamilyUi` metadata.
  - `protocol_inspector.dart`: `ProtocolInspectorController` & `ProtocolTrafficEntry` capturing TX/RX frames across all 4 families and redacting `WIFI PASSWORD`, `BLUETOOTH SETSSID`/`GETPASSWORD`, `WLAN PWD`/`LAP`, `XSL` Wi-Fi passwords, and tokens.
- `lib/src/stubs/`: Transport-boundary loopback stubs for offline Simulation Mode:
  - `in_memory_io.dart`: `InMemoryHttpClient`, `InMemorySocket`, `InMemoryRawDatagramSocket` (zero OS socket binds; works identically in app runtime and `flutter test`).
  - `sim_esc_wan_stub.dart`: `SimEscConnectedDevice` + `SimCloudWanBackend` (REST + OSS multipart + MQTT v5 broker using `MqttV5PacketCodec`).
  - `sim_thermal_lan_stub.dart`: `SimThermalWifiDevice` + `SimThermalLanBackend` wired into `Network.scoped`.
  - `sim_sublimation_stub.dart`: `SimulatedSublimationBleDevice`, `SimulatedSublimationUdpTransport`, and `SimulatedSublimationTcpDevice` (8B RPC + `cache > 0` flow control + `1B 44` + OTA).
  - `sim_inkjet_stub.dart`: `SimulatedInkjetBleDevice` (`ACL cmd=24`), `SimulatedInkjetMdnsBrowser`, `SimulatedInkjetSoftApProbe`, `SimulatedInkjetNetworkBinder`, and `SimulatedInkjetTcpDevice` (`XSL` + `XPL`).
- `lib/src/protocol_registry.dart`: `registerDemoProtocols()` calling `registerSublimationProtocol()` and explicitly registering `InkjetPrinterDriver`, `InkjetBleProvisioner`, and `InkjetDiscoveryAdapter` onto `CloudPrinterRegistry`.
- `lib/src/controllers/`: `DemoCoordinator`, `EscWanController`, `ThermalLanController`, `SublimationController`, `InkjetController`, and `RealTransportHelper`.
- `lib/src/widgets/`: `EscWanTab`, `ThermalLanTab`, `SublimationTab`, `InkjetTab`, `ProtocolInspectorDrawer`, and shared Material 3 panel/card components.
- `lib/src/utils/test_image_generator.dart`: Pure-Dart RGBA pattern generators for sublimation cards and multi-page inkjet test sheets (no binary assets required).

## 2. Dependency Resolution (Sibling Checkout vs Worktree)

`pubspec.yaml` declares all 13 direct and transitive `psdk_*` packages using `path: ../../psdk/dart/...`, matching the sibling-checkout layout:

```text
parent-dir/
├── psdk/
│   └── dart/...
└── psdk-examples/
    └── cloud-print-demo/
```

When developing inside a Git worktree (`.worktrees/<branch>/cloud-print-demo/`), the demo directory sits 4 levels below `parent-dir/`. Add a gitignored `pubspec_overrides.yaml` in `cloud-print-demo/`:

```yaml
dependency_overrides:
  psdk_bluetooth_ble:
    path: ../../../../psdk/dart/devices/bluetooth_ble
  psdk_bluetooth_traits:
    path: ../../../../psdk/dart/devices/bluetooth_traits
  psdk_cloud_wan:
    path: ../../../../psdk/dart/devices/cloud_wan
  psdk_color_core:
    path: ../../../../psdk/dart/algorithms/color_core
  psdk_device_adapter:
    path: ../../../../psdk/dart/packages/device_adapter
  psdk_frame_cloud:
    path: ../../../../psdk/dart/packages/frame_cloud
  psdk_frame_father:
    path: ../../../../psdk/dart/packages/frame_father
  psdk_fruit_esc:
    path: ../../../../psdk/dart/fruits/esc
  psdk_fruit_inkjet:
    path: ../../../../psdk/dart/fruits/inkjet
  psdk_fruit_sublimation:
    path: ../../../../psdk/dart/fruits/sublimation
  psdk_fruit_wifi:
    path: ../../../../psdk/dart/fruits/wifi
  psdk_imageb:
    path: ../../../../psdk/dart/algorithms/imageb
  psdk_network:
    path: ../../../../psdk/dart/devices/network
```

Both `pubspec_overrides.yaml` and `pubspec.lock` are listed in `cloud-print-demo/.gitignore` so worktree-relative paths are never committed.

## 3. Simulation vs Real Device Mode

- **Simulation Mode** injects loopback implementations at the transport boundary (`ConnectedDevice`, `SublimationUdpTransport`, `Network.scoped` socket binders, `CloudWanConfig.custom` factories, `InkjetMdnsBrowser`, `InkjetSoftApProbeTransport`, `InkjetNetworkBinder`) and resolves `PureDartColorCoreEngine()` automatically when native `libcolor_core.so` is absent.
- **Real Device Mode** starts a fresh device session. The inspector records BLE/TCP transfer sizes, bounded raster previews, sublimation UDP datagrams, HTTP methods and response codes, and MQTT byte counts. It omits real provisioning payloads and cloud credentials. The SDK opens the following connections.
  - `BLEBluetooth.scoped(config: BleConnectionConfig..., enableStatePolling: false)` with per-family GATT profiles (`BleConnectionConfig.sublimation`, `BleConnectionConfig.inkjet`, or `preferredMtu: 512`), guarding `MissingPluginException` / `PlatformException`.
  - `Network.scoped(...)` for UDP `22368`, mDNS `_printer._tcp`, SoftAP `:9100`, and TCP `:9100`.
  - `CloudWanPrinterDriver` against configured REST + MQTT v5 TLS endpoints.

## 4. Platform Permissions

- **Android** (`android/app/src/main/AndroidManifest.xml`): Declares `BLUETOOTH`, `BLUETOOTH_ADMIN`, `BLUETOOTH_SCAN` (`neverForLocation`), `BLUETOOTH_CONNECT`, `ACCESS_FINE_LOCATION`, `INTERNET`, `ACCESS_WIFI_STATE`, `CHANGE_WIFI_STATE`, `ACCESS_NETWORK_STATE`, and `CHANGE_WIFI_MULTICAST_STATE`. Release signing and `@mipmap/ic_launcher` binary assets are intentionally omitted.
- **iOS** (`ios/Runner/Info.plist` & `ios/Podfile`): Declares `NSBluetoothAlwaysUsageDescription`, `UIBackgroundModes` (`bluetooth-central`), `NSLocalNetworkUsageDescription`, and `NSBonjourServices` (`_printer._tcp`).

## 5. Verification Commands

```sh
cd cloud-print-demo
dart format --output=none --set-exit-if-changed .
flutter pub get
flutter analyze
flutter test
flutter build apk --debug
```
