//
//  CBlod.h
//  CPCL
//
//  Created by IPRT on 2022/10/10.
//

#import "BasicCPCLArg.h"

NS_ASSUME_NONNULL_BEGIN

@interface CBold : BasicCPCLArg
@property (nonatomic, readonly) CBold *(^bold)(BOOL isBold);
@end

NS_ASSUME_NONNULL_END
