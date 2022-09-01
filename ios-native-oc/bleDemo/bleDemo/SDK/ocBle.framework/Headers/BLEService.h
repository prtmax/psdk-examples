//
//  BLEHRService.h
//  iBridgeLib
//
//  Created by qiuwenqing on 15/11/17.
//  Copyright © 2015年 BRT. All rights reserved.
//

#import <Foundation/Foundation.h>

@class CBPeripheral;
@class CBService;
@class CBCharacteristic;
@class BLEHRMeasurement;

@interface BLEService : NSObject {
    @protected CBService *_service;
    @protected NSString *_serviceUUIDString;
}

#pragma mark - 公用方法

#pragma mark 启动服务
#pragma mark 在连接成功之后(didDisconnectPeripheral)才能调用
#pragma mark 会触发didStart
- (BOOL)start:(nonnull NSString *)serviceUUIDString on:(nonnull CBPeripheral *)peripheral;

#pragma mark 停止服务
- (void)stop;

#pragma mark 获取特征
- (nullable NSArray<CBCharacteristic *> *)getCharacteristics;

#pragma mark - 
- (void)peripheral:(nonnull CBPeripheral *)peripheral didDiscoverServices:(nullable NSError *)error;
- (void)peripheral:(nonnull CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(nullable CBService *)service error:(nullable NSError *)error;
- (void)peripheral:(nonnull CBPeripheral *)peripheral didUpdateValueForCharacteristic:(nullable CBCharacteristic *)characteristic error:(nullable NSError *)error;
- (void)peripheral:(nonnull CBPeripheral *)peripheral didWriteValueForCharacteristic:(nullable CBCharacteristic *)characteristic error:(nullable NSError *)error;

@end
