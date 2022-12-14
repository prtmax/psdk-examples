//
//  TBox.h
//  TSPL
//
//  Created by IPRT on 2022/10/11.
//

#import <tspl/BasicTSPLArg.h>

NS_ASSUME_NONNULL_BEGIN

@interface TBox : BasicTSPLArg
/**
   * 起始x坐标
   */
@property(nonatomic , readonly) TBox *(^startX)(int sx);
/**
   * 起始y坐标
   */
@property(nonatomic , readonly) TBox *(^startY)(int sy);
/**
   * 结束x坐标
   */
@property(nonatomic , readonly) TBox *(^endX)(int ex);
/**
   * 结束y坐标
   */
@property(nonatomic , readonly) TBox *(^endY)(int ey);
/**
   * 线宽
   */
@property(nonatomic , readonly) TBox *(^width)(int lineWidth);
/**
   * 线高
   */
@property(nonatomic , readonly) TBox *(^radius)(int r);
@end

NS_ASSUME_NONNULL_END
