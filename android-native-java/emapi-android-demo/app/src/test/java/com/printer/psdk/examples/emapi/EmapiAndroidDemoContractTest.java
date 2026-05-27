package com.printer.psdk.examples.emapi;

import org.junit.Assert;
import org.junit.Test;

import java.io.File;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;

public class EmapiAndroidDemoContractTest {
    @Test
    public void mainActivity_containsFlutterParityLabels() throws Exception {
        String source = read("src/main/java/com/printer/psdk/examples/emapi/MainActivity.java");
        String[] labels = {
            "EMAPI Android Demo", "设置", "断开", "蓝牙设备", "模拟测试台", "开始扫描", "扫描中", "停止", "设备列表",
            "测试模式", "模拟模式", "发送指令", "命令结果", "上报解析", "休眠关机", "打印自检页",
            "设置关机时间", "RFID UID", "RFID 信息", "纸张长度", "RFID 失败处理", "配网信息",
            "WIFI 状态", "热点信息", "WiFi 文件传输", "基本参数", "打印状态", "ESC 打印", "OTA 升级",
            "WiFi 文件传输", "选择文件", "开始传输", "选择 OTA 文件", "开始 OTA 升级", "选择图片", "开始打印",
            "连续", "间隙", "黑标", "普通", "双重", "灰阶", "图像压缩"
        };
        for (String label : labels) {
            Assert.assertTrue("Missing label: " + label, source.contains(label));
        }
    }

    @Test
    public void controller_containsRequiredJavaEmapiSdkCalls() throws Exception {
        String source = read("src/main/java/com/printer/psdk/examples/emapi/EmapiDemoController.java");
        String[] calls = {
            ".sleepShutdown()", ".printSelfTestPage()", ".setShutdownTime(minutes)", ".queryRfidUid()",
            ".queryRfidCardInfo()", ".queryRfidPaperLength()", ".setRfidAuthFailureHandling(EmapiRfidAuthFailurePolicy.FORBID_PRINT)",
            ".setWifiConfig(ssid, password)", ".queryWifiConnectionState()", ".queryWifiHotspotInfo()",
            ".queryDeviceInfo()", ".queryPrintStatus()", ".startWifiFileDownload(fileType, bytes.length)",
            ".transferWifiFileDownloadChunk(index, chunk)", ".finishWifiFileDownload()", ".startMainControllerOta(bytes.length)",
            ".transferMainControllerOtaChunk(index, chunk)", ".finishMainControllerOta()", ".upgradeMainController()", ".printEsc(escBytes)",
            ".readNextReport()"
        };
        for (String call : calls) {
            Assert.assertTrue("Missing SDK call: " + call, source.contains(call));
        }
    }

    private String read(String relativePath) throws Exception {
        File file = new File(relativePath);
        return new String(Files.readAllBytes(file.toPath()), StandardCharsets.UTF_8);
    }
}
