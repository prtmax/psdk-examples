//
//  CUnderLine.h
//  CPCL
//
//  Created by IPRT on 2022/10/10.
//

#import "BasicCPCLArg.h"

NS_ASSUME_NONNULL_BEGIN

/**
 * 下划线
 */
@interface CUnderLine : BasicCPCLArg

/// 是否加下划线(默认不加下划线)
@property(nonatomic , readonly) CUnderLine *(^underline)(BOOL isUnderline);

@end

NS_ASSUME_NONNULL_END
