# 变更记录 (CHANGELOG)

## (2026-07-08)

### 修复

- **OTA 升级卡死（ANR）**
  - 固件文件读取 (`readResources`) 和蓝牙写入 (`safeWrite`) 原在主线程执行，大固件文件导致 UI 阻塞卡死
  - 改为后台线程执行，与「打印」按钮处理方式保持一致

### 新增

- **固件文件选择器**
  - 「升级打印机」不再硬编码 `res/raw/v138885.RM`，改为弹出系统文件选择器 (`ACTION_OPEN_DOCUMENT`)
  - 支持从手机任意目录选取 `.RM` / `.bin` 等固件文件
  - 新增 `readBytesFromUri()` 方法，通过 `ContentResolver` 读取选中文件

- **一键关机按钮**
  - 新增「一键关机」按钮，调用 `compatibleInkJet.powerOff()` 远程关闭打印机
  - 后台线程执行，不阻塞 UI

- **极低电量状态识别**
  - `STATUS_MASKS` 映射表新增 `0x40000000 → "极低电量"`
  - `mapStatusToString()` 同步新增对应判断分支
  - 主动查询和主动上报两条路径均已覆盖

### Demo 变更

| 文件 | 变更内容 |
|------|---------|
| `MainActivity.java` | 新增 `powerOffButton` 字段及一键关机逻辑；OTA 升级改为后台线程 + 文件选择器；新增 `onActivityResult()`、`readBytesFromUri()` 方法；`STATUS_MASKS` 和 `mapStatusToString()` 新增极低电量；
| `activity_main.xml` | 新增「一键关机」按钮行；

---

## v0.1.19-GA (2026-06)

### 新增

- **imageSN（BITMAP_SN 分包打印协议）**
  - SDK 新增 `IImageSN` 类，支持将图片拆分为多个小包发送，每包带序号和异或校验
  - SDK 新增 `CompatibleInkJet.imageSN()` 方法
  - Demo 新增「分包打印」按钮，演示 BITMAP_SN 协议完整使用流程
  - 支持打印机端校验失败时自动请求重发（`BITMAP_SN_RESEND`）
  - 每包默认 512 字节（2 字节序号 + 509 字节数据 + 1 字节校验）

### Demo 变更

| 文件 | 变更内容 |
|------|---------|
| `MainActivity.java` | 新增 `activeSNImage` 字段；新增分包打印按钮点击逻辑（图片加载→压缩→构建 IImageSN→发送）；新增 `compressImageForSN()` 图片压缩方法；DataListener 中新增 `notifyResponse` 转发 |
| `ReadMark.java` | 新增 `OPERATE_PRINT_SN` 枚举值，用于标识 BITMAP_SN 打印操作 |
| `activity_main.xml` | 新增「分包打印」按钮和「取消打印」按钮 |
| `app/build.gradle` | SDK 依赖更新为 `fat-compatible-external-inkjet-0.1.19-GA.jar` |

### SDK 接口说明

```java
// 构建 BITMAP_SN 图片参数
IImageSN<?> imageSN = IImageSN.builder()
    .image(sourceImage)       // 图片数据
    .mode(ImageMode.JPG)      // 图片模式
    .x(0)                     // 起始 x 坐标（可选，默认 0）
    .y(0)                     // 起始 y 坐标（可选，默认 0）
    .pageSize(509)            // 每包数据字节数（可选，默认 509）
    .quality(ImageQuality.FAST) // 图片质量（可选，默认 FAST）
    .build();

// 发送
compatibleInkJet.imageSN(imageSN);
// 或指定包间延迟
compatibleInkJet.imageSN(imageSN, interPacketDelayMs);

// 接收回传数据时转发（支持重发）
imageSN.notifyResponse(receivedBytes);
```

### 注意事项

1. 图片数据需压缩到 400KB 以内，否则可能因数据量过大导致传输失败
2. 图片最大宽度 1052px
3. 必须在设备数据监听回调中调用 `notifyResponse()` 以支持分包重发
4. 打印成功时设备返回 `AA`

---

## 历史版本

### v0.1.18 及之前

- 蓝牙扫描与连接
- BITMAP 协议普通打印
- 打印机状态查询（主动/被动）
- 电池电量查询
- 打印机配置查询（分辨率/固件版本/关机时间/提示音）
- 墨盒信息查询
- 定时关机设置
- 一键退纸
- 清洁打印头
- OTA 固件升级
