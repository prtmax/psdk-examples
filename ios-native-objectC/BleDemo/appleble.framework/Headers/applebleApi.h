//
//  applebleApi.h
//  appleble
//
//  Created by IPRT on 2022/11/28.
//

#import <adapter/ConnectedDevice.h>
#import "ProviderOptions.h"
NS_ASSUME_NONNULL_BEGIN
typedef enum _printerStateBy {
    printerStatePoweredOffBy,//蓝牙关闭
    printerStatePoweredOnBy//蓝牙打开
}printerStateBy;
@protocol applebleApiDelegate <ConnectedDeviceDelegate>
@optional
- (void)bleDidUpdateStateBy:(printerStateBy)state;
@end
@interface applebleApi : ConnectedDevice
@property (nonatomic,assign)_Nullable id<applebleApiDelegate> delegate;

-(instancetype)init:(ProviderOptions *)options;
@property (nonatomic , strong) NSString *UUIDString;

@end

NS_ASSUME_NONNULL_END
