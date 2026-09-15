//
//  TTypes.m
//  AYSDK
//
//  Created by aiyin on 2023/9/14.
//


typedef NS_ENUM(NSInteger, TReceivedType) {
    TReceivedTypeSN,              // 查询序列号返回
    TReceivedTypeVersion,          // 查询固件版本返回
    TReceivedBatteryLevel,         // 电池电量上报
    TReceivedPrinterState,         // 打印机状态上报
    TReceivedPrintSuccess,         // 打印任务成功上报
    TReceivedSetOffTime,           // 设置关机时间
    TReceivedGetOffTime,            // 获取关机时间
    TReceivedStatus,                // 状态上报
    TReceivedNotSpace,              // 空间不足
    TReceivedSpaceEnough,           // 空间恢复正常
    TReceivedTypeHardwareVersion,   // 固件版本
    TReceivedTypeFactoryReset,      // 恢复出厂
    TReceivedNone,                  // 未分类/默认类型

    // 新增 TSPL 查询类型（追加在 TReceivedNone 后，保持既有枚举值不变）
    TReceivedTypeModel,           // 打印机型号
    TReceivedTypePrintLife,       //  打印机寿命
    TReceivedTypeBluetoothModel,   // 蓝牙模块型号
    TReceivedTypeBluetoothVersion, // 蓝牙固件版本
    TReceivedTypeBluetoothMAC,     // 蓝牙 MAC 地址
    TReceivedTypeBluetoothName,    // 蓝牙设备名称
    TReceivedTypeWifiVersion,      // Wi-Fi 版本信息
    TReceivedTypeDRAMSpace,        // DRAM 容量
    TReceivedTypeDRAMFileList,     // DRAM 文件列表
    TReceivedTypeFlashSpace,       // FLASH 容量
    TReceivedTypeFlashFileList,    // FLASH 文件列表
    TReceivedTypeCardSpace,        //  储存卡容量（与 FLASH 命令一致）
    TReceivedTypeDiagnosticReport, //  通用回执
    TReceivedTypePrinterBase,      // 打印机基础信息（cJSON 字符串）
};

typedef NS_ENUM(NSInteger, TOutDirection) {
    UP_OUT,      // 0-上端先出
    DOWN_OUT    // 1－下端先出
};

typedef NS_ENUM(NSInteger, TCodeType) {
    TCodeType_128,
    TCodeType_39,
    TCodeType_93,
    TCodeType_ITF,
    TCodeType_UPCA,
    TCodeType_UPCE,
    TCodeType_CODABAR,
    TCodeType_EAN8,
    TCodeType_EAN13,
};

typedef NS_ENUM(int, TShowType) {
    TShowTypeNone = 0,
    TShowTypeLeft = 1,
    TShowTypeCenter = 2,
    TShowTypeRight = 3,
};

typedef NS_ENUM(int, TRotation) {
    TRotation_0 = 0,
    TRotation_90 = 90,
    TRotation_180 = 180,
    TRotation_270 = 270,
};

typedef NS_ENUM(int, TLineType) {
    TLineTypeSolid = 0,
    TLineTypeDotted = 1,
    TLineTypeDashed_1 = 2,
    TLineTypeDashed_2 = 3,
    TLineTypeDashed_3 = 4
};

typedef NS_ENUM(int, TECCLevel) {
    TECCLevelL = 0,
    TECCLevelM = 1,
    TECCLevelQ = 2,
    TECCLevelH = 3,
};

typedef NS_ENUM(int, TFont) {
    TFontTSS12 = 0, // 12点阵
    TFontTSS16 = 1, // 16点阵
    TFontTSS20 = 2, // 20点阵
    TFontTSS24 = 3, // 24点阵
    TFontTSS28 = 4, // 28点阵
    TFontTSS32 = 5, // 32点阵
    TFontSIMHEI = 6 //
};
