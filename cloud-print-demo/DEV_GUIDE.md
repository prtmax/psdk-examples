# Developer Guide (`cloud-print-demo`)

## 1. Architecture Overview

`cloud-print-demo` demonstrates all four `CloudPrinterFamily` tracks from `prtmax/psdk` in a single Material 3 Flutter app:

- `lib/main.dart`: `CloudPrintDemoApp` (`#256B75` / `#F6F8F6` Material 3 theme) and `CloudPrintDemoPage` (global `Sim` / `Real` mode switcher, `TabBar` keyed by `CloudPrinterFamily.values`, and `ProtocolInspectorDrawer` endDrawer).
- UI uses Simplified Chinese (`zh_CN`) with Flutter Material localization; protocol names and wire data remain unchanged.
- `WifiSsidField` is shared by all provisioning forms. In real mode it uses `RealTransportHelper.readCurrentWifiName()` / `network_info_plus` to autofill SSID, coalesces concurrent permission/read requests, removes Android's surrounding quotes, and preserves intervening manual edits. The trailing button explicitly rereads the network. Simulation performs no Wi-Fi read. Mobile reads require foreground location access and enabled location services; Android precise location is needed for SSID. iOS includes `NSLocationWhenInUseUsageDescription` and the Access WiFi Information entitlement, which must also be supported by the signing profile; iOS device/signing validation requires a Mac.
- The BLE picker opens immediately and listens to `RealTransportHelper` scan updates. Devices with null, empty, or whitespace-only names are excluded before deduplication, allowing a later named advertisement to appear. Closing/selecting stops the scan; selection waits for cleanup before connecting.
- Thermal and 4-inch sublimation printers use UDP 22368 only (`DIAGNOSTIC REPORT NETBROADCAST`), matching the legacy discovery flow. Names derive from `MODEL` and the final four Wi-Fi MAC hex digits in uppercase. The UDP 1901 discovery and status-test UI/controller/stub branches were removed; TCP 9100 still carries ordinary status/control/print traffic. The sibling PSDK retains 1901 support for other consumers, including its deterministic 22368-over-1901 display-name merge policy.
- Color inkjet real-device discovery runs UDP 22368, UDP 4201 multicast, mDNS `_printer._tcp.`, and SoftAP probes concurrently. UDP uses child scanners from a per-scan `Network.scoped`; the inkjet adapter owns and disposes those scanners, then the controller disposes the network scope.
- `lib/src/models/`:
  - `demo_mode.dart`: `DemoRunMode` (`simulation`, `realDevice`) and `CloudPrinterFamilyUi` metadata.
  - `protocol_inspector.dart`: `ProtocolInspectorController` & `ProtocolTrafficEntry` capturing TX/RX frames across all 4 families and redacting `WIFI PASSWORD`, `BLUETOOTH SETSSID`/`GETPASSWORD`, `WLAN PWD`/`LAP`, `XSL` Wi-Fi passwords, and tokens.
- `lib/src/controllers/lan_setup_controller.dart` and `lib/src/widgets/lan_setup_panel.dart`: thermal and 4-inch sublimation share `BLUETOOTH SETSSID` / `GETLINKSTATE` provisioning and the same real `Network` UDP 22368 scanner, result deduplication, and device selection. Mesh, provisioning protocol selection, and the extra `WLAN SSID` / `WLAN PWD` path were removed from this demo. SDK protocol identifier `bluetoothAtText` is retained because it names these existing text commands.
- `lib/src/stubs/`: Transport-boundary loopback stubs for offline Simulation Mode:
  - `sim_lan_ble_device.dart`: shared `SimulatedLanBleDevice` for both LAN families, with credential redaction.
  - `in_memory_io.dart`: `InMemoryHttpClient`, `InMemorySocket`, `InMemoryRawDatagramSocket` (zero OS socket binds; works identically in app runtime and `flutter test`).
  - `sim_esc_wan_stub.dart`: `SimEscConnectedDevice` + `SimCloudWanBackend` (REST + OSS multipart + MQTT v5 broker using `MqttV5PacketCodec`).
  - `sim_thermal_lan_stub.dart`: `SimThermalLanBackend` wired into `Network.scoped`.
  - `sim_sublimation_stub.dart`: `SimulatedSublimationUdpTransport`, and `SimulatedSublimationTcpDevice` (8B RPC + `cache > 0` flow control + `1B 44` + OTA).
  - `sim_inkjet_stub.dart`: `SimulatedInkjetBleDevice` (`ACL cmd=24`), `SimulatedInkjetMdnsBrowser`, `SimulatedInkjetSoftApProbe`, `SimulatedInkjetNetworkBinder`, and `SimulatedInkjetTcpDevice` (`XSL` + `XPL`).
- `lib/src/protocol_registry.dart`: `registerDemoProtocols()` calling `registerSublimationProtocol()` and explicitly registering `InkjetPrinterDriver`, `InkjetBleProvisioner`, and `InkjetDiscoveryAdapter` onto `CloudPrinterRegistry`.
- `lib/src/controllers/`: `DemoCoordinator`, `EscWanController`, `ThermalLanController`, `SublimationController`, `InkjetController`, and `RealTransportHelper`.
- `lib/src/widgets/`: `EscWanTab`, `ThermalLanTab`, `SublimationTab`, `InkjetTab`, `ProtocolInspectorDrawer`, and shared Material 3 panel/card components.
- `lib/src/utils/test_image_generator.dart`: Pure-Dart RGBA pattern generators for sublimation cards and multi-page inkjet test sheets (no binary assets required).

## 2. Dependency Resolution (Sibling Checkout vs Worktree)

`pubspec.yaml` declares all 14 direct and transitive `psdk_*` packages using `path: ../../psdk/dart/...`, matching the sibling-checkout layout:

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
  psdk_bluetooth_windows:
    path: ../../../../psdk/dart/devices/bluetooth_windows
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
  - `RealTransportHelper` chooses `WindowsBluetooth.scoped` (`psdk_bluetooth_windows` / `bluetooth_low_energy`) on Android and Windows; iOS retains `BLEBluetooth.scoped` (`psdk_bluetooth_ble` / `ble_plugin`). Both use the same demo device picker. Generic text provisioning detects GATT characteristics; H100 explicitly selects `0x180A/0xFF00`. Android requests scan/connect permissions on API 31+, location on older versions, and waits for native Bluetooth state initialization.
  - The Windows/Android SDK session awaits `WindowsConnectedDevice.ready` and passes the actual `negotiatedMtu` into provisioning. Notification setup checks characteristic properties: read/write-only H100 firmware uses the native read hook to poll its ACK; notify/indicate firmware enables notifications. Failed initialization/GATT discovery disconnects the native peripheral before retrying, and disconnect releases its event subscriptions even after initialization failure. Scoped sessions omit legacy background polling and are disposed with the demo session. These supporting changes live in the sibling `psdk/dart/devices/bluetooth_windows` checkout and must accompany the demo. iOS keeps its existing provider-reported MTU behavior; iOS hardware validation is separate.
  - Color inkjet uses `Network.scoped(...)` for UDP `22368`, UDP `4201` multicast, and mDNS `_printer._tcp`, with SoftAP `:9100` fallback. TCP `:9100` carries XSL/XPL traffic after selection.
  - `CloudWanPrinterDriver` against configured REST + MQTT v5 TLS endpoints.

## 4. Platform Permissions

H100 ACL 配网不启用 FF03 额度流控。共享 Android/Windows 蓝牙库新增可选
`BleFlowControlOptions(enabled: true)`，用于 `FF00/FF02/FF01/FF03` 设备，
参考 iOS 的增量额度规则；具体用法见兄弟 SDK 的
`dart/devices/bluetooth_windows/README.md`。不要因为底层支持该能力就为所有机型开启。
配网整体 45 秒期限覆盖 GATT 准备、发送和 ACK 读取，取消与期限均能中止等待原生回调。
有原生 I/O 未结束时会断开连接，避免下一次操作继续卡在同一 ATT 会话；页面显示具体阶段和最终结果。
H100 连接后不再额外调用 `discoverGATT`：读 ACK 使用连接对象的 `readCharacteristic()`，
与写入共用连接时选定的 GATT 特征。Android 插件按原生对象标识查找回调，重新发现服务后
继续使用旧特征可能造成写入完成回调无法匹配。
2026-11-21 在已连接的 Android / H100 上复测：移除重复发现后收到有效 ACL
`status=1` ACK，`ProvisionResult.success=true`，页面退出忙碌状态，蓝牙连接仍保持。
这项验证覆盖 H100 配网；FF03 额度流控仍只有模拟传输测试证据。

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
