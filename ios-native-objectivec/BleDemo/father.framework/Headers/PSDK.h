//
//  PSDK.h
//  father
//
//  Created by IPRT on 2022/11/8.
//

#import <Foundation/Foundation.h>
#import <adapter/ConnectedDevice.h>
#import <father/Command.h>
#import <father/Commander.h>
#import <father/PsdkConst.h>
#import <father/WriteOptions.h>
#import <father/Raw.h>
NS_ASSUME_NONNULL_BEGIN
typedef void (^DiscoverBle)(CBPeripheral* peripheral, NSNumber *RSSI);
typedef void (^DidConnectPeripheral)(CBPeripheral* peripheral);
typedef void (^DidConnectPeripheral)(CBPeripheral* peripheral);
typedef void (^DidFailToConnectPeripheral)(CBPeripheral* peripheral,NSError *error);
typedef void (^DidDisconnectPeripheral)(CBPeripheral* peripheral,NSError *error);
typedef void (^DidStart)(BOOL result);
@interface PSDK : NSObject
-(ConnectedDevice *)connectedDevice;
-(NSString *)sversion;
-(NSArray *)authors;
@property(nonatomic , readonly)PSDK *(^raw)(Raw*r);
@property(nonatomic , readonly)PSDK *(^variable)(NSString *name, id value);
-(Command *)command;
@property(nonatomic , readonly)PSDK *(^clear)(void);
@property(nonatomic , copy)ReceivedData read;
@property (nonatomic ,readonly)WroteReporter *(^write)(void);
-(WroteReporter *)write:(WriteOptions *)options;
@property(nonatomic , copy) DiscoverBle discoverBle;
@property(nonatomic , copy) DidConnectPeripheral bleDidConnectPeripheral;
@property(nonatomic , copy) DidFailToConnectPeripheral bleDidFailToConnectPeripheral;
@property(nonatomic , copy) DidDisconnectPeripheral bleDidDisconnectPeripheral;
@property(nonatomic , copy) DidStart didStart;
@property(nonatomic , readonly)PSDK *(^pushArg)(Arg *arg);
@property(nonatomic , readonly)PSDK *(^pushArgs)(NSArray<Arg *>*args);
-(void)pushArg:(Arg *)arg;
-(Commander *)commander;
/**
 * 开始扫描打印机设备
 */
-(void)startScanPrinters;
/**
 * 停止扫描打印机设备
 */
-(void)stopScanPrinters;
-(void)read:(ReadOptions *)options;
//@property(nonatomic , readonly)PSDK *(^line)(LineArg *arg);
//@property(nonatomic , readonly)PSDK *(^batteryVolume)(BatteryArg * arg);
@end

NS_ASSUME_NONNULL_END
