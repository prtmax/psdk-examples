//
//  TTypes.m
//  AYSDK
//
//  Created by aiyin on 2023/9/14.
//

typedef NS_ENUM(NSInteger, EImageMode) {
    Normal,
    DoubleWidth,
    DoubleHeight,
    DoubleAll
};

typedef NS_ENUM(NSInteger, EPosition) {
    EPositionLeft,
    EPositionCenter,
    EPositionRight
};

typedef NS_ENUM(NSInteger, EThickness) {
    EThicknessLow,
    EThicknessMedium,
    EThicknessHigh
};

typedef NS_ENUM(NSInteger, EPaperType) {
    BLP,
    CP,
    LP
};

typedef NS_ENUM(NSInteger, ESet) {
    SetThickness = 0,       // 设置浓度
    SetShutTime = 1,        // 设置关机时间
    SetNone                 // none
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
