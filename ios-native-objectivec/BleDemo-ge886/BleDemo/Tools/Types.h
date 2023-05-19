//
//  Types.h
//  Printer
//
//  Created by aiyin on 2022/12/15.
//  Copyright © 2022 printer. All rights reserved.
//

/**
 * 查询标识
 */
typedef enum {
    CHECKPRINTER = 0,   // 校验打印机，用于判断是否为可允许打印机
    PRINTERSTATUS,      // 查询打印机状态
    BATTERYVOL,         // 查询电量
    TEMPANDHUM,         // 查询温湿度
    BTNAME,             // 查询BT名称
    MAC,                // 查询MAC地址
    BTVERSION,          // 查询BT版本
    PRINTERVERSION,     // 查询打印机版本
    PRINTERSN,          // 查询打印机SN
    PRINTERMODEL,       // 查询打印机型号
    PRINTERINFOR,       // 查询打印机信息
    LABELHEIGHT,        // 查询标签高度
    PRINTSTATUS,        // 查询打印状态
    RECOGNITIONHEIGHT,  // 自动识别高度
    NONE_NONE,          // none
} SEARCHTYPE;
