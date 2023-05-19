//
//  TBarCode.h
//  TSPL
//
//  Created by IPRT on 2022/10/11.
//

#import <tspl/BasicTSPLArg.h>
#import <tspl/TSPLCodeType.h>
#import <tspl/TSPLShowType.h>
#import <tspl/TSPLRotation.h>
NS_ASSUME_NONNULL_BEGIN

/**
 * 打印一维条码
 */
@interface TBarCode : BasicTSPLArg

/**
 * 条码起始x坐标
 */
@property (nonatomic , readonly) TBarCode *(^x)(int startX);
/**
 * 条码起始y坐标
 */
@property (nonatomic , readonly) TBarCode *(^y)(int startY);
/**
 * 条码类型(默认CODE128)
 */
@property (nonatomic , readonly) TBarCode *(^codeType)(TCodeType ctype);
/**
 * 条码高度
 */
@property (nonatomic , readonly) TBarCode *(^height)(int h);
/**
 * 文字显示方式(默认不显示)
 */
@property (nonatomic , readonly) TBarCode *(^showType)(TShowType stype);
/**
 * 条码旋转角度(默认不旋转)
 */
@property (nonatomic , readonly) TBarCode *(^rotation)(TRotation rot);
/**
 * 条码线宽度
 */
@property (nonatomic , readonly) TBarCode *(^cellwidth)(int width);
/**
 * 条码内容
 */
@property (nonatomic , readonly) TBarCode *(^content)(NSString * cnt);

@end

NS_ASSUME_NONNULL_END
