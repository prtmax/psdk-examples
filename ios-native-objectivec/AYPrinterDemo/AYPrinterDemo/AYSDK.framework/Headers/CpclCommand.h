//
//  CpclCommand.h
//  AYSDK
//
//  Created by aiyin on 2023/9/14.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <AYSDK/Command.h>
#import <AYSDK/CTypes.h>

NS_ASSUME_NONNULL_BEGIN

@interface CpclCommand : Command

/**
 * 设置标签宽度与高度及打印份数
 * @param width 标签宽度
 * @param height 标签高度
 * @param copies  打印份数
 */
- (void)pageWidth:(int)width height:(int)height copies:(int)copies;

/**
 * 打印完成后定位到下一页的顶部
 */
- (void)form;

/**
 * 定位到标签
 */
- (void)feed;

- (void)print:(BOOL)isClockwise180;

/**
 * 查询打印机状态
 */
- (void)state;

/**
 * 自测页
 */
- (void)selfTest;

/**
 * 用于以指定的宽和高横向或纵向打印条码
 * @param x 横向起始位置
 * @param y 纵向起始位置
 * @param d 条码方向，详见 CBarcodeDirection
 * @param width 窄条单位宽度
 * @param height 条码单位高度
 * @param content 条码内容
 */
- (void)barcodeX:(int)x y:(int)y type:(CCodeType)ct direction:(CBarcodeDirection)d width:(int)width height:(int)height content:(NSString *)content;

/**
 * 用于打印二维码
 * @param x 横向起始位置
 * @param y 纵向起始位置
 * @param width 条码宽度高度， 范围1~32
 * @param ecc 纠错等级，详见 CEccLevel
 * @param rotate 旋转角度，详见 CCodeRotation
 * @param content 内容
 */
- (void)qrCodeX:(int)x y:(int)y width:(int)width ecc:(CEccLevel)ecc rotate:(CCodeRotation)rotate content:(NSString *)content;

/**
 * 文本加粗
 * @param bold 是否加粗
 */
- (void)bold:(BOOL)bold;

/**
 * 文本加下划线
 * @param underLine 是否加下划线
 */
- (void)underLine:(BOOL)underLine;

/**
 * 水印文字
 * @param level 水印浓度
 */
- (void)waterMark:(int)level;

/**
 * 用于将所定义区域内的在其之前创建 的对象的黑色区域将重绘为白色，白色区域将重绘为黑色。这些对象可以包括文本、条码和/或图形
 * @param content 文本
 * @param font  字体，详见CFont
 * @param x  起点的 x 坐标（单位：点）
 * @param y  起点的 y 坐标（单位：点）
 * @param rotate 旋转角度，详见CRotation
 * @param reverse 是否反色
 */
- (void)textX:(int)x y:(int)y font:(CFont)font rotate:(CRotation)rotate reverse:(BOOL)reverse content:(NSString *)content;

/**
 * 生成指定线条宽度的矩形
 * @param x 左上角的X坐标
 * @param y 左上角的Y坐标
 * @param ex 右下角的X坐标
 * @param ey 右下角的Y坐标
 * @param width 线条单位宽度
 */
- (void)boxX:(int)x y:(int)y endX:(int)ex endY:(int)ey width:(int)width;

/**
 * 打印位图
 * @param image 图片
 * @param x 左上角位置的 x 坐标（单位：点）
 * @param y  左上角位置的 y 坐标（单位：点）
 * @param compress  是否压缩（需打印机支持压缩）
 */
- (void)image:(UIImage *)image x:(int)x y:(int)y compress:(BOOL)compress;

/**
 * 绘制指定长度、宽度和方向的线条
 * @param x 起始点的 x 坐标（单位：点）
 * @param y  起始点的 y 坐标（单位：点）
 * @param ex 终止点的 x 坐标（单位：点）
 * @param ey  终止点的 y 坐标（单位：点）
 * @param width 线条单位宽度
 * @param solid 是否是实线，实线:true  虚线:false
 */
- (void)lineX:(int)x y:(int)y endX:(int)ex endY:(int)ey width:(int)width solid:(BOOL)solid;

/**
 * 用于将所定义区域内的在其之前创建 的对象的黑色区域将重绘为白色，白色区域将重绘为黑色。这些对象可以包括文本、条码和/或图形
 * @param x 起始点的 x 坐标（单位：点）
 * @param y  起始点的 y 坐标（单位：点）
 * @param ex 终止点的 x 坐标（单位：点）
 * @param ey  终止点的 y 坐标（单位：点）
 * @param width 线条单位宽度
 */
- (void)inverseLineX:(int)x y:(int)y endX:(int)ex endY:(int)ey width:(int)width;



@end

NS_ASSUME_NONNULL_END
