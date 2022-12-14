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

@interface CText : BasicCPCLArg
@property (nonatomic , readonly) CText *(^font)(CFont fnt);
@property (nonatomic , readonly) CText *(^rotation)(CRotation rot);
@property (nonatomic , readonly) CText *(^textX)(int text);//矩形框左上角x坐标
@property (nonatomic , readonly) CText *(^textY)(int text);//矩形框左上角y坐标
@property (nonatomic , readonly) CText *(^content)(id text);//打印的文本内容
@property (nonatomic , readonly) CText *(^bold)(BOOL isBold);//是否加粗
@property (nonatomic , readonly) CText *(^underline)(BOOL isUnderline);//是否下划线
@property (nonatomic , readonly) CText *(^mag)(BOOL isMag);//是否字体倍数放大
@end

NS_ASSUME_NONNULL_END
