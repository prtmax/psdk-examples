# PSDK Android 打印接入文档

> 适用项目：`generic-android-demo`  
> SDK：`fat-generic-super-fat-sdk-0.1.18-GA.jar`  
> 目标：让客户在自己的 Android App 中完成打印机连接、打印、状态读取和资源释放。

## 1. 先看结论：客户只需要完成 5 步

1. 将 SDK JAR 放到 `app/libs/`，在 `app/build.gradle` 引入。
2. 在 `AndroidManifest.xml` 声明蓝牙、网络、相机（如使用扫码）和 USB 相关权限。
3. App 启动时调用一次 `Bluetooth.getInstance().initialize(getApplication())`（仅蓝牙场景）。
4. 建立连接，连接成功后用 `PrintUtil` 初始化打印协议对象。
5. 用 TSPL、CPCL 或 ESC 构造指令，调用 `.write()`，页面销毁时断开连接/注销 USB。

最小调用链如下：

```text
连接成功 -> ConnectedDevice
         -> PrintUtil.getInstance().init(connectedDevice)
         -> PrintUtil.getInstance().tspl()/cpcl()/esc()
         -> 构造指令
         -> psdk.write()
         -> WroteReporter.isOk()
```

## 2. 能力与连接方式

| 场景 | 连接 API | 适用协议 | 关键说明 |
| --- | --- | --- | --- |
| 经典蓝牙打印（SPP） | `Bluetooth.getInstance().createConnectionClassic(...)` | TSPL / CPCL / ESC / ZPL 原始指令 | 设备必须是 Classic 蓝牙，不是 BLE |
| BLE 配网 | `Bluetooth.getInstance().createConnectionBle(...)` | `WIFI.generic(...)` 或 `ESC.generic(...)` | 用于下发 Wi-Fi 名称、密码、IP 等配置 |
| 网络打印 | `Network.getInstance().connect(ip, 9100)` | TSPL / CPCL / ESC / 原始指令 | 手机与打印机在同一网络；默认端口 9100 |
| USB 打印 | `new USB(context, handler)` + `openUsb()` | TSPL / CPCL / ESC | 需 USB OTG、系统 USB 授权和匹配的 VID/PID |

当前 Demo 的入口页面是 `ScanActivity`：

- “打印设备（SPP）”筛选 Classic 蓝牙，进入 TSPL、CPCL、ESC 或 ZPL 示例。
- “配网设备（BLE）”筛选 BLE，进入 TSPL 配网或 ESC 配网示例。
- 另有 USB 和 NET 入口。

## 3. 环境与依赖

### 3.1 项目要求

本 Demo 的构建配置如下，客户项目可以使用更高版本，但建议先按此组合验证：

- `compileSdk 32`
- `minSdk 21`
- `targetSdk 32`
- Java 8
- Android Gradle Plugin `7.0.4`
- Gradle Wrapper `7.5`

### 3.2 引入 SDK

将以下文件复制到客户项目的 `app/libs/`：

```text
app/libs/fat-generic-super-fat-sdk-0.1.18-GA.jar
```

在 `app/build.gradle` 的 `dependencies` 增加：

```gradle
implementation files('libs/fat-generic-super-fat-sdk-0.1.18-GA.jar')
```

Demo 还带有 `pdf.jar`，仅当客户需要 PDF 转图片/打印功能时才需要：

```gradle
implementation files('libs/pdf.jar')
```

图片打印需要把图片转成 SDK 的 `AndroidSourceImage`：

```java
import com.printer.psdk.imagep.android.AndroidSourceImage;
```

## 4. Manifest 权限

按客户实际能力选择权限。下面是本 Demo 的完整声明，可直接参考：

如果使用 `tools:targetApi`，请确保 `<manifest>` 根节点同时包含 `xmlns:tools="http://schemas.android.com/tools"`。

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
    xmlns:tools="http://schemas.android.com/tools">
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.ACCESS_WIFI_STATE" />

<!-- 扫码功能才需要 -->
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.VIBRATE" />

<!-- Android 11 及以下蓝牙搜索通常需要定位权限 -->
<uses-permission android:name="android.permission.BLUETOOTH" />
<uses-permission android:name="android.permission.BLUETOOTH_ADMIN" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_LOCATION_EXTRA_COMMANDS" />

<!-- Android 12（API 31）及以上 -->
<uses-permission
    android:name="android.permission.BLUETOOTH_SCAN"
    android:usesPermissionFlags="neverForLocation"
    tools:targetApi="s" />
<uses-permission android:name="android.permission.BLUETOOTH_CONNECT" />

<!-- USB 设备匹配由 res/xml/device_filter.xml 配置 -->
</manifest>
```

注意：声明权限不等于获得权限。Android 6+ 必须运行时申请定位权限；Android 12+ 必须运行时申请 `BLUETOOTH_SCAN`、`BLUETOOTH_CONNECT`。用户拒绝权限时，不要继续扫描或连接，应提示用户到系统设置开启。

`BLUETOOTH_PRIVILEGED` 属于系统/特权权限，普通三方 App 不应依赖它；客户项目按上面的公开权限申请即可。

## 5. 蓝牙 SPP 打印（最常用）

### 5.1 初始化蓝牙 SDK

在 `Application.onCreate()` 或首个蓝牙页面的 `onCreate()` 中调用一次：

```java
import com.printer.psdk.device.bluetooth.Bluetooth;

Bluetooth.getInstance().initialize(getApplication());
```

如果需要扫描设备：

```java
Bluetooth bluetooth = Bluetooth.getInstance();
bluetooth.setDiscoveryListener(new DiscoveryListen() {
  @Override public void onDiscoveryStart() {}
  @Override public void onDiscoveryStop() {}
  @Override public void onDiscoveryError(int errorCode, String errorMsg) {}
  @Override public void onDeviceFound(BluetoothDevice device, int rssi) {
    // 保存 device；连接时传入该对象
  }
});
bluetooth.startDiscovery();
```

扫描前请确认：蓝牙已开启、运行时权限已授予、位置服务（Android 11 及以下）已开启。扫描结束或页面暂停时调用 `stopDiscovery()`。

### 5.2 建立 Classic 连接

连接操作放到后台线程；所有 UI 更新切回主线程：

```java
private Connection connection;

private void connectClassic(BluetoothDevice device) {
  connection = Bluetooth.getInstance().createConnectionClassic(device, new ConnectListener() {
    @Override
    public void onConnectSuccess(ConnectedDevice connectedDevice) {
      // 连接成功后才能创建 TSPL/CPCL/ESC 指令
      PrintUtil.getInstance().init(connectedDevice);
      startReceiveListener(connectedDevice); // 如果需要状态/回传数据
    }

    @Override
    public void onConnectFail(String errMsg, Throwable e) {
      Log.e("PSDK", "连接失败：" + errMsg, e);
    }

    @Override
    public void onConnectionStateChanged(BluetoothDevice device, int state) {
      // Connection.STATE_CONNECTING / STATE_PAIRING / STATE_PAIRED /
      // STATE_CONNECTED / STATE_DISCONNECTED / STATE_RELEASED
    }
  });

  if (connection == null) {
    Log.e("PSDK", "创建连接失败");
    return;
  }

  new Thread(() -> connection.connect(null)).start();
}
```

`createConnectionClassic` 的参数类型是 `BluetoothDevice`，不能直接把设备名称或 MAC 字符串传给 SDK；如果业务侧只有 MAC 地址，可以先通过系统 API 转换为 `BluetoothDevice` 再连接。

```java
import android.bluetooth.BluetoothAdapter;
import android.bluetooth.BluetoothDevice;

private void connectByMac(String mac) {
  try {
    // mac 示例："AA:BB:CC:DD:EE:FF"
    BluetoothDevice device = BluetoothAdapter.getDefaultAdapter().getRemoteDevice(mac);
    connectClassic(device); // 复用上面的连接方法
  } catch (IllegalArgumentException e) {
    Log.e("PSDK", "MAC 地址格式错误：" + mac, e);
  }
}
```

`getRemoteDevice(mac)` 只负责创建 Android 设备对象，不代表打印机一定在线或已配对；最终连接结果仍以 `onConnectSuccess` / `onConnectFail` 为准。Android 12 及以上请先申请 `BLUETOOTH_CONNECT`，并在连接前确认蓝牙已开启。

### 5.3 发送 TSPL 打印

Demo 中 TSPL 页面和坐标单位如下：页面宽高是 mm，文字/图形坐标是 dot；203 dpi 时通常 `1 mm = 8 dot`，300 dpi 时通常 `1 mm = 12 dot`，请按打印机分辨率适配。

```java
import com.printer.psdk.device.adapter.types.WroteReporter;
import com.printer.psdk.tspl.GenericTSPL;
import com.printer.psdk.tspl.args.TDirection;
import com.printer.psdk.tspl.args.TPage;
import com.printer.psdk.tspl.args.TText;

private boolean printText(String text) {
  try {
    GenericTSPL tspl = PrintUtil.getInstance().tspl()
        .clear()
        .page(TPage.builder().width(100).height(100).build())
        .direction(TDirection.builder()
            .direction(TDirection.Direction.UP_OUT)
            .mirror(TDirection.Mirror.NO_MIRROR)
            .build())
        .cls()
        .text(TText.builder().x(50).y(50).content(text).build())
        .cut(true)
        .print(1);

    WroteReporter reporter = tspl.write();
    if (!reporter.isOk()) {
      Log.e("PSDK", "打印发送失败", reporter.getException());
    }
    return reporter.isOk();
  } catch (Exception e) {
    Log.e("PSDK", "打印异常", e);
    return false;
  }
}
```

常用 TSPL 元素：

```java
GenericTSPL tspl = PrintUtil.getInstance().tspl()
    .clear()
    .page(TPage.builder().width(100).height(150).build())
    .text(TText.builder().x(30).y(40).content("订单号：A0001").build())
    .barcode(TBarCode.builder().x(30).y(100).height(60).content("A0001").build())
    .qrcode(TQRCode.builder().x(500).y(100).cellWidth(4).content("https://example.com").build())
    .print(1);
WroteReporter reporter = tspl.write();
```

图片打印：

```java
Bitmap bitmap = BitmapFactory.decodeResource(getResources(), R.drawable.logo);
GenericTSPL tspl = PrintUtil.getInstance().tspl()
    .clear()
    .page(TPage.builder().width(100).height(100).build())
    .cls()
    .image(TImage.builder()
        .x(0).y(0)
        .image(new AndroidSourceImage(bitmap))
        .compress(true)
        .build())
    .print(1);
tspl.write();
```

### 5.4 CPCL、ESC 和 ZPL

连接和 `write()` 流程完全相同，只需替换协议对象：

```java
// CPCL：单位为 dot；完整指令需要 page() + print()
GenericCPCL cpcl = PrintUtil.getInstance().cpcl()
    .page(CPage.builder().width(608).height(800).copies(1).build())
    .text(CText.builder().textX(20).textY(30).content("Hello CPCL").build())
    .print(CPrint.builder().build());
cpcl.write();

// ESC：按 ESC 打印机能力组合指令
GenericESC esc = PrintUtil.getInstance().esc()
    .enable()
    .image(EImage.builder().image(new AndroidSourceImage(bitmap)).compress(true).build())
    .lineDot(250)
    .stopJob();
esc.write();
```

如果客户已有完整 ZPL/ESC/TSPL 字节流，可使用原始指令：

```java
byte[] raw = "^XA^FO40,40^FDHello ZPL^FS^XZ".getBytes(StandardCharsets.US_ASCII);
WroteReporter reporter = PrintUtil.getInstance().tspl()
    .raw(Raw.builder().command(raw).build())
    .write();
```

原始指令必须与打印机当前固件协议一致；协议不匹配时 SDK 只能报告发送结果，不能保证打印机识别内容。

## 6. 接收状态和打印机回传

连接成功后，用 `DataListener` 启动接收监听。监听回调不保证在主线程执行，更新界面时请使用 `runOnUiThread`：

```java
private DataListenerRunner listenerRunner;

private void startReceiveListener(ConnectedDevice device) {
  listenerRunner = DataListener.with(device)
      .listen(new ListenAction() {
        @Override
        public void action(byte[] bytes) {
          if (bytes == null || bytes.length == 0) return;
          Log.d("PSDK", "收到：" + Util.ByteArrToHex(bytes));
          // 根据当前请求解析 bytes，例如 Util.parseTsplStatus(bytes)
        }
      })
      .start();
}
```

典型查询：

```java
// TSPL
PrintUtil.getInstance().tspl().clear().status().write();

// CPCL
PrintUtil.getInstance().cpcl().status().write();

// ESC
PrintUtil.getInstance().esc().state().write();
```

Demo 已提供状态解析方法，可直接复用：

- `Util.parseTsplStatus(byte[])`
- `Util.parseCpclStatus(byte[])`
- `Util.parseEscStatus(byte[])`

USB/网络场景也可以主动读取：

```java
WroteReporter reporter = psdk.write();
if (reporter.isOk()) {
  byte[] response = psdk.read(ReadOptions.builder().timeout(2000).build());
}
```

## 7. 网络打印（NET）

网络连接必须放到后台线程。默认端口是 `9100`，Demo 的 `NETActivity` 也会通过 UDP 搜索打印机：

```java
private final Network network = Network.getInstance();

private void connectNetwork(String ip) {
  new Thread(() -> {
    NetConnectedDevice device = network.connect(ip, 9100);
    runOnUiThread(() -> {
      if (device != null) {
        PrintUtil.getInstance().init(device);
        // 现在可以调用 tspl()/cpcl()/esc()
      }
    });
  }).start();
}
```

可选的 UDP 搜索：

```java
network.setOnPrinterFoundListener(info -> {
  // info.getId() 为可连接的 IP 标识；info.toString() 可用于展示
});
network.setOnScanningChangeListener(scanning -> { /* 更新搜索按钮 */ });
network.startPrinterDiscovery();
// 结束搜索：network.stopPrinterDiscovery();
```

页面销毁时释放：

```java
network.stopPrinterDiscovery();
network.close();
```

## 8. USB 打印

### 8.1 USB 过滤器

在 `app/src/main/res/xml/device_filter.xml` 配置打印机的 VID/PID。Demo 当前示例是：

```xml
<resources>
    <usb-device vendor-id="2501" product-id="1416" />
</resources>
```

客户必须把它替换成自己打印机实际的 VID/PID；否则系统不会把设备分发给 App。

### 8.2 打开、打印和关闭

```java
private USB usb;
private USBConnectedDevice usbDevice;

private void openUsb() {
  usb = new USB(this, new Handler(Looper.getMainLooper()) {
    @Override public void handleMessage(Message msg) {
      // USB.OPEN / CLOSE / ATTACHED / DETACHED
    }
  });
  usb.register_USB();

  new Thread(() -> {
    usbDevice = usb.openUsb();
    if (usbDevice != null) {
      runOnUiThread(() -> PrintUtil.getInstance().init(usbDevice));
    }
  }).start();
}

private void closeUsb() {
  if (usb != null) {
    usb.closeUsb();
    usb.unregister_USB();
  }
}
```

首次连接时系统可能弹出 USB 授权框，用户必须允许。USB 打印同样使用 `PrintUtil.getInstance().tspl()/cpcl()/esc()`。

## 9. BLE 配网

BLE 不是打印数据链路，主要用于把打印机配置到 Wi-Fi。连接方式：

```java
Connection connection = Bluetooth.getInstance().createConnectionBle(device, new ConnectListener() {
  @Override public void onConnectSuccess(ConnectedDevice connectedDevice) {
    GenericWIFI wifi = WIFI.generic(connectedDevice);
    wifi.setSSID(WSetSSID.builder()
        .name("WiFi名称")
        .password("WiFi密码")
        .build())
        .write();
  }
  @Override public void onConnectFail(String errMsg, Throwable e) {}
  @Override public void onConnectionStateChanged(BluetoothDevice device, int state) {}
});
new Thread(() -> connection.connect(null)).start();
```

Demo 已实现的配网能力包括：读取/设置 SSID 和密码、查询连接状态、DHCP/静态 IP、设置 Wi-Fi 角色等，参考 `WIFIActivity.java`。ESC 配网参考 `ESCWIFIActivity.java`。

## 10. 生命周期与线程要求（必须遵守）

- `connect()`、`Network.connect()`、`USB.openUsb()`、大量数据的 `write()` 不要阻塞主线程。
- 只有在 `onConnectSuccess` 或 USB/网络连接成功后，才可调用 `PrintUtil.init(...)` 和打印方法。
- 蓝牙页面销毁时调用 `connection.disconnect()`；如自行创建了监听器，先 `listenerRunner.stop()`。
- 网络页面销毁时调用 `stopPrinterDiscovery()`、`close()`。
- USB 页面销毁时调用 `closeUsb()`、`unregister_USB()`。
- 不要多个页面同时复用同一条连接并交叉发送；建议由一个连接管理器串行发送。
- `WroteReporter.isOk()` 只表示数据是否成功写入连接，不等于打印机已经完成出纸；需要打印结果时，结合状态查询或回传监听。

## 11. 常见问题排查

| 现象 | 优先检查 |
| --- | --- |
| 扫描不到 Classic 设备 | 蓝牙是否开启；是否申请定位/蓝牙扫描权限；位置服务是否开启；当前入口是否误选 BLE |
| Android 12 连接失败 | 是否运行时申请 `BLUETOOTH_SCAN`、`BLUETOOTH_CONNECT`；Manifest 是否声明 |
| `connection == null` | 设备对象是否为空；设备类型是否与 Classic/BLE API 匹配 |
| 已连接但打印失败 | 是否在 `onConnectSuccess` 中调用 `PrintUtil.init`；是否在后台线程发送；检查 `WroteReporter.getException()` |
| 打印内容乱码 | 协议、字体和字符集是否匹配；TSPL/CPCL 的坐标和 DPI 是否正确 |
| 图片打印空白/过大 | 检查图片尺寸、`compress(true)`、打印机分辨率和纸张尺寸 |
| 网络连接失败 | 手机与打印机是否同网段；IP 是否正确；端口是否为 9100；是否被防火墙拦截 |
| USB 无设备 | VID/PID 是否正确；是否插入 OTG；是否允许系统 USB 授权 |
| 状态读取不到 | 是否先发送 `status()/state()`；是否启动 `DataListener` 或调用 `read(timeout)`；打印机是否支持该查询 |

## 12. 联调验收清单

- [ ] 能扫描/发现目标打印机并显示设备名称、地址。
- [ ] 连接回调进入 `onConnectSuccess`，并完成 `PrintUtil.init`。
- [ ] 打印一张纯文本标签。
- [ ] 打印一张图片或二维码/条码。
- [ ] 调用一次 `status()`/`state()` 并能解析返回值。
- [ ] 断开页面后再次进入，连接可以重新建立。
- [ ] 网络场景确认 9100 端口可用；USB 场景确认授权框和 VID/PID。
- [ ] Android 6、Android 12 及以上设备分别验证权限流程。

## 13. Demo 代码索引

| 文件 | 用途 |
| --- | --- |
| `app/src/main/java/com/example/classic_bluetooth_demo/ScanActivity.java` | 蓝牙初始化、扫描、设备类型过滤、入口跳转 |
| `app/src/main/java/com/example/classic_bluetooth_demo/TSPLActivity.java` | TSPL 文本、图片、条码、二维码、状态、升级示例 |
| `app/src/main/java/com/example/classic_bluetooth_demo/CPCLActivity.java` | CPCL 文本、图片、条码、二维码、状态示例 |
| `app/src/main/java/com/example/classic_bluetooth_demo/ESCActivity.java` | ESC 打印、状态、设备信息和更多打印机能力 |
| `app/src/main/java/com/example/classic_bluetooth_demo/WIFIActivity.java` | BLE 配置 Wi-Fi |
| `app/src/main/java/com/example/classic_bluetooth_demo/ESCWIFIActivity.java` | ESC BLE 配网 |
| `app/src/main/java/com/example/classic_bluetooth_demo/NETActivity.java` | UDP 搜索、IP/端口连接、网络打印 |
| `app/src/main/java/com/example/classic_bluetooth_demo/USBActivity.java` | USB 授权、打开/关闭、打印和状态读取 |
| `app/src/main/java/com/example/classic_bluetooth_demo/util/PrintUtil.java` | 统一保存 `ConnectedDevice` 和 TSPL/CPCL/ESC 对象 |
| `app/src/main/java/com/example/classic_bluetooth_demo/util/Util.java` | 状态解析、十六进制转换、资源读取 |
| `app/src/main/res/xml/device_filter.xml` | USB VID/PID 过滤配置 |
