//
//  CWaterMark.h
//  CPCL
//
//  Created by IPRT on 2022/10/10.
//

#import "BasicCPCLArg.h"

NS_ASSUME_NONNULL_BEGIN

@interface CWaterMark : BasicCPCLArg
@property(nonatomic , readonly) CWaterMark *(^value)(int val);
@end

NS_ASSUME_NONNULL_END
