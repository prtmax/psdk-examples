//
//  Bluetooth.h
//  FSCBluetooth
//
//  Created by IPRT on 2022/10/20.
//

#import <Foundation/Foundation.h>
#import <adapter/ConnectedDevice.h>

NS_ASSUME_NONNULL_BEGIN
@protocol FscBleApiInterfaceDelegate <ConnectedDeviceDelegate>
@end
@interface FscBleApi : ConnectedDevice
-(void)send:(NSData *)data SendStatusBlock:(void (^)(NSData *data))block;
@end

NS_ASSUME_NONNULL_END
