//
//  CMag.h
//  CPCL
//
//  Created by IPRT on 2022/10/10.
//

#import "BasicCPCLArg.h"
#import "CPCLFont.h"
NS_ASSUME_NONNULL_BEGIN

/**
 * 可将内置字体放大指定的放大倍数
 */
@interface CMag : BasicCPCLArg

/// 字体(默认TSS16)
@property (nonatomic , readonly) CMag *(^font)(CFont fnt);

@end

NS_ASSUME_NONNULL_END
