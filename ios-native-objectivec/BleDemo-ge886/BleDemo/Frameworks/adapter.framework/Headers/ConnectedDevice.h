//
//  ConnectedDevice.h
//  adapter
//
//  Created by IPRT on 2022/10/24.
//

#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>
#import <CoreBluetooth/CBCharacteristic.h>
#import <adapter/ReadOptions.h>
#import <adapter/IPRTBlueToothBaseDef.h>
#import <adapter/WroteReporter.h>

NS_ASSUME_NONNULL_BEGIN
typedef enum _printResult {
    printResultSuccessful,//打印成功
    printResultFailed,//打印失败
    printResultInvalidDevice,
    printResultUnknow
}printResult;
typedef enum _printStatus{
    printResultCoverOpen,//纸舱盖打开
    printResultNoPaper,//缺纸
    printResultOverHeat,//打印头过热
    printResultPrinting,//打印中
    printResultBatteryLow,//低电压
    printResultOk,//正常
}printStatus;
@protocol ConnectedDeviceDelegate <NSObject>

/**
 * 打印机数据接收
 * @param revData  接收到的数据
 * 备注：在未进行查询动作的情况下：
 * 若打印最后发送了【printerPosition】则打印成功后会收到OK，不成功收到RE
 * 若打印最后未发送【printerPosition】则发送成功后会收到0xAA，不成功无返回
 */
- (void)bleDataReceived:(NSData *)revData;
/**
 * 搜索到打印机设备
 * @param peripheral  CBCentralManager通过扫描、连接的外围设备
 * @param RSSI  设备信号强度
 */
- (void)bleDidDiscoverDevies:(CBPeripheral *)peripheral RSSI:(nullable NSNumber *)RSSI;

/**
 * 打印机连接成功
 * @param peripheral  CBCentralManager通过扫描、连接的外围设备
 */
- (void)bleDidConnectPeripheral:(CBPeripheral *)peripheral;

@optional
/**
 *打印结束回调
 */
-(void)bleDidFinishPrint:(printResult)result;
-(void)printResultFailed;
/**
 *查询打印机状态回调
 */
-(void)blePrinterStatus:(printStatus)status;

- (void)didServicesFound:(nonnull CBPeripheral *)peripheral services:(nullable NSArray<CBService *> *)services;
/**
 * 搜索到打印机设备
 * @param peripheral  CBCentralManager通过扫描、连接的外围设备
 * @param RSSI  设备信号强度
 */

- (void)bleDidDiscoverDevies: (CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(nullable NSNumber *)RSSI;
/**
 * 打印机连接失败
 * @param peripheral  CBCentralManager通过扫描、连接的外围设备
 * @param error  错误信息
 */
- (void)bleDidFailToConnectPeripheral:(CBPeripheral *)peripheral error:(nullable NSError *)error;

/**
 * 打印机断开连接
 * @param peripheral  CBCentralManager通过扫描、连接的外围设备
 * @param error  错误信息
 */
- (void)bleDidDisconnectPeripheral:(CBPeripheral *)peripheral error:(nullable NSError *)error;
/**
 * 蓝牙打开
 */
- (void)bleBTOpen;
/**
 * 蓝牙断开
 */
- (void)bleBTClose;
/**
 * 蓝牙异常断开
 */
- (void)bleAbnormalDisconnection;
/**
 * 蓝牙开始升级
 */
- (void)startUpdateBt;
/**
 * 蓝牙升级失败
 */
- (void)updateBtFail;
/**
 * 蓝牙升级进度
 * @param progress 进度值
 */
- (void)updateBtProgress:(int)progress;
/**
 * 蓝牙升级结束
 */
- (void)updateBtFinish;

/**
 * 打印机开始升级
 */
- (void)startUpdatePrinter;
/**
 * 打印机升级失败
 */
- (void)updatePrinterFail;
/**
 * 打印机升级进度
 * @param progress 进度值
 */
- (void)updatePrinterProgress:(int)progress;
/**
 * 打印机升级结束
 */
- (void)updatePrinterFinish;
/**
 * 打印机自动返回缺纸
 */
- (void) onPrinterOutPaperAuto;
/**
 * 打印机自动返回开盖
 */
- (void) onPrinterOpenCoverAuto;
/**
 * 打印机自动返回过热
 */
- (void) onPrinterOverHeatAuto;
/**
 * 打印机自动返回低电压
 */
- (void) onPrinterLowValAuto;
/**
 * 打印机开启服务
 * @param result YES：开启成功 NO：开启失败
 */
- (void)didStart:(BOOL)result;

@end

@interface ConnectedDevice : NSObject

@property (nonatomic,assign)_Nullable id<ConnectedDeviceDelegate> delegate;
/**
 * 获取设备名称
 */
-(NSString *)deviceName;
/**
 * 写入数据
 * @param data 数据
 */
-(void)write:(NSData *)data;
/**
 * 读取数据
 * @param options options
 */
-(void)read:(ReadOptions *)options ;
/**
 * 获取连接状态
 */
-(ConnectionState)connectionState;
/**
 * 获取实例
 */
+ (ConnectedDevice *)sharedInstance;
/**
 * 开始扫描打印机设备
 */
-(void)startScanPrinters;
/**
 * 停止扫描打印机设备
 */
-(void)stopScanPrinters;
/**
 * 连接设备
 * @param peripheral 外设
 */
- (void)connect:(CBPeripheral*)peripheral;
/**
 * 断开连接
 * @param peripheral 外设
 */
- (void)disconnect:(CBPeripheral*)peripheral;
- (void)disconnect;
/**
 * 启动服务
 * @param serviceUUIDString 服务 uuid
 * @param peripheral 外设
 */
- (BOOL)start:(NSString *)serviceUUIDString on:(CBPeripheral *)peripheral;
-(NSString *)getNowTimeTimestamp;

@end

@interface NoneConnectedDevice : ConnectedDevice

@end
NS_ASSUME_NONNULL_END
