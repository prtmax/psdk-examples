//
//  TSpeed.h
//  TSPL
//
//  Created by IPRT on 2022/10/12.
//
#import <tspl/BasicTSPLArg.h>
NS_ASSUME_NONNULL_BEGIN

/**
 * 打印速度
 */
@interface TSpeed : BasicTSPLArg

/// 速度
@property (nonatomic , readonly) TSpeed *(^speed)(int s);

@end

NS_ASSUME_NONNULL_END
