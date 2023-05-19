//
//  BasicTSPL.h
//  tspl
//
//  Created by IPRT on 2022/11/19.
//

#import <father/father.h>
#import <adapter/adapter.h>
#import <tspl/tspl.h>
NS_ASSUME_NONNULL_BEGIN

@interface BasicTSPL<T> : PSDK
@property(nonatomic , readonly) BasicTSPL *(^BasicTSPL)(Lifecycle *lifecycle,TSPLPrinter printer);

-(ConnectedDevice *)getConnectedDevice;
-(TSPLPrinter)getPrinter;
/**
   * 画线(只能画横竖线)
   */
@property(nonatomic , readonly) BasicTSPL *(^bar)(TBar *arg);
/**
   * 画线(能画斜线)
   */
@property(nonatomic , readonly) BasicTSPL *(^line)(TLine *arg);

/**
   * 二维码
   */
@property(nonatomic , readonly) BasicTSPL *(^barcode)(TBarCode *arg);
/**
 * 打印边框
 */
@property(nonatomic , readonly) BasicTSPL *(^box)(TBox *arg);

/**
  * 画圆
  */
@property(nonatomic , readonly) BasicTSPL *(^circle)(TCircle *arg);
/**
   * 清除页面缓冲区
   */
@property(nonatomic , readonly) BasicTSPL *(^cls)(void);
/**
   * 创建标签页面大小
   */
@property(nonatomic , readonly) BasicTSPL *(^page)(TPage *arg);
/**
  * 使能切刀
  *
  * @param enable true:使能 false:不使能
  * @return
  */
@property(nonatomic , readonly) BasicTSPL *(^cut)(BOOL enable);
/**
    * 设置浓度
    *
    * @param density 浓度值(0-15)
    * @return
    */
@property(nonatomic , readonly) BasicTSPL *(^density)(int density);

/**
   * 设置打印方向
   */
@property(nonatomic , readonly) BasicTSPL *(^direction)(TDirection *arg);
/**
  * 打印二维条码DATAMATRIX
  */
@property(nonatomic , readonly)BasicTSPL *(^dmatrix)(TDmatrix *arg);
/**
   * 打印图片
   */
@property(nonatomic , readonly)BasicTSPL *(^image)(TImage *arg);
/**
   * 打印标签
   */
@property(nonatomic , readonly)BasicTSPL *(^print)(void);
/**
   * 打印标签
   *
   * @param copies 打印份数
   * @return
   */
@property(nonatomic , readonly)BasicTSPL *(^printWithCopies)(int copies);
/**
   * 二维码
   */
@property(nonatomic , readonly)BasicTSPL *(^qrcode)(TQRCode *arg);
/**
   * 反色
   */
@property(nonatomic , readonly)BasicTSPL *(^reverse)(TReverse *arg);

/**
 * 查询状态
 */
@property(nonatomic , readonly)BasicTSPL *(^state)(void);

/**
  * 定位缝隙
  */

@property(nonatomic , readonly)BasicTSPL *(^gap)(BOOL enable);
/**
   * 查询SN
   */
@property(nonatomic , readonly)BasicTSPL *(^sn)(void);
/**
   * 设置速度
   *
   * @param speed 速度值 （范围1、1.5、2、2.5～6）,建议设置3～4区间
   * @return T
   */
@property(nonatomic , readonly)BasicTSPL *(^speed)(int speed);
/**
  * 打印文本
  */
@property(nonatomic , readonly)BasicTSPL *(^text)(TText *arg);

/**
 * 打印文本框
 */

@property(nonatomic , readonly)BasicTSPL *(^textBox)(TTextBox *arg);
/**
  * 查询版本
  */
@property(nonatomic , readonly)BasicTSPL *(^version)(void);

@property(nonatomic , readonly)BasicTSPL *(^mddle)(void);
/**
   * 清除位图
   */
@property(nonatomic , readonly)BasicTSPL *(^cleanFlash)(int index);
/**
   * 下载位图
   */
@property(nonatomic , readonly)BasicTSPL *(^downloadFlash)(int index, NSData *data);
/**
   * 下载位图
   */
@property(nonatomic , readonly)BasicTSPL *(^downloadFlashWithArg)(TDownloadBmpFlash *arg);
@end

NS_ASSUME_NONNULL_END
