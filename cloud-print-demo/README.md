# Cloud & Color Print Flutter Demo (`cloud-print-demo`)

Unified 4-in-1 Flutter Material 3 example demonstrating all four `CloudPrinterFamily` Wi-Fi and color printing protocol stacks from `prtmax/psdk` inside a single application.

> Developer guide: see [DEV_GUIDE.md](./DEV_GUIDE.md) for architecture, protocol flows, Simulation vs Real Device mode details, worktree dependency overrides, and troubleshooting.

## Protocol Tracks

1. **`CloudPrinterFamily.escWanCloud`** (`psdk_fruit_esc` + `psdk_cloud_wan`)
   - ESC binary TLV Wi-Fi provisioning (`ESetWifi` w/ LE16 length, `ESetHost`, `ESetKey`, `EGetKey`, `EGetWifiSta`, `EGetWifiName`, `EResetNetworkInfo`, `ESN`, `EMac`, `EPrinterVersion`, `EscWifiResponseParser`).
   - Cloud WAN channel (`CloudWanPrinterDriver`: device-token auth, `CloudObjectUploader` OSS multipart upload, REST print job submission, `MqttV5TlsClient` stream + 5s HTTP polling fallback, `>=3` poll failures -> `offline`, fault codes `6001..6013`, cancel).
2. **`CloudPrinterFamily.thermalLanStream`** (`psdk_fruit_wifi` + `psdk_network`)
   - Dual text provisioning dialects (`BluetoothAtWifiCommands` & `TsplWlanCommands` / `BasicWIFI`).
   - `Network.scoped` UDP `22368` discovery (with password redaction) + TCP `:9100` `NetworkConnectedDevice` + `StreamJobSession` print streaming & cancellation.
3. **`CloudPrinterFamily.sublimationRpc`** (`psdk_fruit_sublimation` + `psdk_color_core`)
   - Dual-mode BLE provisioning (`0x180B` AT text & `0xA5 0x53` binary mesh STA/SoftAP).
   - Dual-mode LAN discovery (`UDP 22368` & `UDP 1901`) + `UDPCommandHelper` (`1901`).
   - 8B RPC dashboard (40B status, ribbon %, temperatures, card position, `autoShutDownMinutes`), mechanical actions (`Inject`, `Eject`, `Hold Eject`, `Flip`, `Move RFID`, `Move Back`, `Recycle`, `Init`, `Clear Cache`, `Self Test`, `Test Card`), and `1B 44` multi-plane card printing (`Y/M/C/O` + `K`) with `cache > 0` flow control.
4. **`CloudPrinterFamily.colorInkjetPjl`** (`psdk_fruit_inkjet` + `psdk_color_core`)
   - BLE `0x180A/0xFF00` `ACL` `cmd=24` (`187B` + `16B` ACK) provisioning + mDNS `_printer._tcp` & SoftAP discovery.
   - `XSL` C/M/Y/K ink levels, active status push, 30+ hardware fault presets, nozzle maintenance (`Clean`, `Deep Clean`, `Test`, `Wet 0/1/4/8h`, `Calibrate`, `Factory Reset`), built-in pages, `InkjetPreflightChecker` confirmation dialogs, and `XPL` multi-page JBIG-1 streaming with N-up/custom paper/borderless & mid-job cancel.

## Operating Modes & Protocol Inspector

- **Simulation Mode (Default)**: Exercises the `psdk` encoders, decoders, drivers, and `PureDartColorCoreEngine` offline against in-process transport-boundary loopback stubs.
- **Real Device Mode**: Connects to physical hardware via `BLEBluetooth`, `Network.scoped`, and `CloudWanPrinterDriver`.
- **Protocol Inspector Drawer**: Tap the terminal icon in the top AppBar to inspect simulated protocol frames and real BLE/TCP transfers, HTTP requests and MQTT traffic (hex + decoded summary + secret redaction) filtered by `CloudPrinterFamily` and direction. Real device traffic shows transfer sizes and bounded raster previews. Real HTTP/MQTT entries show request methods, status codes or byte counts; Simulation Mode also decodes cloud protocol fields.

## Run & Verify

From a sibling checkout (`psdk/` and `psdk-examples/` sharing the same parent directory):

```sh
cd cloud-print-demo
flutter pub get
dart format --output=none --set-exit-if-changed .
flutter analyze
flutter test
flutter run
```

> Inside a Git worktree (`.worktrees/<name>/cloud-print-demo/`), create a gitignored `pubspec_overrides.yaml` pointing the 13 `psdk_*` packages to `../../../../psdk/dart/...`; see [DEV_GUIDE.md](./DEV_GUIDE.md).
