package com.example.classic_bluetooth_demo;

public enum ReadMark {
  NONE,
  GET_LABEL_HEIGHT,
  OPERATE_PRINT,//连续纸打印操作
  OPERATE_PRINT_LABEL,//缝隙纸打印操作
  OPERATE_STATUS,//打印机状态查询
  OPERATE_BATVOL,//电量查询
  OPERATE_PRINTERSN,//打印机SN号
  OPERATE_PRINTERMODEL,//打印机型号
  OPERATE_PRINTERVER,//打印机软件版本号
  OPERATE_BTMAC,//蓝牙mac地址
  OPERATE_BTVER,//蓝牙软件版本号
  OPERATE_BTNAME,//蓝牙名称
  OPERATE_INFO,//设备所有信息
  OPERATE_PAPERTYPE,//纸张类型
}
