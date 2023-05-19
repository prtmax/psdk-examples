//
//  TReverse.h
//  TSPL
//
//  Created by IPRT on 2022/10/12.
//

#import <tspl/BasicTSPLArg.h>
NS_ASSUME_NONNULL_BEGIN

/**
 * 反色
 */
@interface TReverse : BasicTSPLArg

/// 反色区域起始x坐标
@property (nonatomic , readonly) TReverse *(^x)(int startX);
/// 反色区域起始y坐标
@property (nonatomic , readonly) TReverse *(^y)(int startY);
/// 反色区域高度
@property (nonatomic , readonly) TReverse *(^height)(int h);
/// 反色区域宽度
@property (nonatomic , readonly) TReverse *(^width)(int w);

@end

NS_ASSUME_NONNULL_END
