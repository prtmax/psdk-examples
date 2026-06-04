# EMAPI 打印机对接文档

> **版本**: 0.1.18-GA &nbsp;|&nbsp; **适用平台**: Android (Java) &nbsp;|&nbsp; **通信方式**: Bluetooth Classic / 模拟
>
> EMAPI（Embedded Printer API）是 PSDK 提供的一套**二进制命令协议级通信库**，用于 host 端（Android/iOS）通过蓝牙与打印机主板进行双向通信，完成参数查询、状态监测、打印控制、OTA 升级等功能。

---

## 目录

1. [快速一览](#快速一览)
2. [整体架构](#整体架构)
3. [环境准备](#环境准备)
4. [建立连接](#建立连接)
5. [API 速查表](#api-速查表)
   - [系统类](#1-系统类)
   - [RFID 类](#2-rfid-类)
   - [WIFI 类](#3-wifi-类)
   - [打印机类](#4-打印机类)
   - [文件传输 / OTA 类](#5-文件传输--ota-类)
6. [异步上报（Report）处理](#异步上报report处理)
7. [完整 Demo 核心代码走读](#完整-demo-核心代码走读)
8. [常见问题](#常见问题)

---

## 快速一览

> **对接 EMAPI 只需要 3 步：** `连接设备` → `构建 Printer` → `调用 API / 监听上报`

```java
// 1) 通过 PSDK 蓝牙扫描 & 连接，拿到 ConnectedDevice
ConnectedDevice device = ... ;  // PSDK 连接回调返回

// 2) 用 ConnectedDevice 构建 EmapiPrinter
EmapiPrinter printer = EmapiPrinter.connectedDevice(device)
    .fallbackMtu(512)
    .build();

// 3) 查询信息 & 打印
EmapiPrinterInfo info = printer.queryDeviceInfo();
byte[] escData = ... ;  // 生成的 ESC 位图指令
printer.printEsc(escData);

// 4) 后台线程持续读取主动上报
while (true) {
    EmapiReport report = printer.readNextReport();
    // 处理纸张状态、打印结果、OTA 状态等上报...
}
```

**Demo 项目路径**: `https://github.com/prtmax/psdk-examples/tree/main/android-native-java/emapi-android-demo`

---

## 整体架构

```
┌─────────────────────────────────────────────┐
│              你的 App (Host)                │
│  ┌───────────────────────────────────────┐  │
│  │          EmapiPrinter                 │  │
│  │   .queryDeviceInfo()                  │  │
│  │   .printEsc(bytes)   .queryRfidUid() │  │
│  │   .queryPrintStatus()  .startOta()   │  │
│  └──────────┬────────────────────────────┘  │
│             │ EmapiConnection 接口           │
│  ┌──────────▼────────────────────────────┐  │
│  │   ConnectedDeviceEmapiConnection      │  │
│  │   (包装 PSDK ConnectedDevice)          │  │
│  └──────────┬────────────────────────────┘  │
│             │                                │
│  ┌──────────▼────────────────────────────┐  │
│  │   PSDK Bluetooth Classic 传输层        │  │
│  └──────────┬────────────────────────────┘  │
└─────────────┼────────────────────────────────┘
              │  蓝牙 SPP (Binary Frames)
┌─────────────▼────────────────────────────────┐
│          打印机主板 (Device/Firmware)         │
│   接收命令 → 执行 → 回复 / 主动上报           │
└──────────────────────────────────────────────┘
```

- **同步命令**：每条 `queryXxx()` / `setXxx()` 会发送请求，**阻塞等待**对应应答。
- **异步上报**：打印机主动推送（状态变化、打印结果等），通过 `readNextReport()` 轮询获取。

---

## 环境准备

### 1) 添加依赖

引入 PSDK 的 fat-jar 或 maven 坐标：

```groovy
// build.gradle
dependencies {
    implementation files('libs/fat-generic-super-fat-sdk-0.1.18-GA.jar')
}
```

> `fat-generic-super-fat-sdk` 聚合了 `emapi`、`device-adapter`、`bluetooth` 等模块，无需单独引入。

### 2) Android 权限（AndroidManifest.xml）

```xml
<!-- 蓝牙基础 -->
<uses-permission android:name="android.permission.BLUETOOTH" />
<uses-permission android:name="android.permission.BLUETOOTH_ADMIN" />

<!-- Android 12+ -->
<uses-permission android:name="android.permission.BLUETOOTH_SCAN"
    android:usesPermissionFlags="neverForLocation" />
<uses-permission android:name="android.permission.BLUETOOTH_CONNECT" />

<!-- Android 11 及以下（经典蓝牙扫描需要定位） -->
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
```

### 3) 初始化 PSDK 蓝牙模块

```java
Bluetooth.getInstance().initialize(context.getApplicationContext());
```

---

## 建立连接

### 流程示意

```
扫描设备 → 选择设备 → 创建经典蓝牙连接 → 获取 ConnectedDevice → 构建 EmapiPrinter
```

### 关键代码

```java
// 1. 设置扫描回调
Bluetooth.getInstance().setDiscoveryListener(new DiscoveryListen() {
    @Override
    public void onDeviceFound(BluetoothDevice device, int rssi) {
        // 过滤 BLE 设备，只保留经典蓝牙
        if (device.getType() == BluetoothDevice.DEVICE_TYPE_LE) return;
        String name = device.getName();
        if (name == null || name.isEmpty()) return;
        // 将 device 展示到 UI 列表
    }
    @Override
    public void onDiscoveryError(int errorCode, String errorMsg) { /* 处理错误 */ }
});

// 2. 开始扫描
Bluetooth.getInstance().startDiscovery();

// 3. 用户选择设备后，创建连接
BluetoothDevice btDevice = bluetoothAdapter.getRemoteDevice(address);
Connection conn = Bluetooth.getInstance().createConnectionClassic(btDevice, new ConnectListener() {
    @Override
    public void onConnectSuccess(ConnectedDevice connectedDevice) {
        // ★ 得到了 ConnectedDevice ★
        // 用 ConnectedDevice 构建 EmapiPrinter
        EmapiPrinter printer = EmapiPrinter.connectedDevice(connectedDevice)
            .fallbackMtu(512)           // MTU 回退值（建议 512）
            .timeoutMs(2000)            // 命令超时（默认 2000ms）
            .maxRetries(3)              // 重试次数（默认 3）
            .build();
        // 启动上报监听线程...
    }
    @Override
    public void onConnectFail(String errMsg, Throwable e) { /* 连接失败 */ }
    @Override
    public void onConnectionStateChanged(BluetoothDevice btDevice, int state) {
        // STATE_CONNECTING → STATE_PAIRING → STATE_CONNECTED
    }
});

// 4. 执行连接
executor.execute(() -> conn.connect(null));
```

> **提示**：如果你已经有自己的蓝牙连接通道，只需要实现 `EmapiConnection` 接口（`write` / `read` / `close` 三个方法）即可接入 EMAPI。

---

## API 速查表

所有 API 调用都**阻塞等待**应答，请在后台线程执行。

### 1. 系统类

| 方法 | 说明 | 返回值 |
|------|------|--------|
| `queryDeviceInfo()` | 查询设备基本参数 | `EmapiPrinterInfo`（型号、序列号、版本、MTU） |
| `sleepShutdown()` | 使打印机进入休眠/关机 | `void` |
| `setShutdownTime(int minutes)` | 设置自动关机时间 | `void` |

**EmapiPrinterInfo 字段**:

| 字段 | 说明 |
|------|------|
| `getDeviceType()` | 设备类型 |
| `getDeviceModel()` | 设备型号 |
| `getBrand()` | 品牌 |
| `getSerialNumber()` | 序列号 |
| `getHardwareVersion()` | 硬件版本 |
| `getSoftwareVersion()` | 软件版本 |
| `getBootVersion()` | Boot 版本 |
| `getMtu()` | 协商后的 MTU |

### 2. RFID 类

| 方法 | 说明 | 返回值 |
|------|------|--------|
| `queryRfidUid()` | 读取 RFID/NFC 标签 UID | `String`（16进制字符串） |
| `queryRfidCardInfo()` | 读取耗材卡片信息 | `EmapiRfidCardInfo` |
| `queryRfidPaperLength()` | 读取卡片记录的纸张长度 | `long`（毫米） |
| `setRfidAuthFailureHandling(policy)` | 设置认证失败策略 | `void` |

**EmapiRfidCardInfo 字段**:

| 字段 | 说明 |
|------|------|
| `getPaperModel()` | 纸张型号 |
| `getPaperLength()` | 纸张长度 |
| `getPaperWidth()` | 纸张宽度 |
| `getPaperColor()` | 纸张颜色 |
| `getPaperMaterialNumber()` | 物料编号 |

**EmapiRfidAuthFailurePolicy**:

| 枚举值 | 说明 |
|--------|------|
| `ALLOW_PRINT` | 认证失败仍允许打印 |
| `FORBID_PRINT` | 认证失败禁止打印 |

### 3. WIFI 类

| 方法 | 说明 | 返回值 |
|------|------|--------|
| `setWifiConfig(ssid, password)` | 配置打印机 WiFi | `void` |
| `setWifiConfig(ssid, password, encryptionMethod)` | 配置 WiFi（含加密方式） | `void` |
| `queryWifiConnectionState()` | 查询 WiFi 连接状态 | `EmapiWifiConnectionState` |
| `queryWifiHotspotInfo()` | 查询 AP 热点信息 | `EmapiWifiHotspotInfo` |

**EmapiWifiConnectionState**:

| 枚举值 | 说明 |
|--------|------|
| `NOT_CONNECTED` | 未连接 |
| `HOTSPOT_CONNECTED` | 已连接热点（AP 模式） |
| `IOT_CONNECTED` | 已连接 IoT 平台 |
| `UNKNOWN` | 未知 |

**EmapiWifiHotspotInfo**:

| 字段 | 说明 |
|------|------|
| `getSsid()` | 热点名称 |
| `getRssi()` | 信号强度 |
| `getIp()` | IP 地址 |
| `getPort()` | 端口号 |

### 4. 打印机类

| 方法 | 说明 | 返回值 |
|------|------|--------|
| `queryPrinterParams()` | 查询打印参数（分辨率等） | `EmapiPrinterParams` |
| `queryPrintStatus()` | 查询当前打印状态 | `EmapiPrintStatus` |
| `printSelfTestPage()` | 打印自检页 | `void` |
| `printEsc(byte[] escBytes)` | ★ **打印 ESC 位图指令** | `void` |

**EmapiPrinterParams 字段**:

| 字段 | 说明 |
|------|------|
| `getPrintSize()` | 打印宽度（点数） |
| `getResolution()` | 分辨率（DPI） |
| `getDotsPerByte()` | 每字节点数 |

**EmapiPrintStatus 字段**:

| 字段 | 说明 |
|------|------|
| `getPaperStatus()` | 纸张状态 |
| `getCoverStatus()` | 开盖状态 |
| `getLowBattery()` | 低电量警告 |
| `getOverheat()` | 过热状态 |
| `getBatteryPercent()` | 电量百分比 |
| `getBatteryVoltage()` | 电池电压（mV） |
| `getTphTemperature()` | 打印头温度（℃） |

### 5. 文件传输 / OTA 类

| 方法 | 说明 |
|------|------|
| `startMainControllerOta(long totalSize)` | 开始主控 OTA |
| `transferMainControllerOtaChunk(int index, byte[] data)` | 传输 OTA 分块 |
| `finishMainControllerOta()` | 结束 OTA 传输 |
| `upgradeMainController()` | 触发主控升级 |
| `startWifiFileDownload(int fileType, long totalSize)` | 开始 WiFi 模块文件传输 |
| `transferWifiFileDownloadChunk(int index, byte[] data)` | 传输 WiFi 文件分块 |
| `finishWifiFileDownload()` | 结束 WiFi 文件传输 |

> **分块大小计算**：`chunkSize = (MTU - 帧头 - 命令头 - 4) & align32`，Demo 中使用 `(knownMtu - 8 - 4 - 4) / 32 * 32`，最小 32 字节。

---

## 异步上报（Report）处理

打印机在以下场景会**主动推送**上报帧，你需要在一个独立线程中循环读取：

```java
// 启动上报监听循环（在后台线程运行）
while (reportLoopRunning && printer != null) {
    try {
        EmapiReport report = printer.readNextReport();
        handleReport(report);
    } catch (EmapiProtocolException e) {
        // 读取超时，正常情况，继续等待
    } catch (EmapiConnectionException e) {
        break;  // 连接断开，退出循环
    }
}
```

### 所有上报类型

| 上报类 | 触发场景 | 关键字段 |
|--------|----------|----------|
| `EmapiPrinterStatusReport` | 打印机状态变化 | 纸张、开盖、电量、过热、NFC 识纸 |
| `EmapiPrintResultReport` | 打印完成 | `getResult()` 结果码 |
| `EmapiFlowControlReport` | 流控状态变化 | `isBusy()` 是否忙碌 |
| `EmapiUpgradeStatusReport` | OTA 升级状态变化 | `getStatus()` |
| `EmapiBluetoothConnectionReport` | 蓝牙连接状态变化 | `getState()` |
| `EmapiWifiConfigStatusReport` | 配网结果 | SSID、配网状态 |
| `EmapiUnknownReport` | 未知上报（原始命令） | `getCommand()` 原始数据 |

### 上报处理示例

```java
private void handleReport(EmapiReport report) {
    if (report instanceof EmapiPrintResultReport) {
        int result = ((EmapiPrintResultReport) report).getResult();
        // result == 0 → 打印成功
    } else if (report instanceof EmapiPrinterStatusReport) {
        EmapiPrinterStatusReport s = (EmapiPrinterStatusReport) report;
        if (s.getPaperStatus() != null && s.getPaperStatus() != 1) {
            // 缺纸提醒
        }
    } else if (report instanceof EmapiFlowControlReport) {
        boolean busy = ((EmapiFlowControlReport) report).isBusy();
        // busy 时暂停发送新命令
    }
    // ... 其他上报类型
}
```

---

## 完整 Demo 核心代码走读

> Demo 路径：`https://github.com/prtmax/psdk-examples/tree/main/android-native-java/emapi-android-demo`

### Demo 项目结构

```
app/src/main/java/com/printer/psdk/examples/emapi/
├── MainActivity.java          ← UI 层，按钮交互
├── EmapiDemoController.java   ← ★ 核心逻辑：连接、API 调用、上报处理
├── DeviceModel.java           ← 蓝牙设备数据模型
├── TracingEmapiConnection.java← 调试用连接包装（记录收发帧）
├── EscCommandBuilder.java     ← ESC 指令构建（位图打印）
├── EscPrintOptions.java       ← 打印选项（纸张类型、模式等）
└── LogEntry.java              ← 日志条目
```

### 核心流程：MainActivity ⇄ EmapiDemoController

```
MainActivity                 EmapiDemoController                  Printer
    │                              │                                  │
    │── scanBluetooth() ──────────→│── startDiscovery()               │
    │                              │── onDeviceFound() → add list     │
    │                              │                                  │
    │── connect(device) ──────────→│── createConnectionClassic()      │
    │                              │── onConnectSuccess()             │
    │                              │── build EmapiPrinter             │
    │                              │── startReportLoop() ────────────→│ readNextReport() loop
    │                              │                                  │
    │── printSelfTest() ──────────→│── printer.printSelfTestPage() ──→│
    │                              │                                  │
    │── printImage(path) ─────────→│── buildEscCommands()             │
    │                              │── printer.printEsc(bytes) ──────→│
    │                              │                                  │← printResultReport()
    │                              │←─ handleReport()                 │
    │←── onChanged() update UI ───│                                  │
```

### 关键代码片段（取自 Demo）

**1) 构建 EmapiPrinter**（`EmapiDemoController.connect()`）：

```java
tracingConnection = new TracingEmapiConnection(
    new ConnectedDeviceEmapiConnection(connectedDevice)
);
printer = EmapiPrinter.builder()
    .connection(tracingConnection)
    .fallbackMtu(512)
    .build();
```

**2) 查询设备信息**（`EmapiDemoController.queryDeviceInfo()`）：

```java
EmapiPrinterInfo info = printer.queryDeviceInfo();
// info.getDeviceModel()、info.getSerialNumber()、info.getMtu()...
if (info.getMtu() != null) {
    knownMtu = info.getMtu();  // 记录协商后的 MTU
}
```

**3) ESC 图片打印**（`EmapiDemoController.performEscPrint()`）：

```java
byte[] image = readFile(path);
byte[] escBytes = EscCommandBuilder.buildImagePrint(image, options);
// EscCommandBuilder 内部使用 PSDK GenericESC 构建完整指令链：
//   wakeup → enable → paperType → enableMode → thickness → image → position → stopJob
printer.printEsc(escBytes);
// 打印结果通过 EmapiPrintResultReport 异步上报
```

**4) OTA 升级**（`EmapiDemoController.performOta()`）：

```java
// ① 开始
printer.startMainControllerOta(fileBytes.length);

// ② 分块传输
int chunkSize = fileChunkSize();  // 基于 MTU 计算
for (int offset = 0; offset < bytes.length; offset += chunkSize) {
    byte[] chunk = Arrays.copyOfRange(bytes, offset, Math.min(offset + chunkSize, bytes.length));
    printer.transferMainControllerOtaChunk(index++, chunk);
}

// ③ 结束 & 触发升级
printer.finishMainControllerOta();
printer.upgradeMainController();

// 升级进度通过 EmapiUpgradeStatusReport 异步上报
```

**5) WiFi 配网**（`EmapiDemoController.setWifiConfig()`）：

```java
printer.setWifiConfig("MyWiFi", "password123");
// 配网结果通过 EmapiWifiConfigStatusReport 异步上报
```

---

## 常见问题

### Q1: 连接成功但 API 调用超时？

- 检查 `fallbackMtu` 是否设置合理（推荐 512）。
- 确认 `timeoutMs` 不要太小，蓝牙通信建议 >= 2000ms。
- 确保在**后台线程**调用 API，不要阻塞主线程。

### Q2: 如何判断打印机是否忙碌？

监听 `EmapiFlowControlReport`，`isBusy() == true` 时：
- 暂停发送新的打印任务。
- 等待 `isBusy() == false` 后继续。

### Q3: printEsc() 分片逻辑是什么？

`printEsc()` 内部会：
1. 调用 `queryDeviceInfo()` 获取 MTU。
2. 根据 `MTU - 帧开销` 计算每片有效载荷容量。
3. 自动将 ESC 字节数组分片发送，每片等待 ACK。

你只需传入完整的 ESC 字节数组即可，无需手动分片。

### Q4: 如何接入自定义传输层（非 PSDK 蓝牙）？

实现 `EmapiConnection` 接口即可：

```java
public class MyTransport implements EmapiConnection {
    @Override
    public void write(byte[] data) throws IOException {
        // 你的发送逻辑
    }
    @Override
    public byte[] read(int timeoutMs) throws IOException {
        // 你的接收逻辑（需阻塞等待 timeoutMs）
    }
    @Override
    public void close() throws IOException {
        // 你的断开逻辑
    }
}

// 使用自定义连接
EmapiPrinter printer = EmapiPrinter.builder()
    .connection(new MyTransport())
    .build();
```

### Q5: Demo 中 TracingEmapiConnection 是做什么的？

它是对 `EmapiConnection` 的**装饰器包装**，用于记录所有收发的原始帧数据，方便在 Demo UI 的日志面板中展示。**生产环境不需要这个**，直接使用 `ConnectedDeviceEmapiConnection` 即可。

---

> **更多问题？** 查阅 Demo 完整代码：`https://github.com/prtmax/psdk-examples/tree/main/android-native-java/emapi-android-demo`
