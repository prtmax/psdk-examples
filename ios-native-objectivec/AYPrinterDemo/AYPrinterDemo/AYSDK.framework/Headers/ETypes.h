//
//  TTypes.m
//  AYSDK
//
//  Created by aiyin on 2023/9/14.
//

typedef NS_ENUM(NSInteger, EImageMode) {
    Normal = 0,      // 正常打印
    DoubleWidth,     // 倍宽打印
    DoubleHeight,    // 倍高打印
    DoubleAll        // 倍宽倍高打印
};

typedef NS_ENUM(NSInteger, EPosition) {
    EPositionLeft,      // 居左
    EPositionCenter,    // 居中
    EPositionRight      // 居右
};

typedef NS_ENUM(NSInteger, EThickness) {
    EThicknessLow,      // 低浓度
    EThicknessMedium,   // 中浓度
    EThicknessHigh      // 高浓度
};

typedef NS_ENUM(NSInteger, EPaperType) {
    EPaperTypeBlackMark = 0,    // 黑标纸模式
    EPaperTypeContinuous,       // 连续纸模式
    EPaperTypeGap,              // 缝隙纸模式
    EPaperTypeHole,             // 打孔纸模式
    EPaperTypeTattoo,           // 纹身纸模式
    EPaperTypeTattooWrinkles,   // 纹身纸（防皱模式）
};

typedef NS_ENUM(NSInteger, EPaperTypeQX) {
    EPaperTypeQXGap,              // 缝隙纸模式
    EPaperTypeQXBlackMark,        // 黑标纸模式
    EPaperTypeQXContinuous,       // 连续纸模式
};

typedef NS_ENUM(NSInteger, ESet) {
    SetThickness = 0,   // 设置浓度
    SetShutTime = 1,    // 设置关机时间
    SetPaperType,       // 设置纸张类型
    SetLabelGap,        // 设置学习标签缝隙
    SetNone             // none
};


typedef NS_ENUM(NSInteger, EQuery) {
    CheckPrinter = 0,           // 校验打印机，用于判断是否为可允许打印机
    
    QueryState = 1,       // 查询打印机状态
    QuerySN,              // 查询打印机SN
    QueryMac,             // 查询MAC地址
    QueryVersion,         // 查询打印机版本
    QueryModel,           // 查询打印机型号
    QueryBatteryVol,      // 查询电量
    QueryShutTime,        // 查询关机时间
    QueryTempAndHun,      // 查询温湿度
    QueryInfo,            // 查询打印机信息
    QueryPaperType,       // 查询纸张类型
    
    QueryBtName,          // 查询BT名称
    QueryBtVersion,       // 查询BT版本
    
    QueryNfcPaper,        // 查询纸张信息
    QueryNfcUID,          // 获取标签UID
    QueryNfcUsedLength,   // 获取标签使用长度
    QueryNfcRestLength,   // 获取标签剩余长度
    
    QueryNone,                    // none
    
    
//    LableHeight,            // 查询标签高度
//    PrintState,             // 查询打印状态
//    RECOGNITIONHEIGHT,      // 自动识别高度
//    SETPAPERTYPE,           // 设置纸张类型
//    THICKNESS,              // 预留，暂时无用
    //    SETTHICKNESS,           // 设置浓度
    //    SETSHUTOFFTIME,         // 设置关机时间
};
