//
//  CPCL1.h
//  cpcl
//
//  Created by IPRT on 2022/11/19.
//

#import <Foundation/Foundation.h>
#import "GenericCPCL.h"
NS_ASSUME_NONNULL_BEGIN

@interface CPCL_ : NSObject
@property(nonatomic , readonly) GenericCPCL *(^genericWithConnectedDevice)(ConnectedDevice *connectedDevice);
@property(nonatomic , readonly) GenericCPCL *(^genericWithLifecycle)(Lifecycle *lifecycle);
@end

NS_ASSUME_NONNULL_END
