//
//  CPageWidth.h
//  CPCL
//
//  Created by IPRT on 2022/10/10.
//

#import "BasicCPCLArg.h"

NS_ASSUME_NONNULL_BEGIN
/**
 * 设置打印纸张宽度（打印区域）的宽度
 */
@interface CPageWidth : BasicCPCLArg

/// 打印区域宽度
@property(nonatomic , readonly) CPageWidth *(^pageWidth)(int cpageWidth);

@end

NS_ASSUME_NONNULL_END
