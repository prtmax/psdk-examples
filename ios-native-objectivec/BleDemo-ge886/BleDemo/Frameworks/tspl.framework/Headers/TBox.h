//
//  TBox.h
//  TSPL
//
//  Created by IPRT on 2022/10/11.
//

#import <tspl/BasicTSPLArg.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * 打印边框
 */
@interface TBox : BasicTSPLArg

/// 左上角起始点 x 坐标
@property(nonatomic , readonly) TBox *(^startX)(int sx);
/// 左上角起始点 y 坐标
@property(nonatomic , readonly) TBox *(^startY)(int sy);
/// 右下角结束点 x 坐标
@property(nonatomic , readonly) TBox *(^endX)(int ex);
/// 右下角结束点 y 坐标
@property(nonatomic , readonly) TBox *(^endY)(int ey);
/// 线宽
@property(nonatomic , readonly) TBox *(^width)(int lineWidth);
/// 圆角半径
@property(nonatomic , readonly) TBox *(^radius)(int r);

@end

NS_ASSUME_NONNULL_END
