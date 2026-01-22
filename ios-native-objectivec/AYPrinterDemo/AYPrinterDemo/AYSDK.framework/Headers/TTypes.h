//
//  TTypes.m
//  AYSDK
//
//  Created by aiyin on 2023/9/14.
//


typedef NS_ENUM(NSInteger, TReceivedType) {
    TReceivedTypeSN,
    TReceivedTypeVersion,
    TReceivedBatteryLevel,
    TReceivedPrinterState,
    TReceivedPrintSuccess,
    TReceivedSetOffTime,  // 设置关机时间
    TReceivedGetOffTime,  // 获取关机时间
    TReceivedStatus,      // 状态上报
    TReceivedNone,
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
};
