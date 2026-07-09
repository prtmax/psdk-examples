//
//  AYRGB.h
//  AYSDK
//
//  Created by aiyin on 1/29/26.
//

#import <AYSDK/AYSDK.h>

@interface AYRGBCommand : Command

#pragma mark - 页面与基础控制

/**
 * 设置标签页面大小
 *
 * @param width  页面宽度（mm）
 * @param height 页面高度（mm）
 */
- (void)pageWidth:(int)width height:(int)height;

/**
 * 清除打印缓冲区
 */
- (void)cls;

/**
 * 执行打印
 *
 * @param copies 打印份数
 */
- (void)print:(int)copies;

/**
 * 取消当前打印任务
 */
- (void)cancel;

#pragma mark - 图片相关

/**
 * 打印图片
 *
 * @param image   UIImage 图片对象
 * @param x       起始 X 坐标
 * @param y       起始 Y 坐标
 * @param quality  图片质量（0:快速 1:精细 2:照片）
 * @param mode  0:覆盖 1:或 2:异或 3:自定义 4:JPG 5:PNG 6:BMP
 */
- (void)image:(UIImage *)image
            x:(int)x
            y:(int)y
      quality:(int)quality
         mode:(int)mode;

/**
 * 打印图片
 *
 * @param image   UIImage 图片对象
 * @param x       起始 X 坐标
 * @param y       起始 Y 坐标
 * @param quality  图片质量（0:快速 1:精细 2:照片）
 * @param mode  0:覆盖 1:或 2:异或 3:自定义 4:JPG 5:PNG 6:BMP
 */
- (void)imageSN:(UIImage *)image
            x:(int)x
            y:(int)y
      quality:(int)quality
         mode:(int)mode;

#pragma mark - 打印机信息查询

/**
 * 查询打印机配置信息
 */
- (void)info;

/**
 * 查询墨盒 / 碳带信息
 */
- (void)inkBoxInfo;

/**
 * 查询打印机序列号
 */
- (void)sn;

/**
 * 查询打印机当前状态
 */
- (void)state;

/**
 * 查询电池电量
 */
- (void)batteryVolume;

/**
 * 退纸
 */
- (void)ejectPaper;

/**
 * 清洁打印头
 */
- (void)printerClean;

/**
 * 打印自测页
 */
- (void)selfTest;

#pragma mark - 系统设置

/**
 * 设置自动关机时间
 *
 * @param time 时间（单位依设备协议，通常为秒）00    永不     01    15min     02    30min     03    60min
 */
- (void)setShutdownTime:(int)time;

#pragma mark - OTA 升级
/**
 * OTA 升级
 *
 * @param data 固件数据
 */
- (void)ota:(NSData *)data;

@end
