//
//  EBackLineDot.h
//  ESC
//
//  Created by IPRT on 2022/10/11.
//

#import "BasicESCArg.h"

NS_ASSUME_NONNULL_BEGIN

/**
 * 回退纸张命令
 */
@interface EBackLineDot : BasicESCArg

/// 走纸行数
@property (nonatomic, readonly)EBackLineDot *(^dot)(int d);

@end

NS_ASSUME_NONNULL_END
