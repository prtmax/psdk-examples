//
//  BLEGATTService.h
//  iBridgeLib
//
//  Created by Michael Zu on 12-11-14.
//  Copyright (c) 2012年 BRT. All rights reserved.
//

#import "BLEService.h"
#import <CoreBluetooth/CBCharacteristic.h>
@class CBPeripheral;
@class CBCharacteristic;
@class BLEGATTService;

@protocol BLEGATTServiceDelegate <NSObject>

#pragma mark - BLEGATTServiceDelegate

#pragma mark 启动服务的结果,调用start之后会产生此事件
- (void)bleGattService:(nonnull BLEGATTService *)bleGattService didStart:(BOOL)result;

#pragma mark 是否可发送，以及可发送的字节数
- (void)bleGattService:(nonnull BLEGATTService *)bleGattService didFlowControl:(int)credit withMtu:(int)mtu;

#pragma mark 数据接收
- (void)bleGattService:(nonnull BLEGATTService *)bleGattService didDataReceived:(nonnull NSData *)revData;

@end

@interface BLEGATTService : BLEService

#pragma mark - 公用方法

#pragma mark 数据发送
- (void)write:(nonnull NSData *)data withResponse:(BOOL)withResponse;

#pragma mark 获取特征
- (nullable NSArray<CBCharacteristic *> *)getCharacteristics;

#pragma mark - 公用属性
@property(weak,nonatomic)_Nullable id<BLEGATTServiceDelegate> delegate;
@property(assign,nonatomic) CBCharacteristicProperties writeCharacteristicProperties;

@end
