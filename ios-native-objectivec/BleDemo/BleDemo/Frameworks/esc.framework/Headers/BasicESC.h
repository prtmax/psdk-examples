//
//  BasicESC.h
//  esc
//
//  Created by IPRT on 2022/11/10.
//

#import <Foundation/Foundation.h>
#import<father/father.h>
#import <adapter/adapter.h>
#import <esc/esc.h>
NS_ASSUME_NONNULL_BEGIN

@interface BasicESC<T> : PSDK

@property(nonatomic , readonly) BasicESC *(^BasicESC)(Lifecycle *lifecycle,ESCPrinter printer);

-(ConnectedDevice *)getConnectedDevice;
-(ESCPrinter)getPrinter;

/**
 * 打印机信息
 *
*/
@property(nonatomic , readonly)BasicESC *(^printerInfo)(void);
- (T)queryPrinterInfo;

/**
   * 走纸命令
   *
   * @param dot 走纸点行
   */
@property(nonatomic , readonly) BasicESC *(^lineDot)(int dot);
-(T)lineDot:(int)dot;
/**
   * 回纸命令
   *
   * @param dot 走纸点行
   * @return T
   */
@property(nonatomic , readonly) BasicESC *(^backLineDot)(int dot);
-(T)backLineDot:(int)dot;

/**
 * 查询电量
 */
@property(nonatomic , readonly) BasicESC *(^batteryVolume)(void);

-(T)printerBatteryVolume;
/**
   * 使能打印机
   */
@property(nonatomic , readonly) BasicESC *(^enable)(void);
-(T)enablePrinter;

/**
 * 设置关机时间 (单位：分钟)
 */
@property(nonatomic , readonly)BasicESC *(^setShutdownTime)(int time);
-(T)setShutdownTime:(int)time;

/**
 * 获取关机时间(单位：分钟) , 返回两个字节，高位在前低位在后，单位为分钟
 */
@property(nonatomic , readonly) BasicESC *(^shutdownTime)(void);
-(T)getShutdownTime;

/**
   * 打印图片
   */
@property(nonatomic , readonly) BasicESC *(^image)(EImage * arg);
-(T)printImage:(EImage *)arg;
/**
   * 学习缝隙
   */
@property(nonatomic , readonly) BasicESC *(^learnGap)(void);
-(T)learnLabelGap;
/**
   * 画线
   */
@property(nonatomic , readonly) BasicESC *(^line)(ELine *arg);
-(T)line:(ELine *)arg;
/**
   * 设置打印起始横向位置
   *
   * @param location 0:居左 1:居中 2:居右
   */
@property(nonatomic , readonly) BasicESC *(^location)(int loc);
-(T)location:(int)location;
/**
   * 查询MAC
   */
@property(nonatomic , readonly) BasicESC *(^mac)(void);
-(T)queryMac;
/**
   * 查询打印机型号
   */
@property(nonatomic , readonly)BasicESC *(^model)(void);
-(T)queryModel;
/**
 * 查询蓝牙名称
 */
@property(nonatomic , readonly)BasicESC *(^name)(void);
-(T)queryName;
/**
   * 纸张类型
   */
@property(nonatomic , readonly)BasicESC *(^paperType)(EPaperType *arg);
-(T)paperType:(EPaperType *)arg;
/**
   * 打印定位
   */
@property(nonatomic , readonly)BasicESC *(^position)(void);
-(T)printePosition;
/**
  * 查询打印机固件版本
  */
@property(nonatomic , readonly)BasicESC *(^printerVersion)(void);
-(T)queryPrinterVersion;

/**
   * 查询SN
   */
@property(nonatomic , readonly)BasicESC *(^sn)(void);

-(T)querySn;
/**
   * 查询打印机状态
   */

@property(nonatomic , readonly)BasicESC *(^state)(void);

-(T)queryState;
/**
   * 结束打印任务
   */

@property(nonatomic , readonly)BasicESC *(^stopJob)(void);
-(T)printerStopJob;
/**
   * 设置打印机浓度(0-2)
   *
   * @param thickness 0:低浓度 1:中浓度 2:高浓度
   */

@property(nonatomic , readonly)BasicESC *(^thickness)(int thick);
-(T)thickness:(int)thickness;
/**
   * 查询蓝牙固件版本
   */

@property(nonatomic , readonly)BasicESC *(^version)(void);
-(T)bleVersion;
/**
   * 唤醒打印机
   */

@property(nonatomic , readonly)BasicESC *(^wakeup)(void);
-(T)printerWakeup;
@end

NS_ASSUME_NONNULL_END
