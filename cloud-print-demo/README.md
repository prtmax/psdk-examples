# Cloud & Color Print Flutter Demo (`cloud-print-demo`)

Unified 4-in-1 Flutter Material 3 example demonstrating all four `CloudPrinterFamily` Wi-Fi and color printing protocol stacks from `prtmax/psdk` inside a single application.

> Developer guide: see [DEV_GUIDE.md](./DEV_GUIDE.md) for architecture, protocol flows, Simulation vs Real Device mode details, worktree dependency overrides, and troubleshooting.

## Protocol Tracks

1. **`CloudPrinterFamily.escWanCloud`** (`psdk_fruit_esc` + `psdk_cloud_wan`)
   - ESC binary TLV Wi-Fi provisioning (`ESetWifi` w/ LE16 length, `ESetHost`, `ESetKey`, `EGetKey`, `EGetWifiSta`, `EGetWifiName`, `EResetNetworkInfo`, `ESN`, `EMac`, `EPrinterVersion`, `EscWifiResponseParser`).
   - Cloud WAN channel (`CloudWanPrinterDriver`: device-token auth, `CloudObjectUploader` OSS multipart upload, REST print job submission, `MqttV5TlsClient` stream + 5s HTTP polling fallback, `>=3` poll failures -> `offline`, fault codes `6001..6013`, cancel).
2. **`CloudPrinterFamily.thermalLanStream`** (`psdk_fruit_wifi` + `psdk_network`)
   - 与 4 寸热升华共用 `LanSetupController` / `LanSetupPanel`：使用 `BLUETOOTH SETSSID`、`BLUETOOTH GETLINKSTATE` 配置 Wi-Fi；统一通过 `Network.scoped` 仅使用 UDP `22368` 发现打印机，按 IP 去重、保留网卡信息并选择目标设备。
   - 显示名使用 UDP 22368 的 `MODEL + WIFI MAC 后四位`，后缀统一大写。demo 不发送 UDP 1901 发现或状态指令；底层 SDK 的相关能力保留供其他机型使用。
   - TCP `:9100` `NetworkConnectedDevice` + `StreamJobSession` print streaming & cancellation.
3. **`CloudPrinterFamily.sublimationRpc`** (`psdk_fruit_sublimation` + `psdk_color_core`)
   - 复用上述蓝牙 Wi-Fi 配网与 UDP 发现流程；demo 已移除 Mesh、SoftAP 配网和额外的 `WLAN SSID` / `WLAN PWD` 分支。
   - 8B RPC dashboard (40B status, ribbon %, temperatures, card position, `autoShutDownMinutes`), mechanical actions (`Inject`, `Eject`, `Hold Eject`, `Flip`, `Move RFID`, `Move Back`, `Recycle`, `Init`, `Clear Cache`, `Self Test`, `Test Card`), and `1B 44` multi-plane card printing (`Y/M/C/O` + `K`) with `cache > 0` flow control.
4. **`CloudPrinterFamily.colorInkjetPjl`** (`psdk_fruit_inkjet` + `psdk_color_core`)
   - BLE `0x180A/0xFF00` `ACL` `cmd=24` (`187B` + `16B` ACK) provisioning + UDP `22368` (`DIAGNOSTIC REPORT NETBROADCAST`), UDP `4201` multicast, mDNS `_printer._tcp` & SoftAP discovery.
   - 兼容 `FF00` 仅支持读/写、不支持通知的喷墨固件：通过读取特征轮询 ACK；支持通知的固件仍使用通知。连接失败后会释放原生连接及订阅，允许重新扫描、连接。
   - ACL 配网有阶段提示和“取消配网”。准备 GATT、写入及读 ACK 共用最长 45 秒期限；Android/Windows 的单次原生写入另有 10 秒期限。回调未返回时取消或超时会释放等待并断开该连接，需重新连接后重试；仅收到有效的 16B ACK 才显示成功。
   - `XSL` C/M/Y/K ink levels, active status push, 30+ hardware fault presets, nozzle maintenance (`Clean`, `Deep Clean`, `Test`, `Wet 0/1/4/8h`, `Calibrate`, `Factory Reset`), built-in pages, `InkjetPreflightChecker` confirmation dialogs, and `XPL` multi-page JBIG-1 streaming with N-up/custom paper/borderless & mid-job cancel.

## Operating Modes & Protocol Inspector

- **Simulation Mode (Default)**: Exercises the `psdk` encoders, decoders, drivers, and `PureDartColorCoreEngine` offline against in-process transport-boundary loopback stubs.
- **真机模式**：Android / Windows 通过 `psdk_bluetooth_windows`（底层 `bluetooth_low_energy`）扫描连接；iOS 保留 `psdk_bluetooth_ble`（底层 `ble_plugin`）。局域网与云打印使用 `Network.scoped`、`CloudWanPrinterDriver`。
- **中文界面**：页面、按钮、模式切换、故障及预检提示统一中文；协议名称与原始报文保留。
- **蓝牙设备列表**：点击扫描立即打开弹窗，边扫描边显示有名称的设备；隐藏空名称及纯空格名称。选中设备或关闭弹窗会停止扫描，扫描结束后可重试。
- **Wi-Fi 名称自动填写**：真机模式的所有配网页面自动读取当前连接的 Wi-Fi 名称，可手动修改，也可点输入框右侧图标重新读取；读取失败会提示原因，不覆盖读取期间的手动输入。手机需允许定位权限并开启定位服务；模拟模式保留示例名称。
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

> Inside a Git worktree (`.worktrees/<name>/cloud-print-demo/`), create a gitignored `pubspec_overrides.yaml` pointing the 14 `psdk_*` packages to `../../../../psdk/dart/...`; see [DEV_GUIDE.md](./DEV_GUIDE.md).

配网名称说明：现有 SDK 将 `BLUETOOTH SETSSID` / `GETLINKSTATE` 这组命令标记为 `WifiProvisionProtocol.bluetoothAtText`。demo 仅展示“蓝牙 Wi-Fi 配网”，不提供协议切换。H100 仍走其独立的 `ACL cmd=24` 配网，并在真机模式下同时使用 UDP 22368、UDP 4201 组播、mDNS / SoftAP 发现。
