
export enum EscQueryType {
  Info = 0,             // 查询打印机信息
  SN,               // 查询打印机SN
  Mac,              // 查询MAC地址
  State,            // 查询打印机状态
  Version,          // 查询打印机固件版本
  Model,            // 查询打印机型号
  BatteryVolume,    // 查询电量
  ShutTime,         // 查询关机时间
  BtName,           // 查询BT名称
  // PaperType,        // 查询纸张类型
  // BtVersion,        // 查询BT版本
  // NfcPaper,         // 查询纸张信息
  // NfcUID,           // 获取标签UID
  // NfcUsedLength,    // 获取标签使用长度
  // NfcRestLength,    // 获取标签剩余长度
}

export enum EscSettingType {
  Thickness,   // 设置浓度
  ShutTime,    // 设置关机时间
  // PaperType,   // 设置纸张类型
  // LabelGap,    // 设置学习标签缝隙
}

export enum ThicknessLevel {
  Low,      // 低浓度
  Medium,   // 中浓度
  High      // 高浓度
}

