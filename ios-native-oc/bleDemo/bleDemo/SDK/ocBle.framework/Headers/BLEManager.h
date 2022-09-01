//
//  BLEManager.h
//  iBridgeLib
//
//  Created by Michael Zu on 12-11-14.
//  Copyright (c) 2012年 BRT. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>
#import <UIKit/UIKit.h>
#import "BLEService.h"
#import "BLEAdvertisementData.h"

#pragma mark - 通用宏定义

#define SERVICE_UUID_ALERT_NOTIFICATION    @"1811" //Alert Notification Service
#define SERVICE_UUID_AUTOMATION_IO    @"1815" //Automation IO

#define SERVICE_UUID_BATTERY    @"180F" //Battery Service
#define CHAR_UUID_BATTERY_LEVEL @"2A19" //Battery Level

#define SERVICE_UUID_BLOOD_PRESSURE    @"1810" //Blood Pressure
#define CHAR_UUID_BLOOD_PRESSURE_MEASUREMENT    @"2A35"
#define CHAR_UUID_INTERMEDIATE_CUFF_PRESSURE     @"2A36"
#define CHAR_UUID_BLOOD_PRESSURE_FEATURE        @"2A49"

#define SERVICE_UUID_BODY_COMPOSITION    @"181B" //Body Composition
#define SERVICE_UUID_BOND_MANAGEMENT    @"181E" //Bond Management
#define SERVICE_UUID_CONTINUOUS_GLUCOSE_MONITORING    @"181F" //Continuous Glucose Monitoring
#define SERVICE_UUID_CURRENT_TIME    @"1805" //Current Time Service
#define SERVICE_UUID_CYCLING_POWER    @"1818" //Cycling Power
#define SERVICE_UUID_CYCLING_SPEED_AND_CADENCE    @"1816" //Cycling Speed and Cadence
#define SERVICE_UUID_DEVICE_INFORMATION    @"180A" //Device Information
#define SERVICE_UUID_ENVIRONMENTAL_SENSING    @"181A" //Environmental Sensing
#define SERVICE_UUID_GENERIC_ACCESS    @"1800" //Generic Access
#define SERVICE_UUID_GENERIC_ATTRIBUTE    @"1801" //Generic Attribute
#define SERVICE_UUID_GLUCOSE    @"1808" //Glucose
#define SERVICE_UUID_HEALTH_THERMOMETER    @"1809" //Health Thermometer

#define SERVICE_UUID_HEART_RATE    @"180D" //Heart Rate
#define CHAR_UUID_HR_CONTROL_POINT  @"2A39"//Heart Rate Control Point
#define CHAR_UUID_HR_BODY_SENSOR_LOCATION   @"2A38" //Body Sensor Location
#define CHAR_UUID_HR_MEASUREMENT    @"2A37" //Heart Rate Measurement

#define SERVICE_UUID_HTTP_PROXY    @"1823" //HTTP Proxy
#define SERVICE_UUID_HUMAN_INTERFACE_DEVICE    @"1812" //Human Interface Device
#define SERVICE_UUID_IMMEDIDATE_ALERT    @"1802" //Immediate Alert
#define SERVICE_UUID_INDOOR_POSITIONING    @"1821" //Indoor Positioning
#define SERVICE_UUID_INTERNET_PROTOCOL_SUPPORT    @"1820" //Internet Protocol Support
#define SERVICE_UUID_LINK_LOSS    @"1803" //Link Loss
#define SERVICE_UUID_LOCATION_AND_NAVIGATION    @"1819" //Location and Navigation
#define SERVICE_UUID_NEXT_DST_CHANGE    @"1807" //Next DST Change Service
#define SERVICE_UUID_PHONE_ALERT_STATUS    @"180E" //Phone Alert Status Service
#define SERVICE_UUID_PLUSE_OXIMETER    @"1822" //Pulse Oximeter
#define SERVICE_UUID_PEFERENCE_TIME_UPDATE   @"1806" //Reference Time Update Service
#define SERVICE_UUID_RUNNING_SPEED_AND_CADENCE    @"1814" //Running Speed and Cadence
#define SERVICE_UUID_SCAN_PARAMETERS    @"1813" //Scan Parameters
#define SERVICE_UUID_TX_POWER    @"1804" //Tx Power
#define SERVICE_UUID_USER_DATA    @"181C" //User Data
#define SERVICE_UUID_WEIGHT_SCALE    @"181D" //Weight Scale

#define SERVICE_UUID_BRT_DATA_TRANSMISSION @"FF00"
#define CHAR_UUID_BRT_DT_NOTIFY @"FF01"
#define CHAR_UUID_BRT_DT_WRITE  @"FF02"
#define CHAR_UUID_BRT_DT_FLOW_CONTROL   @"FF03"

#define SERVICE_UUID_BRT_ATCMD @"FF80"
#define CHAR_UUID_BRT_ATCMD_NOTIFY @"FF81"
#define CHAR_UUID_BRT_ATCMD_WRITE  @"FF82"

#define SERVICE_UUID_BRT_PEDOMETER  @"FF01"
#define CHAR_UUID_BRT_PEDOMETER_NOTIFY @"FF01"

#define BLEMANAGER ((BLEManager *)[BLEManager sharedInstance])


@protocol BLEManagerDelegate <NSObject>

#pragma mark - BLEManagerDelegate

#pragma mark 蓝牙状态改变
- (void)didUpdateState:(CBCentralManagerState) state;

#pragma mark 发现设备
- (void)didPeripheralFound:(nonnull CBPeripheral *)peripheral advertisementData:(nullable BLEAdvertisementData *)advertisementData RSSI:(nullable NSNumber *)RSSI;

#pragma mark 连接成功
- (void)didConnectPeripheral:(nonnull CBPeripheral *)peripheral;

#pragma mark 连接失败
- (void)didFailToConnectPeripheral:(nonnull CBPeripheral *)peripheral error:(nullable NSError *)error;

#pragma mark 连接断开
- (void)didDisconnectPeripheral:(nonnull CBPeripheral *)peripheral error:(nullable NSError *)error;

#pragma mark 发现服务
- (void)didServicesFound:(nonnull CBPeripheral *)peripheral services:(nullable NSArray<CBService *> *)services;

@end

@interface BLEManager : NSObject

#pragma mark - 类属方法

#pragma mark 共用实例
+ (nonnull id)sharedInstance;

#pragma mark - 公用方法

#pragma mark 搜索
#pragma mark 搜索广播信息中有指定uuid的设备，如果uuidString/uuids为nil，则搜索所有的设备
- (void)scanForPeripherals:(nullable NSString *)uuidString;

#pragma mark 停止搜索
- (void)stopScan;

#pragma mark 连接设备
- (void)connect:(nonnull CBPeripheral*)peripheral;

#pragma mark 断开连接
- (void)disconnect:(nonnull CBPeripheral*)peripheral;

#pragma mark 获取服务
- (void)discoverServices:(nonnull CBPeripheral *)peripheral;

#pragma mark 获取之前搜索到的设备
#pragma mark identifiers:nil,返回最后一个连接的设备)
- (nullable NSArray<CBPeripheral *> *)retrievePeripheralsWithIdentifiers:(nullable NSArray<NSUUID *> *)identifiers;

#pragma mark - 辅助函数

#pragma mark 获取UUID的描述
- (nullable NSString *)getUuidDescription:(nonnull NSString *)uuidString;

#pragma mark 获取特征属性对应文字描述
- (nullable NSString *)getCharacteristicPropertyString:(CBCharacteristicProperties) properties;

#pragma mark - 公用属性

@property(weak,nonatomic) _Nullable id<BLEManagerDelegate> delegate;
@property(strong,nonatomic) NSMutableArray<BLEService *> *bleServices;

@end
