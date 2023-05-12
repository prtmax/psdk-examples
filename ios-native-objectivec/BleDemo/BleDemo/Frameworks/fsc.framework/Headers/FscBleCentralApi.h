//
//  FscBleCentralApi.h
//  FscBleCentral
//
//  Created by Feasycom on 2017/12/26.
//  Copyright © 2017 Feasycom. All rights reserved.
//

typedef enum {
    BLEMODULE = 0,  // ble type
    BEACONMODULE    // beacon type
} MODULETYPE;

// Release Date: 2019-9-29

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>
@class FWPeripheralWrapper;
@class BeaconBean;

@interface FscBleCentralApi : NSObject
/**
 *  Module type
 */
@property (nonatomic, assign) MODULETYPE moduleType;
/**
 *  Last connected peripheral
 */
@property (nonatomic, strong) CBPeripheral *peripheral;
/**
 *  BroadCast info
 */
@property (nonatomic, strong) NSArray <FWPeripheralWrapper *>*broadCastInfoArray;
/**
 *  Beacon info
 */
@property (nonatomic, strong) NSArray *beaconInfoArray;
/**
 *  Peripherals info
 */
@property (nonatomic, strong) NSArray *peripheralsInfoArray;

//-----------------------------------  callbacks  -------------------------------------//
/**
 * peripheral enabled callback
 */
- (void)isBtEnabled:(void (^)(CBCentralManager *central))block;
/**
 * peripheral found callback
 */
- (void)blePeripheralFound:(void (^)(CBCentralManager *central,CBPeripheral *peripheral,NSDictionary *advertisementData, NSNumber *RSSI))block;
/**
 * peripheral connected callback
 */
- (void)blePeripheralConnected:(void (^)(CBCentralManager *central,CBPeripheral *peripheral))block;
/**
 *  discover services
 */
- (void)servicesFound:(void (^)(NSArray <CBService *>*services,NSError *error))block;
/**
 *  peripheral disconnected callback
 */
- (void)blePeripheralDisonnected:(void (^)(CBCentralManager *central,CBPeripheral *peripheral,NSError *error))block;
/**
 * write value with response callback
 */
- (void)sendCompleted:(void (^)(CBCharacteristic *characteristic,NSData *data,NSError *error))block;
/**
 * received packet callback
 */
- (void)packetReceived:(void (^)(CBPeripheral *peripheral,NSData *data,NSError *error))block;
/**
 * response for characteristic value read
 */
- (void)readResponse:(void (^)(CBCharacteristic * characteristic))block;
/**
 * response for send AT commands
 */
- (void)fscAtResponse:(void (^)(NSString *type,int status))block;
/**
 * update progress callbacks
 */
- (void)otaProgressUpdate:(void (^)(CGFloat percentage,int status))block;
/**
 * device info callbacks
 */
- (void)deviceInfo:(void (^)(NSArray *infoArray))block;

/**
 * write ready
 */
- (void)peripheralWriteDidReady:(void (^)(void))block;


/**
 * single_one
 */
+ (instancetype)shareFscBleCentralApi;
/**
 * single_two
 */
+ (instancetype)defaultFscBleCentralApi;
/**
 * SDK version
 */
+ (NSString *)SDKVersion;
/**
 * start scan peripherals
 */
- (void)startScan;
/**
 * stop scan peripherals
 */
- (void)stopScan;
/**
 * connect peripheral(BLE)
 */
- (void)connect:(CBPeripheral *)peripheral;

- (void)discoverServices;
/**
 * connect peripheral(beacon)
 */
- (void)connect:(FWPeripheralWrapper *)peripheralWrapper withPin:(NSString *)pin;
/**
 * disconnect peripheral
 */
- (void)disconnect;
/**
 * send data to peripheral, response is flow control
 */
- (void)send:(NSData *)data withResponse:(BOOL)response withSendStatusBlock:(void (^)(NSData *data))block;
/**
 * send data to peripheral, response is flow control(sync)
 */
- (void)syncSend:(NSData *)data withResponse:(BOOL)response;
/**
 * stop send data to peripheral and reset sending status
 */
- (void)stopSend;
/**
 * if YES, start the facp, the default is NO
 */
- (void)facpControl:(BOOL)control;

/**
 * set characteristic
 */
- (void)setCharacteristic:(NSString *)serviceUUID withCharacteristicUUID:(NSString *)characteristicUUID withNotify:(BOOL)notify infoBlock:(void (^)(BOOL result))block;
/**
 * read characteristic value
 */
- (void)read:(CBCharacteristic *)characteristic;
/**
 * set send interval(ms)
 */
- (void)setSendInterval:(NSInteger)interval;
/**
 * clear buffer cache
 */
- (void)clearCache;
/**
 * set mtu
 */
- (void)setAttMtu:(NSInteger)mtu;
/**
 * restore mtu
 */
- (void)restoreMtu;
/**
 * send AT commands
 */
- (void)sendFscAtCommands:(NSArray *)commandArray;
/**
 * load file and check file information
 */
- (NSDictionary *)checkDfuFile:(NSString *)dfuFileName;
/**
 * upgrade and restore default settings
 */
- (void)startOTA:(NSString *)dfuFileName withRestoreDefaultSettings:(BOOL)restore;

//----------------------------------  beacon  ------------------------------------------//
/**
 * get device info, also see "deviceInfo:"
 */
- (void)startGetDeviceInfo;
/**
 * set device name
 */
- (void)setDeviceName:(NSString *)deviceName;
/**
 * set feasyBeacon pin
 */
- (void)setFscPin:(NSString *)pin;
/**
 * set broadcast interval
 */
- (void)setBroadcastInterval:(NSString *)interval;
/**
 * set tx power
 */
- (void)setTxPower:(NSString *)txPower;
/**
 * set connectable or not
 */
- (void)setConnectable:(BOOL)connectable;
/**
 * add beacon broadcast
 */
- (void)addBeaconInfo:(BeaconBean *)beaconBean;
/**
 * delete beacon broadcast of index
 */
- (void)deleteBeaconInfo:(uint32_t)index;
/**
 * update beacon info of index
 */
- (void)updateBeaconInfo:(BeaconBean *)beaconBean withIndex:(uint32_t)index withPosition:(uint32_t)position;
/**
 * get beacon info of index
 */
- (BeaconBean *)getBeaconInfo:(uint32_t)index;

- (void)saveBeaconInfo;


@end

