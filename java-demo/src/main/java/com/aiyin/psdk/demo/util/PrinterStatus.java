package com.aiyin.psdk.demo.util;

public enum PrinterStatus {
  NORMAL,       //-正常
  LIB_IS_OPEN,  //-开盖
  PRINT_ERROR,  //-打印失败
  NO_PAPER,     //-缺纸
  PRINTING,     //-打印中
  PAUSED,       //-暂停
  OVERHEATED,   //-过热
  TIMEOUT       //-超时
}
