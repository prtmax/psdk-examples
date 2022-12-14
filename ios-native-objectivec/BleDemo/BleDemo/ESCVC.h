//
//  ESCVC.h
//  BleDemo
//
//  Created by IPRT on 2022/11/22.
//

#import "BaseVC.h"
#import <esc/BasicESC.h>
NS_ASSUME_NONNULL_BEGIN
/**
 * 查询标识
 */
typedef enum {
    /**
     * 校验打印机，用于判断是否为可允许打印机
     */
    CHECKPRINTER = 0,
    /**
     * 查询打印机状态
     */
    PRINTERSTATUS,
    /**
     * 查询电量
     */
    BATTERYVOL,
    /**
     * 查询温湿度
     */
    TEMPANDHUM,
    /**
     * 查询BT名称
     */
    BTNAME,
    /**
     * 查询MAC地址
     */
    MAC,
    /**
     * 查询BT版本
     */
    BTVERSION,
    /**
     * 查询打印机版本
     */
    PRINTERVERSION,
    /**
     * 查询打印机SN
     */
    PRINTERSN,
    /**
     * 查询打印机型号
     */
    PRINTERMODEL,
    /**
     * 查询打印机信息
     */
    PRINTERINFOR,
    /**
     * 查询标签高度
     */
    LABELHEIGHT,
    /**
     * 查询打印状态
     */
    PRINTSTATUS,
    /**
     * 自动识别高度
     */
    RECOGNITIONHEIGHT,
    /**
     * 预留，暂时无用
     */
    THICKNESS
} SEARCHTYPE;
@interface ESCVC : BaseVC
@end

NS_ASSUME_NONNULL_END
