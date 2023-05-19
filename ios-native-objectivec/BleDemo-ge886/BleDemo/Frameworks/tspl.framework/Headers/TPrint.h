//
//  TPrint.h
//  TSPL
//
//  Created by IPRT on 2022/10/12.
//
#import <tspl/BasicTSPLArg.h>
NS_ASSUME_NONNULL_BEGIN

/**
 * 打印份数
 */

@interface TPrint : BasicTSPLArg

/// 打印份数
@property (nonatomic , readonly) TPrint *(^copies)(int copyCount);

@end

NS_ASSUME_NONNULL_END
