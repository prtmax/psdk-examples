package com.example.classic_bluetooth_demo;

public class Config {
  public int resolution;        // 分辨率
  public String hardwareVersion; // 硬件版本
  public String firmwareVersion;// 固件版本
  public int autoShutdown;      // 定时关机设置
  public int beepEnabled;       // 提示音设置

  @Override
  public String toString() {
    String shutdownDesc;
    switch (autoShutdown) {
      case 0:
        shutdownDesc = "永不关机";
        break;
      case 1:
        shutdownDesc = "15分钟后关机";
        break;
      case 2:
        shutdownDesc = "30分钟后关机";
        break;
      case 3:
        shutdownDesc = "60分钟后关机";
        break;
      default:
        shutdownDesc = "未知设置(" + autoShutdown + ")";
    }

    return "打印机配置:\n" +
      "  分辨率: " + resolution + " dpi\n" +
      "  硬件版本: " + hardwareVersion + "\n" +
      "  固件版本: " + firmwareVersion + "\n" +
      "  定时关机: " + shutdownDesc + "\n" +
      "  提示音: " + (beepEnabled == 1 ? "开启" : "关闭");
  }
}
