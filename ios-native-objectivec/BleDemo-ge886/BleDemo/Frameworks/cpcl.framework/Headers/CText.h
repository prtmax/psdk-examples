//
//  CText.h
//  CPCL
//
//  Created by IPRT on 2022/10/10.
//

#import "BasicCPCLArg.h"
#import "CPCLRotation.h"
#import "CPCLFont.h"
NS_ASSUME_NONNULL_BEGIN

/**
 * 文本
 */
@interface CText : BasicCPCLArg

/// 文字字体(默认TSS16)
@property (nonatomic , readonly) CText *(^font)(CFont fnt);
/// 文字旋转角度(默认不旋转)
@property (nonatomic , readonly) CText *(^rotation)(CRotation rot);
/// 矩形框左上角x坐标
@property (nonatomic , readonly) CText *(^textX)(int text);
/// 矩形框左上角y坐标
@property (nonatomic , readonly) CText *(^textY)(int text);
/// 打印的文本内容
@property (nonatomic , readonly) CText *(^content)(id text);
/// 是否加粗
@property (nonatomic , readonly) CText *(^bold)(BOOL isBold);
/// 是否下划线
@property (nonatomic , readonly) CText *(^underline)(BOOL isUnderline);
/// 是否字体倍数放大
@property (nonatomic , readonly) CText *(^mag)(BOOL isMag);

@end

NS_ASSUME_NONNULL_END
