//
//  CQRCode.h
//  CPCL
//
//  Created by IPRT on 2022/10/10.
//

#import "BasicCPCLArg.h"
#import "CPCLCodeRotation.h"
#import "CPCLCorrectLevel.h"
NS_ASSUME_NONNULL_BEGIN

/**
 * 二维条码
 */
@interface CQRCode : BasicCPCLArg

/// 二维码起始x坐标
@property (nonatomic , readonly) CQRCode *(^x)(int cx);
/// 二维码起始y坐标
@property (nonatomic , readonly) CQRCode *(^y)(int cy);
/// 二维码内容
@property (nonatomic , readonly) CQRCode *(^content)(id ccontent);
/// 二维码旋转角度(默认不旋转)
@property (nonatomic , readonly) CQRCode *(^codeRotation)(CCodeRotation ccodeRotation);
/// 二维码小黑点宽度(2-20)
@property (nonatomic , readonly) CQRCode *(^width)(int cWidth);
/// 二维码纠错等级(默认L)
@property (nonatomic , readonly) CQRCode *(^level)(CCorrectLevel cLevel);

@end

NS_ASSUME_NONNULL_END
