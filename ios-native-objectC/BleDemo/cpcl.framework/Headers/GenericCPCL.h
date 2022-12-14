//
//  GenericCPCL.h
//  cpcl
//
//  Created by IPRT on 2022/11/19.
//

#import "BasicCPCL.h"

NS_ASSUME_NONNULL_BEGIN

@interface GenericCPCL : BasicCPCL
@property(nonatomic , readonly) GenericCPCL *(^GenericCPCL)(Lifecycle *lifecycle);
@end

NS_ASSUME_NONNULL_END
