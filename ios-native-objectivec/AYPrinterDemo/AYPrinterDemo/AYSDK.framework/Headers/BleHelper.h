//
//  BleHelper.h
//  AYSDK
//
//  Created by aiyin on 2023/9/12.
//

#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>
#import <AYSDK/AYPrinter.h>
#import <AYSDK/ETypes.h>
#import <AYSDK/TTypes.h>

#define BlueManager [BleHelper shareInstance]

typedef NS_ENUM(NSInteger, BleState) {
    BleStateDisconnected,
    BleStateConnected,
    BleStateFailToConnect
};

typedef void(^OnEscQueryChange)(EQuery type, NSData *data);
typedef void(^OnEscSettingChange)(ESet type, NSData *data);
typedef void(^onTsplDataReceived)(TReceivedType type, NSData *data);
typedef void(^OnDataReceived)(NSData *data);

@protocol BleHelperDelegate <NSObject>

@optional
- (void)bleHelperDidUpdateState:(CBManagerState)state;

- (void)bleHelperDiscoverPeripheral:(AYPrinter *)printer;

- (void)bleHelperDidChangeConnectState:(BleState)state peripheral:(CBPeripheral *)peripheral;

@end

@interface BleHelper : NSObject

@property(assign, nonatomic) BleState state;
@property(weak, nonatomic) id<BleHelperDelegate> delegate;
/// 打印机回调 - 接收所有打印机数据返回
@property(copy, nonatomic) OnDataReceived onDataReceived;
/// esc 查询回调 - 只接收 esc 查询数据返回
@property(copy, nonatomic) OnEscQueryChange escQueryChange;
/// esc 设置回调 - 只接收 esc 设置数据返回
@property(copy, nonatomic) OnEscSettingChange escSettingChange;
/// 打印成功回调 - 只接收打印成功返回
@property(copy, nonatomic) OnDataReceived onPrintSuccess;
/// 打印主动上报回调 - 只接收打印主动上报返回
@property(copy, nonatomic) OnDataReceived onPrinterAutoReport;
/// 打印主动上报回调 - tspl反馈
@property(copy, nonatomic) onTsplDataReceived onTsplDataReceived;

+ (instancetype)shareInstance;

- (void)startScan;

- (void)stopScan;

- (void)connect:(AYPrinter *)printer;

- (void)disconnect;

- (void)writeCommands:(NSMutableArray<NSData *> *)commands;

@end

//NS_ASSUME_NONNULL_END
