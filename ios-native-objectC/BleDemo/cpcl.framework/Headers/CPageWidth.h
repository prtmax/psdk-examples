//
//  CPageWidth.h
//  CPCL
//
//  Created by IPRT on 2022/10/10.
//

#import "BasicCPCLArg.h"

NS_ASSUME_NONNULL_BEGIN

@interface CPageWidth : BasicCPCLArg
@property(nonatomic , readonly) CPageWidth *(^pageWidth)(int cpageWidth);
@end

NS_ASSUME_NONNULL_END
