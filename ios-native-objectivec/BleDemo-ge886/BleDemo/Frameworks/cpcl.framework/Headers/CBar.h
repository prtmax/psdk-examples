//
//  CBar.h
//  CPCL
//
//  Created by IPRT on 2022/10/7.
//

#import "BasicCPCLArg.h"
#import "CPCLCodeType.h"
#import "CPCLCodeRotation.h"
NS_ASSUME_NONNULL_BEGIN

/**
 * 一维条码
 */
@interface CBar : BasicCPCLArg

/// 条码起始x坐标
@property (nonatomic , readonly) CBar *(^x)(int startX);
/// 条码起始y坐标
@property (nonatomic , readonly) CBar *(^y)(int startY);
/// 条码内容
@property (nonatomic , readonly) CBar *(^content)(NSString *cnt);
/// 条码线宽度
@property (nonatomic , readonly) CBar *(^lineWidth)(int width);
/// 条码高度
@property (nonatomic , readonly) CBar *(^height)(int lineHeight);
/// 条码类型(默认CODE128)
@property (nonatomic , readonly) CBar *(^codeType)(CCodeType ct);
/// 条码旋转角度(默认不旋转)
@property (nonatomic , readonly) CBar *(^codeRotation)(CCodeRotation cr);

@end

NS_ASSUME_NONNULL_END
