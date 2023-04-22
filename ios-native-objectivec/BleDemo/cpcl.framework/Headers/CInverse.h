//
//  CInverse.h
//  CPCL
//
//  Created by IPRT on 2022/10/10.
//

#import "BasicCPCLArg.h"
#import "CPCLFont.h"
#import "CPCLRotation.h"
NS_ASSUME_NONNULL_BEGIN

/**
 * 反色
 */
@interface CInverse : BasicCPCLArg

/// 文字反色起始x坐标
@property (nonatomic, readonly) CInverse *(^x)(int X);
/// 文字反色起始y坐标
@property (nonatomic, readonly) CInverse *(^y)(int Y);
/// 反色文字字体
@property (nonatomic, readonly) CInverse *(^Fnt)(CFont font);
/// 文本内容
@property (nonatomic, readonly) CInverse *(^content)(id conten);
/// 旋转角度(默认不旋转)
@property (nonatomic, readonly) CInverse *(^rotation)(CRotation InRotation);

@end

NS_ASSUME_NONNULL_END
