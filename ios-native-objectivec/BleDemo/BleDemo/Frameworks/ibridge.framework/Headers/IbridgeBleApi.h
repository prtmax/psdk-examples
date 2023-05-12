//
//  Bluetooth.h
//  IBridgeLibBluetooth
//
//  Created by IPRT on 2022/10/21.
//

#import <Foundation/Foundation.h>
#import <adapter/ConnectedDevice.h>

NS_ASSUME_NONNULL_BEGIN

@protocol IbridgeBleApiInterfaceDelegate <ConnectedDeviceDelegate>

@end

@interface IbridgeBleApi : ConnectedDevice

@property (nonatomic,assign)_Nullable id<IbridgeBleApiInterfaceDelegate> delegate;

@end

NS_ASSUME_NONNULL_END
