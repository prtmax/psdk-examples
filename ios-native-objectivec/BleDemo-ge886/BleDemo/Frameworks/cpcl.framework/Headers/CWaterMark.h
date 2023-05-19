//
//  CWaterMark.h
//  CPCL
//
//  Created by IPRT on 2022/10/10.
//

#import "BasicCPCLArg.h"

NS_ASSUME_NONNULL_BEGIN

/**
 * 水印
 */
@interface CWaterMark : BasicCPCLArg

/// 水印浓度
@property(nonatomic , readonly) CWaterMark *(^value)(int val);

@end

NS_ASSUME_NONNULL_END
