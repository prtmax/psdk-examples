//
//  KeepStateConnectedDevice.h
//  adapter
//
//  Created by IPRT on 2022/11/10.
//

#import "BasedOtherConnectedDevice.h"
#import "QueueConfig.h"
NS_ASSUME_NONNULL_BEGIN

@interface KeepStateConnectedDevice : BasedOtherConnectedDevice
-(instancetype)initWithConfig:(QueueConfig *)config :(ConnectedDevice *)connectedDevice;
-(ConnectedDevice *)raw;
-(void)disconnect;
@end

NS_ASSUME_NONNULL_END
