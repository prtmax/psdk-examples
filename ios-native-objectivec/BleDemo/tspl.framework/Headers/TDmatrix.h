//
//  TDmatrix.h
//  TSPL
//
//  Created by IPRT on 2022/10/12.
//

#import <tspl/BasicTSPLArg.h>
NS_ASSUME_NONNULL_BEGIN

/**
 *  二维条码
 */
@interface TDmatrix : BasicTSPLArg

/// 起始x坐标
@property(nonatomic , readonly) TDmatrix *(^x)(int startX);
/// 起始y坐标
@property(nonatomic , readonly) TDmatrix *(^y)(int startY);
/// 条码宽度
@property(nonatomic , readonly) TDmatrix *(^width)(int lineWidth);
/// 条码高度
@property(nonatomic , readonly) TDmatrix *(^height)(int lineHight);
/// 条码内容
@property(nonatomic , readonly) TDmatrix *(^content)(NSString *cnt);

@end

NS_ASSUME_NONNULL_END
