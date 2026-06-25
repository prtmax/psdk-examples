# 喷墨打印机蓝牙 Demo 开发文档

## 项目概述

本项目是基于 喷墨打印机 PSDK 的 Android 经典蓝牙示例程序，演示了如何通过蓝牙连接喷墨打印机并完成打印、状态查询、OTA 升级等操作。

- **项目路径**: `https://github.com/prtmax/psdk-examples/tree/main/android-native-java/inkjet-classic-buletooth-demo`
- **SDK 版本**: `compatible-external-inkjet-0.1.19-GA`
- **SDK 路径**: `psdk/java/compatible/external/inkjet`
- **编译 SDK**: 32
- **最低支持**: Android 5.0 (API 21)

---

## 工程结构

```
app/
├── build.gradle              # 应用构建配置
├── libs/
│   └── fat-compatible-external-inkjet-0.1.19-GA.jar   # PSDK 依赖
└── src/main/
    ├── AndroidManifest.xml
    ├── res/
    │   ├── layout/
    │   │   ├── activity_main.xml   # 主界面布局
    │   │   └── activity_scan.xml   # 蓝牙扫描界面布局
    │   └── raw/
    │       ├── caomei              # 示例图片
    │       └── v138885             # OTA 固件
    └── java/com/example/classic_bluetooth_demo/
        ├── ScanActivity.java       # 蓝牙扫描界面
        ├── MainActivity.java       # 主界面（打印/查询/升级）
        ├── Device.java             # 蓝牙设备封装
        ├── Config.java             # 打印机配置数据类
        └── ReadMark.java           # 操作类型枚举
```

---

## 功能列表

| 功能 | 按钮 | 对应 SDK 方法 | 说明 |
|------|------|--------------|------|
| 蓝牙扫描 | 扫描 | `Bluetooth.getInstance().startDiscovery()` | 扫描经典蓝牙设备 |
| 蓝牙连接 | 点击设备 | `Bluetooth.getInstance().createConnectionClassic()` | 经典蓝牙 SPP 连接 |
| 打印图片 | 打印 | `compatibleInkJet.page().cls().image().print()` | BITMAP 协议，最大宽度 1052px |
| **分包打印** | **分包打印** | `compatibleInkJet.imageSN()` | **BITMAP_SN 协议（新增）** |
| 取消打印 | 取消打印 | `compatibleInkJet.cancel()` | 需等数据发完后再等 2s |
| 打印机状态 | 打印机状态 | `compatibleInkJet.state()` | 主动/被动状态上报 |
| 电池电量 | 电池电量 | `compatibleInkJet.batteryVolume()` | 查询电量+充电状态 |
| 打印机信息 | 打印机所有信息 | `compatibleInkJet.info()` | 分辨率/固件版本/关机时间/提示音 |
| 墨盒信息 | 墨盒信息 | `compatibleInkJet.inkBoxInfo()` | 墨水量+墨盒唯一标识 |
| 设置关机时间 | 设置关机时间 | `compatibleInkJet.setShutdownTime()` | 永不/15min/30min/60min |
| 一键退纸 | 一键退纸 | `compatibleInkJet.ejectPaper()` | 退纸 |
| 清洁打印头 | 清洁打印头 | `compatibleInkJet.printerClean()` | 清洁 |
| OTA 升级 | 升级打印机 | `compatibleInkJet.ota()` | 固件升级 |

---

## 蓝牙连接流程

```
ScanActivity                          MainActivity
    │                                     │
    ├─ Bluetooth.getInstance()            │
    │   .initialize(getApplication())     │
    │                                     │
    ├─ startDiscovery()                   │
    │   └─ onDeviceFound() → 列表展示     │
    │                                     │
    ├─ 点击设备 ──────────────────────────►│
    │   intent.putExtra("device", device) │
    │                                     │
    │                          ├─ createConnectionClassic(device, listener)
    │                          │   └─ onConnectSuccess(ConnectedDevice)
    │                          │       └─ new CompatibleInkJet(lifecycle)
    │                          │       └─ dataListen(connectedDevice)
    │                          │
    │                          └─ onConnectionStateChanged()
    │                              └─ 更新 UI 连接状态
```

---

## 数据收发机制

### 发送
```java
CompatibleInkJet cmd = compatibleInkJet.xxx();  // 构建命令
WroteReporter reporter = cmd.write();            // 发送到设备
```

### 接收
通过 `DataListener` 监听设备回传数据：

- **0xFF 开头**: 打印机主动状态上报（5 字节）
- **0xFD 开头**: 打印进度上报（5 字节，进度值 0-100）
- **其他**: 查询响应（状态/电量/墨盒/配置/OTA 结果等）

---

## 打印机状态码

| 掩码 | 含义 |
|------|------|
| 0x00000001 | 开盖 |
| 0x00000002 | 卡纸 |
| 0x00000004 | 缺纸 |
| 0x00000008 | 缺墨 |
| 0x00000020 | 繁忙 |
| 0x00000040 | 低压 |
| 0x00000100 | 正在取消 |
| 0x00000200 | 数据异常 |
| 0x00000400 | 机电错误 |
| 0x00000800 | 纸道有纸 |
| 0x00001000 | 无墨盒 |
| 0x10000000 | 充电中 |
| 0x20000000 | 充电完成 |

---

## 新增：BITMAP_SN 分包打印（imageSN）

### 背景
普通 BITMAP 协议将整张图片一次性发送，大数据量时容易因蓝牙传输不稳定导致失败。BITMAP_SN 协议将图片拆分为多个小包逐个发送，每包携带序号和校验，支持接收端请求重发。

### 协议格式

每包结构（默认 512 字节）：
```
[2 字节: 包序号(大端)] [N 字节: 图像数据] [1 字节: 异或校验和]
```

发送流程：
1. 发送命令头 `BITMAP_SN x y w h quality mode totalSize totalPage packetSize`
2. 逐包发送数据
3. 发送 `\r\n` 结束

### 重发机制

打印机接收过程中对每包进行异或校验，校验失败时发送 `BITMAP_SN_RESEND <序号>` 指令。SDK 在 13 秒内收到重发请求后，从错误包开始补发之后所有包。

### 使用方法

```java
// 1. 准备图片（需压缩到 400KB 以内）
Bitmap rawBitmap = ...;
ByteArrayOutputStream baos = new ByteArrayOutputStream();
rawBitmap.compress(Bitmap.CompressFormat.JPEG, 90, baos);
byte[] compressed = compressImageForSN(baos.toByteArray());

// 2. 构建 IImageSN
AndroidSourceImage sourceImage = new AndroidSourceImage(
    BitmapFactory.decodeByteArray(compressed, 0, compressed.length)
);
activeSNImage = IImageSN.builder()
    .image(sourceImage)
    .mode(ImageMode.JPG)
    .build();

// 3. 发送
compatibleInkJet.imageSN(activeSNImage);

// 4. 在 DataListener 中转发回传数据以支持重发
activeSNImage.notifyResponse(received);
```

### 注意事项
- 图片数据需压缩到 **400KB 以内**
- 最大宽度 **1052px**
- 需在数据监听回调中调用 `activeSNImage.notifyResponse(received)` 以支持重发
- 打印成功时设备返回 `AA`

---

## 编译运行

```bash
# Windows
gradlew assembleDebug

# 输出 apk 路径
# app/build/outputs/apk/debug/app-debug.apk
```

使用 Android Studio 打开项目根目录即可直接编译运行。签名文件 `inkjet.jks` 已包含在项目中。
