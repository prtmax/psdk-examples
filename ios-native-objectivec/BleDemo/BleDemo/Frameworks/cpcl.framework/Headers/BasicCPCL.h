//
//  BasicCPCL.h
//  cpcl
//
//  Created by IPRT on 2022/11/16.
//

#import <father/PSDK.h>
#import <father/Lifecycle.h>
#import <cpcl/cpcl.h>
#import <adapter/KeepStateConnectedDevice.h>
NS_ASSUME_NONNULL_BEGIN

@interface BasicCPCL<T> : PSDK
@property(nonatomic , readonly)BasicCPCL *(^BasicCPCL)(Lifecycle *lifecycle, CPCLPrinter printer);
-(ConnectedDevice *)getConnectedDevice;
-(CPCLPrinter)getPrinter;
-(void)safeCheck:(Lifecycle *)lifecycle;
/**
   * 一维码
   */
@property (nonatomic , readonly) BasicCPCL *(^bar)(CBar *arg);
-(T)bar:(CBar *)arg;
/**
   * 画边框
   */
@property (nonatomic , readonly) BasicCPCL *(^box)(CBox *arg);
-(T)box:(CBox *)arg;
/**
   * 加粗
   *
   * @param isBold true 加粗 false 不加粗
   */
@property (nonatomic , readonly) BasicCPCL *(^bold)(BOOL isBold);
-(T)bold:(BOOL)isBold;
/**
   * 定位到标签
   */
@property (nonatomic , readonly) BasicCPCL *(^feed)(void);
-(T)queryFeed;
@property (nonatomic , readonly) BasicCPCL *(^form)(void);
-(T)queryForm;
/**
   * 打印图片
   */
@property (nonatomic , readonly) BasicCPCL *(^image)(CImage *arg);
-(T)image:(CImage *)arg;
/**
  * 反白
  */
@property (nonatomic , readonly) BasicCPCL *(^inverse)(CInverse *arg);
-(T)inverse:(CInverse *)arg;
/**
 * 画线(能画斜线)
 */
@property (nonatomic , readonly) BasicCPCL *(^line)(CLine *arg);
-(T)line:(CLine *)arg;
@property (nonatomic , readonly) BasicCPCL *(^mag)(CMag *arg);
-(T)mag:(CMag *)arg;
/**
   * 打印模式
   */
@property (nonatomic , readonly) BasicCPCL *(^pageMode)(CPageMode *arg);
-(T)pageMode:(CPageMode *)arg;
/**
   * 创建打印页面大小
   */
@property (nonatomic , readonly) BasicCPCL *(^page)(CPage *arg);
-(T)page:(CPage *)arg;
/**
 * 打印
 */
@property (nonatomic , readonly) BasicCPCL *(^print)(CPrint *arg);
-(T)print:(CPrint *)arg;
/**
   * 打印二维码
   */
@property (nonatomic , readonly) BasicCPCL *(^qrcode)(CQRCode *arg);
-(T)qrcode:(CQRCode *)arg;
/**
   * 打印文本
   */
@property (nonatomic , readonly) BasicCPCL *(^text)(CText *arg);
-(T)text:(CText *)arg;
/**
   * 下划线
   *
   * @param isUnderline true 画下划线 false 不画下划线
   */
@property (nonatomic , readonly) BasicCPCL *(^underline)(BOOL isUnderline);
-(T)underline:(BOOL)isUnderline;
/**
  * 水印
  *
  * @param value 水印浓度值
  */
@property (nonatomic , readonly) BasicCPCL *(^waterMark)(int value);
-(T)waterMark:(int)value;

/**
 * 查询打印机状态
 */
@property (nonatomic , readonly) BasicCPCL *(^status)(void);
-(T)queryStatus;
@end

NS_ASSUME_NONNULL_END
