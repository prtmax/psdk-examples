//
//  TPage.h
//  TSPL
//
//  Created by IPRT on 2022/10/12.
//
#import <tspl/BasicTSPLArg.h>
NS_ASSUME_NONNULL_BEGIN

/**
 * 创建标签页面
 */
@interface TPage : BasicTSPLArg

/// 标签宽度,单位 mm
@property (nonatomic , readonly) TPage *(^width)(int width);
/// 标签高度,单位 mm
@property (nonatomic , readonly) TPage *(^height)(int height);

@end

NS_ASSUME_NONNULL_END
