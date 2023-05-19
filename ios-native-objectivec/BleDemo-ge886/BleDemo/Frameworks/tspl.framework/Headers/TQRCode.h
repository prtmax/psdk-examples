//
//  TQRCode.h
//  TSPL
//
//  Created by IPRT on 2022/10/12.
//

#import <tspl/BasicTSPLArg.h>
#import "TSPLCorrectLevel.h"
#import "TSPLRotation.h"
NS_ASSUME_NONNULL_BEGIN

/**
 * 二维条码
 */
@interface TQRCode : BasicTSPLArg

/// 起始x坐标
@property (nonatomic , readonly) TQRCode *(^x)(int startX);
/// 起始y坐标
@property (nonatomic , readonly) TQRCode *(^y)(int startY);
/// 单元宽度
@property (nonatomic , readonly) TQRCode *(^cellWidth)(int cWidth);
/// 纠错等级
@property (nonatomic , readonly) TQRCode *(^correctLevel)(TCorrectLevel clevel);
/// 旋转角度
@property (nonatomic , readonly) TQRCode *(^rotation)(TRotation rot);
/// 条码内容
@property (nonatomic , readonly) TQRCode *(^content)(NSString * cnt);
/// 二维码版本(可不填)
@property (nonatomic , readonly) TQRCode *(^version)(NSString * vsion);

@end

NS_ASSUME_NONNULL_END
