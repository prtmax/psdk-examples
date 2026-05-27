package com.printer.psdk.examples.emapi;

import android.bluetooth.BluetoothAdapter;
import android.bluetooth.BluetoothDevice;
import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.content.IntentFilter;
import android.os.Handler;
import android.os.Looper;

import com.printer.psdk.emapi.EmapiBluetoothConnectionReport;
import com.printer.psdk.emapi.EmapiCommand;
import com.printer.psdk.emapi.EmapiFlowControlReport;
import com.printer.psdk.emapi.EmapiPayload;
import com.printer.psdk.emapi.EmapiPrintResultReport;
import com.printer.psdk.emapi.EmapiPrintStatus;
import com.printer.psdk.emapi.EmapiPrinter;
import com.printer.psdk.emapi.EmapiPrinterInfo;
import com.printer.psdk.emapi.EmapiPrinterStatusReport;
import com.printer.psdk.emapi.EmapiReport;
import com.printer.psdk.emapi.EmapiRfidAuthFailurePolicy;
import com.printer.psdk.emapi.EmapiRfidCardInfo;
import com.printer.psdk.emapi.EmapiUnknownReport;
import com.printer.psdk.emapi.EmapiUpgradeStatusReport;
import com.printer.psdk.emapi.EmapiWifiConfigStatusReport;
import com.printer.psdk.emapi.EmapiWifiConnectionState;
import com.printer.psdk.emapi.EmapiWifiHotspotInfo;
import com.printer.psdk.emapi.protocol.EmapiConstants;
import com.printer.psdk.emapi.protocol.FrameCodec;
import com.printer.psdk.emapi.protocol.Tlv;

import java.io.File;
import java.io.FileInputStream;
import java.io.IOException;
import java.util.ArrayList;
import java.util.List;
import java.util.Set;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;

final class EmapiDemoController {
    interface Listener {
        void onChanged();
    }

    final List<DeviceModel> devices = new ArrayList<DeviceModel>();
    final List<LogEntry> requestLogs = new ArrayList<LogEntry>();
    final List<LogEntry> commandLogs = new ArrayList<LogEntry>();
    final List<LogEntry> reportLogs = new ArrayList<LogEntry>();

    boolean bluetoothEnabled;
    boolean scanning;
    boolean connecting;
    boolean connected;
    boolean simulationMode;
    String connectedDeviceName;
    String pendingActionLabel;
    int knownMtu = 512;
    int transferSentBytes;
    int transferTotalBytes;
    String latestTransferStatus;

    private final Handler mainHandler = new Handler(Looper.getMainLooper());
    private final ExecutorService executor = Executors.newFixedThreadPool(2);
    private final Listener listener;
    private BluetoothAdapter bluetoothAdapter;
    private BroadcastReceiver scanReceiver;
    private TracingEmapiConnection tracingConnection;
    private EmapiPrinter printer;
    private volatile boolean reportLoopRunning;

    EmapiDemoController(Listener listener) {
        this.listener = listener;
    }

    boolean busy() {
        return connecting || pendingActionLabel != null;
    }

    String transferProgress() {
        if (transferTotalBytes <= 0) {
            return latestTransferStatus == null ? "未开始" : latestTransferStatus;
        }
        String status = latestTransferStatus == null ? "" : latestTransferStatus + "\n";
        return status + transferSentBytes + " / " + transferTotalBytes + " bytes";
    }

    void init(Context context) {
        bluetoothAdapter = BluetoothAdapter.getDefaultAdapter();
        bluetoothEnabled = bluetoothAdapter != null && bluetoothAdapter.isEnabled();
        notifyChanged();
    }

    void startScan(final Context context) {
        if (simulationMode) {
            devices.clear();
            devices.add(new DeviceModel("EMAPI 模拟打印机", "SIM-00-00-EMAPI", "Bluetooth Classic", true));
            scanning = false;
            bluetoothEnabled = true;
            addCommandLog("模拟模式：已生成 1 台模拟蓝牙设备");
            notifyChanged();
            return;
        }
        devices.clear();
        bluetoothAdapter = BluetoothAdapter.getDefaultAdapter();
        bluetoothEnabled = bluetoothAdapter != null && bluetoothAdapter.isEnabled();
        if (bluetoothAdapter == null || !bluetoothEnabled) {
            addCommandLog("蓝牙不可用或未开启");
            notifyChanged();
            return;
        }
        addBondedDevices();
        registerScanReceiver(context.getApplicationContext());
        scanning = true;
        try {
            bluetoothAdapter.startDiscovery();
            addCommandLog("开始扫描蓝牙设备");
        } catch (SecurityException error) {
            scanning = false;
            addCommandLog("扫描失败：" + error.getMessage());
        }
        notifyChanged();
    }

    void stopScan(Context context) {
        if (bluetoothAdapter != null) {
            try {
                bluetoothAdapter.cancelDiscovery();
            } catch (SecurityException ignored) {
            }
        }
        unregisterScanReceiver(context.getApplicationContext());
        scanning = false;
        addCommandLog(simulationMode ? "模拟模式：扫描已停止" : "已停止扫描");
        notifyChanged();
    }

    void connect(final DeviceModel device) {
        if (busy()) {
            return;
        }
        connecting = true;
        notifyChanged();
        executor.execute(new Runnable() {
            @Override
            public void run() {
                try {
                    if (simulationMode || device.simulated) {
                        emitSimulatedReport(new EmapiBluetoothConnectionReport(reportCommand(EmapiConstants.CHILD_REPORT_BLUETOOTH_CONNECTION), 1));
                    } else {
                        BluetoothDevice bluetoothDevice = bluetoothAdapter.getRemoteDevice(device.address);
                        tracingConnection = new TracingEmapiConnection(new BluetoothEmapiConnection(bluetoothDevice));
                        printer = EmapiPrinter.builder().connection(tracingConnection).fallbackMtu(512).build();
                        startReportLoop();
                    }
                    connected = true;
                    connectedDeviceName = device.name;
                    addCommandLog("已连接：" + device.name);
                } catch (Exception error) {
                    addCommandLog("连接失败：" + formatError(error));
                } finally {
                    connecting = false;
                    scanning = false;
                    notifyChanged();
                }
            }
        });
    }

    void disconnect() {
        reportLoopRunning = false;
        try {
            if (printer != null) {
                printer.close();
            }
        } catch (Exception ignored) {
        }
        tracingConnection = null;
        printer = null;
        connected = false;
        connectedDeviceName = null;
        latestTransferStatus = null;
        addCommandLog("已断开连接");
        notifyChanged();
    }

    void setSimulationMode(boolean enabled) {
        if (simulationMode == enabled) {
            return;
        }
        if (connected) {
            disconnect();
        }
        simulationMode = enabled;
        devices.clear();
        scanning = false;
        if (enabled) {
            bluetoothEnabled = true;
        } else {
            bluetoothEnabled = bluetoothAdapter != null && bluetoothAdapter.isEnabled();
        }
        addCommandLog(enabled ? "已开启模拟模式" : "已关闭模拟模式");
        notifyChanged();
    }

    void sleepShutdown() {
        runPrinterAction("打印机休眠关机", request(EmapiConstants.PARENT_SYSTEM, EmapiConstants.CHILD_SYSTEM_SLEEP_SHUTDOWN), new PrinterCallable() {
            @Override
            public String call() throws Exception {
                if (simulationMode) {
                    emitSimulatedReport(new EmapiFlowControlReport(reportCommand(EmapiConstants.CHILD_REPORT_FLOW_CONTROL), 0));
                    return "模拟模式：休眠关机指令已接收";
                }
                requirePrinter().sleepShutdown();
                return "打印机休眠关机：已发送";
            }
        });
    }

    void printSelfTestPage() {
        runPrinterAction("打印自检页", request(EmapiConstants.PARENT_PRINTER, EmapiConstants.CHILD_PRINTER_SELF_TEST_PAGE), new PrinterCallable() {
            @Override
            public String call() throws Exception {
                if (!simulationMode) {
                    requirePrinter().printSelfTestPage();
                }
                return (simulationMode ? "模拟模式：" : "") + "自检页打印指令已接收";
            }
        });
    }

    void setShutdownTime(final int minutes) {
        runPrinterAction("设置关机时间", new EmapiCommand(EmapiConstants.TYPE_REQUEST, EmapiConstants.PARENT_SYSTEM, EmapiConstants.CHILD_SYSTEM_SET_SHUTDOWN_TIME, EmapiPayload.uint16(minutes)), new PrinterCallable() {
            @Override
            public String call() throws Exception {
                if (!simulationMode) {
                    requirePrinter().setShutdownTime(minutes);
                }
                return (simulationMode ? "模拟模式：" : "") + "关机时间已设置为 " + minutes + " 分钟";
            }
        });
    }

    void queryRfidUid() {
        runPrinterAction("查询 RFID 卡 UID", request(EmapiConstants.PARENT_RFID, EmapiConstants.CHILD_RFID_UID), new PrinterCallable() {
            @Override
            public String call() throws Exception {
                return simulationMode ? "RFID 卡 UID：04AABBCCDDEE" : "RFID 卡 UID：" + requirePrinter().queryRfidUid();
            }
        });
    }

    void queryRfidCardInfo() {
        runPrinterAction("查询 RFID 卡信息", request(EmapiConstants.PARENT_RFID, EmapiConstants.CHILD_RFID_CARD_INFO), new PrinterCallable() {
            @Override
            public String call() throws Exception {
                EmapiRfidCardInfo info = simulationMode
                    ? new EmapiRfidCardInfo("SIM-L801", "40m", "80mm", "white", "SIM-PAPER-01")
                    : requirePrinter().queryRfidCardInfo();
                return formatRfidCardInfo(info);
            }
        });
    }

    void queryRfidPaperLength() {
        runPrinterAction("查询卡内纸张长度", request(EmapiConstants.PARENT_RFID, EmapiConstants.CHILD_RFID_PAPER_LENGTH), new PrinterCallable() {
            @Override
            public String call() throws Exception {
                long length = simulationMode ? 123456L : requirePrinter().queryRfidPaperLength();
                return "卡内纸张长度：" + length;
            }
        });
    }

    void setRfidAuthFailureHandling() {
        runPrinterAction("设置 RFID 认证失败处理", new EmapiCommand(EmapiConstants.TYPE_REQUEST, EmapiConstants.PARENT_RFID, EmapiConstants.CHILD_RFID_AUTH_FAILURE_HANDLING, EmapiPayload.uint8(1)), new PrinterCallable() {
            @Override
            public String call() throws Exception {
                if (!simulationMode) {
                    requirePrinter().setRfidAuthFailureHandling(EmapiRfidAuthFailurePolicy.FORBID_PRINT);
                }
                return (simulationMode ? "模拟模式：" : "") + "RFID 认证失败处理：禁止打印";
            }
        });
    }

    void setWifiConfig(final String ssid, final String password) {
        runPrinterAction("设置配网信息", null, new PrinterCallable() {
            @Override
            public String call() throws Exception {
                if (simulationMode) {
                    emitSimulatedReport(new EmapiWifiConfigStatusReport(new EmapiCommand(EmapiConstants.TYPE_PASSTHROUGH_REQUEST, EmapiConstants.PARENT_WIFI, EmapiConstants.CHILD_WIFI_CONFIG_STATUS, new byte[0]), ssid.length() == 0 ? "SIM_WIFI" : ssid, 1));
                } else {
                    requirePrinter().setWifiConfig(ssid, password);
                }
                return (simulationMode ? "模拟模式：" : "") + "配网信息已发送：SSID=" + (ssid.length() == 0 ? "SIM_WIFI" : ssid);
            }
        });
    }

    void queryWifiConnectionState() {
        runPrinterAction("查询 WIFI 模块连接状态", passthrough(EmapiConstants.CHILD_WIFI_CONNECTION_STATE), new PrinterCallable() {
            @Override
            public String call() throws Exception {
                EmapiWifiConnectionState state = simulationMode ? EmapiWifiConnectionState.IOT_CONNECTED : requirePrinter().queryWifiConnectionState();
                return "WIFI 状态：" + state;
            }
        });
    }

    void queryWifiHotspotInfo() {
        runPrinterAction("查询 WIFI 模块热点相关信息", passthrough(EmapiConstants.CHILD_WIFI_HOTSPOT_INFO), new PrinterCallable() {
            @Override
            public String call() throws Exception {
                EmapiWifiHotspotInfo info = simulationMode
                    ? new EmapiWifiHotspotInfo("SIM_AP", -42, "192.168.4.1", "9100")
                    : requirePrinter().queryWifiHotspotInfo();
                return "热点 SSID：" + value(info.getSsid()) + "\nRSSI：" + value(info.getRssi()) + "\nIP：" + value(info.getIp()) + "\nPort：" + value(info.getPort());
            }
        });
    }

    void queryDeviceInfo() {
        runPrinterAction("查询打印机基本参数", request(EmapiConstants.PARENT_SYSTEM, EmapiConstants.CHILD_SYSTEM_DEVICE_INFO), new PrinterCallable() {
            @Override
            public String call() throws Exception {
                EmapiPrinterInfo info = simulationMode
                    ? new EmapiPrinterInfo("simulator", "EMAPI-SIM-01", "PSDK", "SIM0000001", "HW-SIM", "SW-SIM", "BOOT-SIM", 512)
                    : requirePrinter().queryDeviceInfo();
                if (info.getMtu() != null) {
                    knownMtu = info.getMtu();
                }
                return "设备类型：" + value(info.getDeviceType()) + "\n设备型号：" + value(info.getDeviceModel()) + "\n品牌：" + value(info.getBrand()) + "\n序列号：" + value(info.getSerialNumber()) + "\n硬件版本：" + value(info.getHardwareVersion()) + "\n软件版本：" + value(info.getSoftwareVersion()) + "\nBoot：" + value(info.getBootVersion()) + "\nMTU：" + value(info.getMtu());
            }
        });
    }

    void queryPrintStatus() {
        runPrinterAction("查询打印状态", request(EmapiConstants.PARENT_PRINTER, EmapiConstants.CHILD_PRINTER_STATUS), new PrinterCallable() {
            @Override
            public String call() throws Exception {
                EmapiPrintStatus status = simulationMode
                    ? new EmapiPrintStatus(1, 0, 0, 0, 86, 7400, 28)
                    : requirePrinter().queryPrintStatus();
                return "纸张：" + value(status.getPaperStatus()) + "\n开盖：" + value(status.getCoverStatus()) + "\n低电量：" + value(status.getLowBattery()) + "\n过热：" + value(status.getOverheat()) + "\n电量：" + value(status.getBatteryPercent()) + "\n电压：" + value(status.getBatteryVoltage()) + "\nTPH 温度：" + value(status.getTphTemperature());
            }
        });
    }

    void performWifiFileTransfer(final String path, final int fileType) {
        runPrinterAction("WIFI 文件传输", null, new PrinterCallable() {
            @Override
            public String call() throws Exception {
                byte[] bytes = simulationMode ? simulatedBytes(1536) : readRequiredFile(path, "请选择或输入 WIFI 文件路径");
                int chunkSize = fileChunkSize();
                transferSentBytes = 0;
                transferTotalBytes = bytes.length;
                latestTransferStatus = "WIFI 文件传输准备中";
                addRequestLog(new LogEntry("WIFI 文件传输文件", "fileType=0x" + Integer.toHexString(fileType) + "，准备发送 " + bytes.length + " bytes，chunkSize=" + chunkSize, bytes));
                if (simulationMode) {
                    simulateTransfer(bytes, chunkSize, "WIFI 文件传输中");
                } else {
                    EmapiPrinter actual = requirePrinter();
                    actual.startWifiFileDownload(fileType, bytes.length);
                    transferChunks(bytes, chunkSize, new ChunkSender() {
                        @Override
                        public void send(int index, byte[] chunk) throws Exception {
                            requirePrinter().transferWifiFileDownloadChunk(index, chunk);
                        }
                    }, "WIFI 文件传输中");
                    actual.finishWifiFileDownload();
                }
                latestTransferStatus = "WIFI 文件传输完成";
                return (simulationMode ? "模拟模式：" : "") + "WIFI 文件传输已完成\n" + transferProgress();
            }
        });
    }

    void performOta(final String path) {
        runPrinterAction("OTA 升级", null, new PrinterCallable() {
            @Override
            public String call() throws Exception {
                byte[] bytes = simulationMode ? simulatedBytes(2048) : readRequiredFile(path, "请选择或输入 OTA 文件路径");
                int chunkSize = fileChunkSize();
                transferSentBytes = 0;
                transferTotalBytes = bytes.length;
                latestTransferStatus = "OTA 升级准备中";
                addRequestLog(new LogEntry("OTA 升级文件", "准备发送 " + bytes.length + " bytes，chunkSize=" + chunkSize, bytes));
                if (simulationMode) {
                    emitSimulatedReport(new EmapiUpgradeStatusReport(reportCommand(EmapiConstants.CHILD_REPORT_UPGRADE_STATUS), 1));
                    simulateTransfer(bytes, chunkSize, "OTA 升级传输中");
                    emitSimulatedReport(new EmapiUpgradeStatusReport(reportCommand(EmapiConstants.CHILD_REPORT_UPGRADE_STATUS), 0));
                } else {
                    EmapiPrinter actual = requirePrinter();
                    actual.startMainControllerOta(bytes.length);
                    transferChunks(bytes, chunkSize, new ChunkSender() {
                        @Override
                        public void send(int index, byte[] chunk) throws Exception {
                            requirePrinter().transferMainControllerOtaChunk(index, chunk);
                        }
                    }, "OTA 升级传输中");
                    actual.finishMainControllerOta();
                    actual.upgradeMainController();
                }
                latestTransferStatus = "OTA 升级命令完成";
                return (simulationMode ? "模拟模式：" : "") + "OTA 升级命令已完成\n" + transferProgress();
            }
        });
    }

    void performEscPrint(final String path, final EscPrintOptions options) {
        runPrinterAction("ESC 图片打印", null, new PrinterCallable() {
            @Override
            public String call() throws Exception {
                byte[] image = simulationMode ? simulatedBytes(256) : readRequiredFile(path, "请选择或输入 ESC 图片路径");
                byte[] escBytes = EscCommandBuilder.buildImagePrint(image, options);
                addRequestLog(new LogEntry("ESC 指令数据", "生成 " + escBytes.length + " bytes ESC 指令", escBytes));
                if (!simulationMode) {
                    requirePrinter().printEsc(escBytes);
                } else {
                    emitSimulatedReport(new EmapiPrintResultReport(reportCommand(EmapiConstants.CHILD_REPORT_PRINT_RESULT), 0));
                }
                return (simulationMode ? "模拟模式：" : "") + "ESC 图片打印指令已完成";
            }
        });
    }

    void destroy(Context context) {
        stopScan(context);
        reportLoopRunning = false;
        disconnect();
        executor.shutdownNow();
    }

    private void runPrinterAction(final String label, final EmapiCommand requestCommand, final PrinterCallable callable) {
        if (busy()) {
            return;
        }
        pendingActionLabel = label;
        final int traceStart = tracingConnection == null ? 0 : tracingConnection.mark();
        if (requestCommand != null) {
            addRequestLog(new LogEntry(label, requestCommand.toString(), FrameCodec.encode(requestCommand)));
        }
        notifyChanged();
        executor.execute(new Runnable() {
            @Override
            public void run() {
                try {
                    String result = callable.call();
                    addActualOutboundLog(label, traceStart);
                    byte[] inbound = tracingConnection == null ? null : tracingConnection.bytesSince(traceStart, TracingEmapiConnection.INBOUND);
                    addCommandEntry(new LogEntry(label, result, inbound));
                } catch (Exception error) {
                    addActualOutboundLog(label, traceStart);
                    addCommandEntry(new LogEntry(label, formatError(error)));
                } finally {
                    pendingActionLabel = null;
                    notifyChanged();
                }
            }
        });
    }

    private void startReportLoop() {
        reportLoopRunning = true;
        executor.execute(new Runnable() {
            @Override
            public void run() {
                while (reportLoopRunning && printer != null) {
                    try {
                        handleReport(printer.readNextReport());
                    } catch (Exception ignored) {
                        return;
                    }
                }
            }
        });
    }

    private void handleReport(EmapiReport report) {
        String message = formatReport(report);
        if (report instanceof EmapiUpgradeStatusReport || report instanceof EmapiFlowControlReport) {
            latestTransferStatus = message;
        }
        reportLogs.add(0, new LogEntry("上报解析", message, FrameCodec.encode(report.getCommand())));
        notifyChanged();
    }

    private void emitSimulatedReport(EmapiReport report) {
        handleReport(report);
    }

    private EmapiPrinter requirePrinter() {
        if (printer == null) {
            throw new IllegalStateException("打印机未连接");
        }
        return printer;
    }

    private void addBondedDevices() {
        try {
            Set<BluetoothDevice> bondedDevices = bluetoothAdapter.getBondedDevices();
            for (BluetoothDevice device : bondedDevices) {
                devices.add(new DeviceModel(device.getName(), device.getAddress(), "Bluetooth Classic", false));
            }
        } catch (SecurityException error) {
            addCommandLog("读取已配对设备失败：" + error.getMessage());
        }
    }

    private void registerScanReceiver(Context context) {
        if (scanReceiver != null) {
            return;
        }
        scanReceiver = new BroadcastReceiver() {
            @Override
            public void onReceive(Context context, Intent intent) {
                if (BluetoothDevice.ACTION_FOUND.equals(intent.getAction())) {
                    BluetoothDevice device = intent.getParcelableExtra(BluetoothDevice.EXTRA_DEVICE);
                    if (device != null) {
                        try {
                            devices.add(new DeviceModel(device.getName(), device.getAddress(), "Bluetooth Classic", false));
                            notifyChanged();
                        } catch (SecurityException ignored) {
                        }
                    }
                }
            }
        };
        context.registerReceiver(scanReceiver, new IntentFilter(BluetoothDevice.ACTION_FOUND));
    }

    private void unregisterScanReceiver(Context context) {
        if (scanReceiver == null) {
            return;
        }
        try {
            context.unregisterReceiver(scanReceiver);
        } catch (IllegalArgumentException ignored) {
        }
        scanReceiver = null;
    }

    private void addActualOutboundLog(String label, int traceStart) {
        if (tracingConnection == null) {
            return;
        }
        byte[] outbound = tracingConnection.bytesSince(traceStart, TracingEmapiConnection.OUTBOUND);
        if (outbound != null) {
            addRequestLog(new LogEntry(label + " 实际发送", "真实连接写出的帧数据", outbound));
        }
    }

    private void transferChunks(byte[] bytes, int chunkSize, ChunkSender sender, String status) throws Exception {
        int index = 1;
        for (int offset = 0; offset < bytes.length; offset += chunkSize) {
            int end = Math.min(offset + chunkSize, bytes.length);
            byte[] chunk = new byte[end - offset];
            System.arraycopy(bytes, offset, chunk, 0, chunk.length);
            sender.send(index++, chunk);
            transferSentBytes = end;
            latestTransferStatus = status;
            notifyChanged();
        }
    }

    private void simulateTransfer(byte[] bytes, int chunkSize, String status) throws InterruptedException {
        for (int offset = 0; offset < bytes.length; offset += chunkSize) {
            Thread.sleep(60);
            transferSentBytes = Math.min(offset + chunkSize, bytes.length);
            latestTransferStatus = status;
            notifyChanged();
        }
    }

    private byte[] readRequiredFile(String path, String emptyMessage) throws IOException {
        if (path == null || path.trim().length() == 0) {
            throw new IllegalArgumentException(emptyMessage);
        }
        File file = new File(path.trim());
        if (!file.exists() || file.length() == 0) {
            throw new IllegalArgumentException("文件不存在或为空：" + path);
        }
        byte[] bytes = new byte[(int) file.length()];
        FileInputStream input = new FileInputStream(file);
        try {
            int offset = 0;
            while (offset < bytes.length) {
                int count = input.read(bytes, offset, bytes.length - offset);
                if (count < 0) {
                    break;
                }
                offset += count;
            }
            return bytes;
        } finally {
            input.close();
        }
    }

    private int fileChunkSize() {
        int capacity = knownMtu - EmapiConstants.FRAME_OVERHEAD_LENGTH - EmapiConstants.COMMAND_HEADER_LENGTH - 4;
        int aligned = (capacity / 32) * 32;
        return Math.max(32, aligned);
    }

    private byte[] simulatedBytes(int length) {
        byte[] data = new byte[length];
        for (int i = 0; i < data.length; i++) {
            data[i] = (byte) (i & 0xff);
        }
        return data;
    }

    private EmapiCommand request(int parent, int child) {
        return new EmapiCommand(EmapiConstants.TYPE_REQUEST, parent, child, new byte[0]);
    }

    private EmapiCommand passthrough(int child) {
        return new EmapiCommand(EmapiConstants.TYPE_PASSTHROUGH_REQUEST, EmapiConstants.PARENT_WIFI, child, new byte[0]);
    }

    private EmapiCommand reportCommand(int child) {
        return new EmapiCommand(EmapiConstants.TYPE_REQUEST, EmapiConstants.PARENT_REPORT, child, new byte[0]);
    }

    private String formatRfidCardInfo(EmapiRfidCardInfo info) {
        return "纸张型号：" + value(info.getPaperModel()) + "\n纸张长度：" + value(info.getPaperLength()) + "\n纸张宽度：" + value(info.getPaperWidth()) + "\n纸张颜色：" + value(info.getPaperColor()) + "\n物料号：" + value(info.getPaperMaterialNumber());
    }

    private String formatReport(EmapiReport report) {
        if (report instanceof EmapiPrintResultReport) {
            return "打印结果上报：result=" + ((EmapiPrintResultReport) report).getResult();
        }
        if (report instanceof EmapiPrinterStatusReport) {
            EmapiPrinterStatusReport status = (EmapiPrinterStatusReport) report;
            return "打印机状态上报：paper=" + value(status.getPaperStatus()) + " cover=" + value(status.getCoverStatus()) + " battery=" + value(status.getBatteryState()) + " overheat=" + value(status.getOverheat()) + " nfc=" + value(status.getNfcPaperRecognition());
        }
        if (report instanceof EmapiFlowControlReport) {
            return "流控上报：" + (((EmapiFlowControlReport) report).isBusy() ? "忙碌" : "空闲");
        }
        if (report instanceof EmapiUpgradeStatusReport) {
            return "升级状态上报：status=" + ((EmapiUpgradeStatusReport) report).getStatus();
        }
        if (report instanceof EmapiBluetoothConnectionReport) {
            return "蓝牙连接上报：state=" + ((EmapiBluetoothConnectionReport) report).getState();
        }
        if (report instanceof EmapiWifiConfigStatusReport) {
            EmapiWifiConfigStatusReport status = (EmapiWifiConfigStatusReport) report;
            return "WIFI 配网上报：SSID=" + value(status.getSsid()) + " state=" + value(status.getState());
        }
        if (report instanceof EmapiUnknownReport) {
            return "未知上报：" + report.getCommand();
        }
        return "上报：" + report.getCommand();
    }

    private String formatError(Throwable error) {
        return error.getClass().getSimpleName() + "：" + (error.getMessage() == null ? "" : error.getMessage());
    }

    private String value(Object value) {
        return value == null ? "-" : String.valueOf(value);
    }

    private void addCommandLog(String message) {
        addCommandEntry(new LogEntry("系统消息", message));
    }

    private void addCommandEntry(LogEntry entry) {
        commandLogs.add(0, entry);
    }

    private void addRequestLog(LogEntry entry) {
        requestLogs.add(0, entry);
    }

    private void notifyChanged() {
        mainHandler.post(new Runnable() {
            @Override
            public void run() {
                listener.onChanged();
            }
        });
    }

    private interface PrinterCallable {
        String call() throws Exception;
    }

    private interface ChunkSender {
        void send(int index, byte[] chunk) throws Exception;
    }
}
