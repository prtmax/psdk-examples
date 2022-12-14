//
//  Lifecycle.h
//  father
//
//  Created by IPRT on 2022/11/8.
//

#import <Foundation/Foundation.h>
#import <adapter/ConnectedDevice.h>
#import <adapter/QueueConfig.h>
#import <father/PsdkConst.h>
NS_ASSUME_NONNULL_BEGIN

@interface Lifecycle : NSObject
@property(nonatomic , readonly)Lifecycle *(^connectedDevice)(ConnectedDevice *device);
@property(nonatomic , readonly)Lifecycle *(^enableAutoNewLine)(BOOL enable);
-(ConnectedDevice *)getConnectedDevice;
@property (nonatomic , strong)QueueConfig *queueConfig;
@end

NS_ASSUME_NONNULL_END
