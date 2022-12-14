//
//  TCircle.h
//  TSPL
//
//  Created by IPRT on 2022/10/12.
//

#import <tspl/BasicTSPLArg.h>
NS_ASSUME_NONNULL_BEGIN

@interface TCircle : BasicTSPLArg

/**
   * 起始x坐标
   */
@property(nonatomic , readonly) TCircle *(^startX)(int sx);
/**
   * 起始y坐标
   */
@property(nonatomic , readonly) TCircle *(^startY)(int sy);
/**
   * 线宽
   */
@property(nonatomic , readonly) TCircle *(^width)(int lineWidth);
/**
   * 线高
   */
@property(nonatomic , readonly) TCircle *(^radius)(int r);
@end

NS_ASSUME_NONNULL_END
