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

@interface TBarCode : BasicTSPLArg
@property (nonatomic , readonly) TBarCode *(^x)(int startX);
@property (nonatomic , readonly) TBarCode *(^y)(int startY);
@property (nonatomic , readonly) TBarCode *(^codeType)(TCodeType ctype);
@property (nonatomic , readonly) TBarCode *(^height)(int h);
@property (nonatomic , readonly) TBarCode *(^showType)(TShowType stype);
@property (nonatomic , readonly) TBarCode *(^rotation)(TRotation rot);
@property (nonatomic , readonly) TBarCode *(^cellwidth)(int width);
@property (nonatomic , readonly) TBarCode *(^content)(NSString * cnt);
@end

NS_ASSUME_NONNULL_END
