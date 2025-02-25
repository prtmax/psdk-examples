package com.example.classic_bluetooth_demo;

public enum ReadMark {
  NONE,
  OPERATE_PRINT,//打印操作
  OPERATE_STATUS,//打印机状态查询
  OPERATE_BATVOL,//电量查询
  OPERATE_SHUTDOWN_TIME,//设置关机时间
  OPERATE_INFO,//设备所有信息
  OPERATE_INK_BOX_INFO,//墨盒信息
  OPERATE_OTA,//ota升级
}
