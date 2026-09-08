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
- (void)thickness:(EThickness)thickness;

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

#pragma mark - 配网
/**
 * APP设置配网信息
 * @param name SSID热点名称
 * @param pwd 密码
 * @param mode 加密方式  (0, 1, 2)
 */
- (void)setWifiName:(NSString *)name pwd:(NSString *)pwd mode:(int)mode;

/**
 * 查询配网是否成功
 * 成功返回 FC 00（0x00:未连接 0x01:热点连接成功 0x02:IOT连接成功(云联接)），失败无 返回
 */
- (void)getWifiState;

/**
 * 获取设备秘钥
 */
- (void)getKey;

/**
 * 设置设备秘钥 成功返回OK，失败返回ER
 */
- (void)setKey:(NSString *)key;

/**
 * 设置服务器域名 成功返回OK，失败返回ER
 */
- (void)setHosts:(NSArray<NSString *> *)hosts;

#pragma mark - ai 打印机接口

/**
 * 设置待机样式
 *
 * @param model 待机样式  1 图片  2 日历
 */
- (void)setStandbyMode:(int)model;

/**
 * 设置系统语言
 *
 * @param language 系统语言  1 英文  2 中文
 */
- (void)setSystemLanguage:(int)language;

/**
 * 获取系统语言
 *
 */
- (void)getSystemLanguage;

/**
 * 设置日历图案
 */
- (void)setCalendarMode:(int)mode;

/**
 * 设置待机图片（需配合 setStandbyMode:1 图片样式使用）
 *
 * 协议分三步：
 *   1. 开始包（帧头 10 FF 36 00 A5），携带图片总长度
 *   2. 分包发送图片数据（帧头 10 FF 36 01 A5）
 *   3. 结束包（帧头 10 FF 36 02 A5）
 *
 * 每包均包含校验和（数据域累加和 & 0xFF）及结束符 0x5A
 *
 * @param image 待机图片
 */
- (void)setStandbyImage:(UIImage *)image;

/**
 * 查询设备信息
 *
 */
- (void)getDeviceInfo;

/**
 * 绑定设备
 *
 * @param onceCode 一次性绑定码
 * @param server   服务器地址
 * @param expire   绑定过期时间
 */
- (void)bindDevice:(NSString *)onceCode server:(NSString *)server expire:(NSString *)expire;

@end

NS_ASSUME_NONNULL_END
