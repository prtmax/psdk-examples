# EMAPI Flutter Demo 开发接入指南

## 1. 概述

本 Demo 演示如何通过 PSDK（Printer SDK）在 Flutter 应用中完成以下完整流程：

1. **蓝牙扫描** — 发现附近的 EMAPI 兼容打印机
2. **设备连接** — 通过 `ConnectedDevice` 适配器建立蓝牙连接
3. **EMAPI 指令交互** — 调用 `psdk_fruit_emapi` 门面 SDK 发送指令并接收上报
4. **文件传输** — OTA 固件升级、WiFi 文件下发
5. **ESC 打印** — 通过 `psdk_fruit_esc` 生成 ESC/POS 指令进行图片打印

Demo 同时内置 **模拟模式**，无需真实硬件即可验证完整 EMAPI 协议流程。

---

## 2. 工程结构

```
flutter/
├── lib/
│   ├── main.dart                          # 应用入口 & 主页面容器
│   └── src/
│       ├── bluetooth_printer_connector.dart  # 蓝牙扫描/连接抽象层
│       ├── emapi_demo_controller.dart        # 核心控制器：命令调度、状态管理
│       ├── emapi_formatters.dart             # 数据格式化（设备信息/RFID/状态等）
│       ├── entities/
│       │   └── emapi_demo_log_entry.dart     # 日志条目数据模型
│       ├── pages/
│       │   ├── scan_page.dart                # 蓝牙扫描页面
│       │   ├── function_page.dart            # 功能操作主页面
│       │   └── settings_page.dart            # 设置页（模拟模式开关）
│       └── widgets/
│           ├── common_widgets.dart           # 通用 UI 组件
│           ├── log_widgets.dart              # 日志面板组件（含 Hex 预览）
│           └── operation_sheet.dart          # 底部操作面板
├── android/                                 # Android 平台工程
│   └── app/src/main/
│       ├── AndroidManifest.xml              # 蓝牙权限声明
│       └── kotlin/.../MainActivity.kt       # Android SDK 版本通道
├── pubspec.yaml                             # 依赖声明
└── analysis_options.yaml                    # Lint 规则
```

---

## 3. 环境要求

| 项目 | 版本要求 |
|------|----------|
| Flutter SDK | ≥ 3.10（Dart SDK ≥ 3.10） |
| Android | minSdk 21, targetSdk 34+ |
| iOS | ≥ 13.0 |

当前 Demo 支持 **Android**（经典蓝牙）与 **iOS**（BLE）平台。

---

## 4. 快速开始

### 4.1 拉取代码

```bash
git clone https://github.com/prtmax/psdk-examples.git
cd psdk-examples/emapi-demo/flutter
```

所有 PSDK 依赖已发布到 pub.dev，无需额外拉取 `psdk` 主仓库。

### 4.2 安装依赖

```bash
flutter pub get
```

### 4.3 运行 Demo

```bash
# Android
flutter run

# iOS
cd ios && pod install && cd ..
flutter run
```

### 4.4 验证环境

```bash
dart format .
flutter analyze
flutter test
flutter build apk --debug
```

---

## 5. 核心依赖说明

Demo 依赖的 PSDK 包及其作用：

| 包名 | 作用 |
|------|------|
| `psdk_fruit_emapi` | **EMAPI 门面 SDK**，提供 `EmapiPrinter`、指令/上报模型 |
| `psdk_fruit_esc` | ESC/POS 指令生成器，用于构建图片打印指令 |
| `psdk_device_adapter` | `ConnectedDevice` 抽象，统一的设备连接接口 |
| `psdk_bluetooth_traits` | 蓝牙协议枚举（BLE / Classic） |
| `psdk_bluetooth_classic` | Android 经典蓝牙实现 |
| `psdk_bluetooth_ble` | BLE 蓝牙实现 |
| `psdk_bluetooth_windows` | Windows 蓝牙实现 |
| `psdk_imageb` | 图片处理支持 |
| `permission_handler` | 运行时权限申请 |
| `file_picker` | 文件选择（OTA / WiFi 文件 / ESC 图片） |

---

## 6. 接入开发步骤

以下从零开始说明如何在自己的 Flutter 应用中接入 PSDK EMAPI 功能。

### 6.1 添加依赖

在你的 `pubspec.yaml` 中添加：

```yaml
dependencies:
  psdk_fruit_emapi: ^0.1.5
  psdk_fruit_esc: ^0.1.5
  psdk_device_adapter: ^0.1.5
  psdk_bluetooth_classic: ^0.1.5    # Android 经典蓝牙
  psdk_bluetooth_ble: ^0.1.5        # BLE
  psdk_bluetooth_traits: ^0.1.5
  permission_handler: ^12.0.1
```

### 6.2 配置 Android 权限

在 `android/app/src/main/AndroidManifest.xml` 中声明蓝牙权限：

```xml
<!-- Android 12 以下 -->
<uses-permission android:name="android.permission.BLUETOOTH"
    android:maxSdkVersion="36" />
<uses-permission android:name="android.permission.BLUETOOTH_ADMIN"
    android:maxSdkVersion="36" />
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />

<!-- Android 12+ -->
<uses-permission android:name="android.permission.BLUETOOTH_SCAN"
    android:usesPermissionFlags="neverForLocation" />
<uses-permission android:name="android.permission.BLUETOOTH_CONNECT" />
```

### 6.3 蓝牙扫描与连接

参考 `bluetooth_printer_connector.dart`，核心流程：

```dart
// 1. 创建蓝牙实例（按平台选择）
final bluetooth = Platform.isAndroid
    ? ClassicBluetooth()
    : BLEBluetooth();

// 2. 请求运行时权限（Android 12+ 需要 BLUETOOTH_SCAN / BLUETOOTH_CONNECT）
await Permission.bluetoothScan.request();
await Permission.bluetoothConnect.request();

// 3. 开始扫描
await bluetooth.startDiscovery(disconnectConnectedDevice: false);

// 4. 监听发现设备
bluetooth.discovered().listen((device) {
    // 处理发现的设备
});

// 5. 连接设备
final connectedDevice = await bluetooth.connect(device);
```

### 6.4 建立 EMAPI 连接

通过 `ConnectedDevice` 创建 `EmapiPrinter` 实例：

```dart
import 'package:psdk_device_adapter/psdk_device_adapter.dart';
import 'package:psdk_fruit_emapi/psdk_fruit_emapi.dart';

// 将蓝牙 ConnectedDevice 包装为 EMAPI 连接
final connection = ConnectedDeviceEmapiConnection(connectedDevice);
final printer = EmapiPrinter(connection: connection);

// 监听打印机主动上报
printer.reports.listen((report) {
    // 处理上报：打印状态、升级状态、流控、蓝牙连接等
});
```

### 6.5 发送 EMAPI 指令

`EmapiPrinter` 提供了以下主要 API：

| API | 说明 |
|-----|------|
| `queryDeviceInfo()` | 查询设备基本信息（型号、版本、MTU 等） |
| `queryPrintStatus()` | 查询打印状态（纸张、电量、温度等） |
| `printSelfTestPage()` | 打印自检页 |
| `sleepShutdown()` | 休眠关机 |
| `setShutdownTime(minutes:)` | 设置自动关机时间 |
| `queryRfidUid()` | 查询 RFID 卡 UID |
| `queryRfidCardInfo()` | 查询 RFID 卡信息（纸张型号/尺寸等） |
| `queryRfidPaperLength()` | 查询卡内纸张长度 |
| `setRfidAuthFailureHandling(policy)` | 设置 RFID 认证失败处理策略 |
| `setWifiConfig(ssid:, password:)` | 设置 WiFi 配网信息 |
| `queryWifiConnectionState()` | 查询 WiFi 模块连接状态 |
| `queryWifiHotspotInfo()` | 查询 WiFi 热点信息 |
| `startMainControllerOta(totalSize:)` | 开始 OTA 升级 |
| `transferMainControllerOtaChunk(index:, data:)` | 传输 OTA 数据块 |
| `finishMainControllerOta()` | 完成 OTA 传输 |
| `upgradeMainController()` | 触发固件升级 |
| `startWifiFileDownload(fileType:, totalSize:)` | 开始 WiFi 文件下载 |
| `transferWifiFileDownloadChunk(index:, data:)` | 传输 WiFi 文件数据块 |
| `finishWifiFileDownload()` | 完成 WiFi 文件下载 |
| `printEsc(bytes)` | 发送 ESC/POS 打印指令 |

---

## 7. 核心架构设计

### 7.1 整体流程

接入 PSDK 只需两步：**连上设备 → 发指令**。

```mermaid
flowchart LR
    A[🔍 蓝牙扫描<br/>发现打印机] --> B[🔗 连接设备<br/>获得 ConnectedDevice]
    B --> C[📦 创建 EmapiPrinter<br/>EmapiPrinter(connection)]
    C --> D[📤 发送指令<br/>queryDeviceInfo / OTA / ESC...]
    D --> E[📥 接收结果 & 上报<br/>返回值 + reports 流]
```

**连接阶段**：`App` → `BluetoothPrinterConnector` → 平台蓝牙 API → `ConnectedDevice`

**指令阶段**：`App` → `EmapiPrinter` → 蓝牙写入 → 打印机 → 蓝牙回传 → `EmapiPrinter` 解析 → 返回结果 + `reports` 流

### 7.2 状态管理

Demo 使用简单的 `ChangeNotifier` 模式（非完整状态管理框架），核心状态字段：

| 字段 | 含义 |
|------|------|
| `initialized` | 蓝牙适配器是否已初始化 |
| `bluetoothEnabled` | 系统蓝牙是否开启 |
| `scanning` | 是否正在扫描 |
| `connecting` | 是否正在连接 |
| `connected` | 是否已连接打印机 |
| `simulationMode` | 是否处于模拟模式 |
| `busy` | 是否有操作正在执行（连接或指令） |

---

## 8. 模拟模式

在 **设置页** 开启模拟模式后，无需真实蓝牙和打印机硬件即可验证完整的 EMAPI 协议交互流程：

- 扫描生成 1 台虚拟蓝牙设备
- 所有 EMAPI 指令返回模拟数据（包含完整的 TLV 编码响应）
- OTA / WiFi 文件传输模拟分块进度
- 模拟主动上报（流控、升级状态、WiFi 配网状态等）

模拟模式下指令和上报的字节流格式与真实设备完全一致，适合用于：
- 前期协议联调
- UI 流程验证
- 无硬件环境下的开发测试

---

## 9. 日志与调试

Demo 提供三栏日志面板，实时展示通信细节：

| 日志栏 | 内容 |
|--------|------|
| **发送指令** | 每次 EMAPI 请求的原始字节（Hex）预览 |
| **命令结果** | 指令执行结果（成功/失败消息 + 响应字节） |
| **上报解析** | 打印机主动上报的解析结果 |

每个日志条目支持：
- Hex 字节预览（可切换每行字节数、CR/LF 换行）
- 一键复制 Hex 数据
- 展开/收起

---

## 10. OTA 升级流程

```
选择 OTA 文件 → startMainControllerOta(totalSize)
  → 循环 transferMainControllerOtaChunk(index, data)
  → finishMainControllerOta()
  → upgradeMainController()
```

- 分块大小根据 `queryDeviceInfo()` 返回的 MTU 自动计算
- 进度通过 `otaSentBytes / otaTotalBytes` 实时反馈
- 升级状态通过 `EmapiUpgradeStatusReport` 上报获取

---

## 11. 常见问题

### Q1: `flutter pub get` 报找不到 psdk_* 包？

所有 PSDK 包已发布到 pub.dev。请检查 `pubspec.yaml` 中依赖版本号是否正确，确保网络能正常访问 pub.dev。如遇临时网络问题可设置国内镜像：

```bash
export PUB_HOSTED_URL=https://pub.flutter-io.cn
```

### Q2: Android 扫描不到蓝牙设备？

- 检查系统蓝牙是否已开启
- Android 12+ 需要在系统设置中授予「附近设备」权限
- Android 11 及以下需要授予位置权限（蓝牙扫描需要）

### Q3: 连接打印机后指令超时？

- 确认打印机支持 EMAPI 协议
- 检查 MTU 协商是否正常（通过 `queryDeviceInfo` 查看）
- 在日志面板查看原始字节确认协议格式

### Q4: 如何扩展支持 Windows？

在 `BluetoothPrinterConnector.init()` 中已有 Windows 平台判断骨架，待对应平台的 PSDK 蓝牙包就绪后即可启用：

```dart
if (Platform.isWindows) {
    _bluetooth = WindowsBluetooth();
}
```

iOS 平台已原生支持（BLE），无需额外配置。

---

## 12. 相关资源

- PSDK 包一览（pub.dev）：
  - [`psdk_fruit_emapi`](https://pub.dev/packages/psdk_fruit_emapi) — EMAPI 协议门面
  - [`psdk_fruit_esc`](https://pub.dev/packages/psdk_fruit_esc) — ESC/POS 指令生成
  - [`psdk_device_adapter`](https://pub.dev/packages/psdk_device_adapter) — 设备连接抽象
  - [`psdk_bluetooth_classic`](https://pub.dev/packages/psdk_bluetooth_classic) — Android 经典蓝牙
  - [`psdk_bluetooth_ble`](https://pub.dev/packages/psdk_bluetooth_ble) — BLE 蓝牙
- Flutter 官方文档：[https://flutter.dev/docs](https://flutter.dev/docs)
