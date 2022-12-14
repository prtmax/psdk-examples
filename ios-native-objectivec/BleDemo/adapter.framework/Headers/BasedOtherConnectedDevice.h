//
//  BasedOtherConnectedDevice.h
//  adapter
//
//  Created by IPRT on 2022/11/10.
//

#import <adapter/ConnectedDevice.h>

NS_ASSUME_NONNULL_BEGIN

@interface BasedOtherConnectedDevice : ConnectedDevice
@property (nonatomic , readonly) BasedOtherConnectedDevice *(^connectedDevice)(ConnectedDevice *device);

@end

NS_ASSUME_NONNULL_END
