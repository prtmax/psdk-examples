//
//  ESC.h
//  AYSDK
//
//  Created by aiyin on 2023/9/14.
//

#import <Foundation/Foundation.h>
#import <AYSDK/Command.h>
#import <UIKit/UIKit.h>
#import <AYSDK/ETypes.h>

NS_ASSUME_NONNULL_BEGIN

@interface AYEscCommand : Command

#pragma mark - 打印指令/print command
/**
 * 使能打印机
 */
- (void)enable;

/**
 * 唤醒打印机 每次打印之前都要调用该函数，防止由于打印机进入低功耗模式而丢失数据
 */
- (void)wake;

/**
 * 打印定位 缝隙纸下调用
 */
- (void)position;

/**
 * 结束打印任务
 */
- (void)stopPrintJob;

/**
 * 走纸命令
 * @param linedots 走纸行数
 */
- (void)linedots:(Byte)linedots;

/**
 * 设置打印位置
 * @param position 打印位置，详见：EPosition
 */
- (void)contentPosition:(EPosition)position;

/**
 * 打印光栅位图
 * @param image 图片
 * @param compress   是否压缩
 * @param mode  打印模式，详见：EImageMode
 */
- (void)image:(UIImage *)image compress:(BOOL)compress mode:(EImageMode)mode;

#pragma mark - 查询指令/query command
/**
 * 查询打印机状态
 */
- (void)state;

/**
 * 查询蓝牙名称
 */
- (void)btName;

/**
 * 查询蓝牙固件版本
 */
- (void)btVersion;

/**
 * 查询打印机SN
 */
- (void)sn;

/**
 * 查询打印机mac地址
 */
- (void)mac;

/**
 * 查询打印机电量
 */
- (void)batteryVol;

/**
 * 查询温湿度
 */
- (void)temperatureAndHumidity;

/**
 * 查询打印机固件版本
 */
- (void)printerVersion;

/**
 * 查询打印机型号
 */
- (void)printerModel;

/**
 * 查询打印机信息
 */
- (void)printerInfo;

/**
 * 查询打印机关机时间
 */
- (void)shutTime;

/**
 * 查询打印机纸张类型
 */
- (void)paperType;

/**
 * 获取标签纸张信息
 */
- (void)nfcPaper;

/**
 * 获取标签UID
 */
- (void)nfcUID;

/**
 * 获取标签使用长度
 */
- (void)nfcUsedLength;

/**
 *  获取标签剩余长度
 */
- (void)nfcRestLength;


#pragma mark - 设置指令/setting command
/**
 * 设置关机时间
 * @param time 关机时间，单位：分钟，不关机传 0
 */
- (void)shutTime:(int)time;

/**
 * 设置浓度
 * @param thickness 浓度
 */
-(void)thickness:(EThickness)thickness;

/**
 * 设置纸张类型
 * @param type 纸张类型
 */
- (void)paperType:(EPaperType)type;

/**
 * 学习标签缝隙（返回OK，还得下发3条指令: enablePrinter / printerPosition / stopPrintJob）
 */
- (void)learnLabelGap;

/**
 *  纸张类型(Q1 Q2 Q3 D11 D30 B21 B22用这个)
 */
- (void)paperTypeQX:(EPaperTypeQX)type;
@end

NS_ASSUME_NONNULL_END
