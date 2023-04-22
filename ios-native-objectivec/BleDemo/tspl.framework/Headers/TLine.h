//
//  TLine.h
//  TSPL
//
//  Created by IPRT on 2022/10/12.
//

#import <tspl/BasicTSPLArg.h>
#import "TSPLLineMode.h"
NS_ASSUME_NONNULL_BEGIN

/**
 * 画线
 */
@interface TLine : BasicTSPLArg

/// 起始x坐标
@property (nonatomic , readonly) TLine *(^start_x)(int startx);
/// 起始y坐标
@property (nonatomic , readonly) TLine *(^start_y)(int starty);
/// 结束x坐标
@property (nonatomic , readonly) TLine *(^end_x)(int endx);
/// 结束y坐标
@property (nonatomic , readonly) TLine *(^end_y)(int endy);
/// 线宽
@property (nonatomic , readonly) TLine *(^width)(int lineWidth);
///  线高
@property (nonatomic , readonly) TLine *(^height)(int lineHeight);
/// 实线/虚线 0-实线；1-4虚线
@property (nonatomic , readonly) TLine *(^lineMode)(TLineMode l);

@end

NS_ASSUME_NONNULL_END
