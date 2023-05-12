//
//  TBar.h
//  TSPL
//
//  Created by IPRT on 2022/10/11.
//

#import <tspl/BasicTSPLArg.h>
#import <tspl/TSPLLineType.h>
NS_ASSUME_NONNULL_BEGIN

/**
 * 画线
 */
@interface TBar : BasicTSPLArg

/// 起始x坐标
@property(nonatomic , readonly) TBar *(^x)(int startX);
/// 起始y坐标
@property(nonatomic , readonly) TBar *(^y)(int startY);
/// 线宽
@property(nonatomic , readonly) TBar *(^width)(int lineWidth);
/// 线高
@property(nonatomic , readonly) TBar *(^height)(int lineHeight);
/// 线框类型: 实线 或 虚线:(默认实线)
@property(nonatomic , readonly) TBar *(^lineType)(TLineType l);

@end

NS_ASSUME_NONNULL_END
