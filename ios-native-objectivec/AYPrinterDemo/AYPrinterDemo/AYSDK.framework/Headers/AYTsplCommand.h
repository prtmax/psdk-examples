//
//  AYWifiCommand.h
//  AYSDK
//
//  Created by aiyin on 2023/9/12.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <AYSDK/Command.h>
#import <AYSDK/TTypes.h>

NS_ASSUME_NONNULL_BEGIN

@interface AYTsplCommand : Command

#pragma mark - command

/**
 * 清除画布缓存
 */
- (void)cls;

/**
 * 定义标签宽度与高度
 * @param width 标签宽度
 * @param height 标签高度
 */
- (void)pageWidth:(int)width height:(int)height;

/**
 * 设定打印方向和镜像打印
 */
- (void)direction:(TOutDirection)direction mirror:(BOOL)mirror;

/**
 * 设置打印速度
 */
- (void)speed:(int)speed;

/**
 * 设置打印浓度
 * @param density 浓度，0~15 0：最淡 15：最浓 8：默认浓度
 */
- (void)density:(int)density;

- (void)enableGap:(BOOL)enable;

- (void)enableCut:(BOOL)enable;

/**
 * 绘制线条
 * @param x 起始横坐标
 * @param y 起始纵坐标
 * @param width 线宽，以点(dot)表示
 * @param height 线高，以点(dot)表示
 * @param dotted 实线/虚线 0-实线；1-虚线
 */
- (void)barX:(int)x y:(int)y width:(int)width height:(int)height dotted:(BOOL)dotted;

/**
 * 绘制一维条码
 * @param x 起始横坐标
 * @param y 起始纵坐标
 * @param cType 条码类型，（祥见 TCodeType）
 * @param height 条码高度（单位：点）
 * @param sType 可读字符显示位置，（祥见 TShowType）
 * @param rotation 顺时针旋转角度，（祥见 TRotation）
 * @param narrow 窄条宽度（单位：点）
 * @param wide 宽条宽度（单位：点）
 * @param content 条码内容
 */
- (void)barCodeX:(int)x y:(int)y type:(TCodeType)cType height:(int)height hriPosition:(TShowType)sType rotation:(TRotation)rotation narrow:(int)narrow wide:(int)wide content:(NSString *)content;

/**
 * 设置黑标的高度以及用户自定义的每次定位额外走纸高度
 * @param height 黑标高度（单位：毫米）
 * @param offset 额外走纸高度（单位：毫米）
 */
- (void)bLineHeight:(int)height offset:(int)offset;

/**
 * 绘制方框
 * @param x 左上角位置的 x 坐标（单位：点）
 * @param y  左上角位置的 y 坐标（单位：点）
 * @param ex  右下角位置的 x 坐标（单位：点）
 * @param ey  右下角位置的 y 坐标（单位：点）
 * @param thickness    线宽（单位：点）
 * @param radius  圆角半径，默认为0
 */
- (void)boxX:(int)x y:(int)y endX:(int)ex endY:(int)ey thickness:(int)thickness radius:(int)radius;

/**
 * 绘制圆形
 * @param x 左上角位置的 x 坐标（单位：点）
 * @param y  左上角位置的 y 坐标（单位：点）
 * @param diameter  直径（单位：点）
 * @param thickness    线宽（单位：点）
 */
- (void)circleX:(int)x y:(int)y diameter:(int)diameter thinkness:(int)thickness;

/**
 * 绘制二维条码DATAMATRIX
 * @param x 左上角位置的 x 坐标（单位：点）
 * @param y  左上角位置的 y 坐标（单位：点）
 * @param width  条码宽度（单位：点）
 * @param height  条码高度（单位：点）
 * @param content   条码内容
 */
- (void)dataMatrix:(int)x y:(int)y width:(int)width height:(int)height content:(NSString *)content;

/**
 * 打印位图
 * @param image 图片
 * @param x 左上角位置的 x 坐标（单位：点）
 * @param y  左上角位置的 y 坐标（单位：点）
 * @param compress  是否压缩（需打印机支持压缩）
 */
- (void)image:(UIImage *)image x:(int)x y:(int)y compress:(BOOL)compress;

/**
 * 绘制线
 * @param x 左上角位置的 x 坐标（单位：点）
 * @param y  左上角位置的 y 坐标（单位：点）
 * @param ex  右下角位置的 x 坐标（单位：点）
 * @param ey  右下角位置的 y 坐标（单位：点）
 * @param width  条码宽度（单位：点）
 * @param lType   线的类型，（祥见 TLineType）
 */
- (void)lineX:(int)x y:(int)y endX:(int)ex endY:(int)ey width:(int)width lineType:(TLineType)lType;

/**
 * 绘制二维码
 * @param x 左上角位置的 x 坐标（单位：点）
 * @param y  左上角位置的 y 坐标（单位：点）
 * @param ecc   纠错等级，（祥见 TECCLevel）
 * @param rotation  旋转角度，（祥见 TRotation）
 * @param cw 单元宽度
 * @param content   条码内容
 */
- (void)qrCodeX:(int)x y:(int)y ecc:(TECCLevel)ecc cellwidth:(int)cw rotation:(TRotation)rotation content:(NSString*)content;

/**
 * 反白指定的区域
 * @param x  左上角位置的 x 坐标（单位：点）
 * @param y   左上角位置的 y 坐标（单位：点）
 * @param width     x 轴方向宽度（单位：点）
 * @param height     y 轴方向高度（单位：点）
 */
- (void)reverseX:(int)x y:(int)y width:(int)width height:(int)height;

/**
 * 绘制文本
 * @param x  左上角位置的 x 坐标（单位：点）
 * @param y   左上角位置的 y 坐标（单位：点）
 * @param font     字体，（祥见 TFont）
 * @param rotation      旋转角度，（祥见 TRotation）
 * @param xm     水平方向放大倍数
 * @param ym      垂直方向放大倍数
 * @param bold      是否加粗
 * @param content      文本内容
 */
- (void)textX:(int)x y:(int)y font:(TFont)font rotation:(TRotation)rotation xMulti:(int)xm yMulti:(int)ym bold:(BOOL)bold content:(NSString *)content;

/**
 * 绘制文本框
 * @param x  左上角位置的 x 坐标（单位：点）
 * @param y   左上角位置的 y 坐标（单位：点）
 * @param font     字体，（祥见 TFont）
 * @param rotation      旋转角度，（祥见 TRotation）
 * @param rotationType      false: 旋转每一个字 true：整体旋转
 * @param xm     水平方向放大倍数
 * @param ym      垂直方向放大倍数
 * @param width    文本框宽度
 * @param linespace       行间距
 * @param bold      是否加粗
 * @param content      文本内容
 */
- (void)textBoxX:(int)x text_y:(int)y font:(TFont)font rotation:(TRotation)rotation rotationType:(BOOL)rotationType xMulti:(int)xm yMulti:(int)ym width:(int)width linespace:(int)linespace bold:(BOOL)bold content:(NSString *)content;

/**
 * 打印已缓存的标签
 * @param copies 打印的数量
 */
- (void)print:(int)copies;

/**
 * 打印自检页
 */
- (void)selfTest;

/**
 * 查询打印机sn号
 */
- (void)readSN;

/**
 * 查询打印机版本
 */
- (void)readVersion;

/**
 * 查询打印机电量，适用于电池款
 */
- (void)readBatteryLevel;

/**
 * 查询打印机状态
 */
- (void)readPrinterState;

/**
  * 设置关机时间
  * @param time 关机时间（分钟）    设置成功回复："WRITEC OFFTIME OK\r\n"
  */
- (void)setOffTime:(uint)time;

/**
  * 获取关机时间 , 回复分钟数：XXXX（unsigned int，00表示永不自动关机）
  */
- (void)getOffTime;

@end

NS_ASSUME_NONNULL_END
