//
//  TText.h
//  TSPL
//
//  Created by IPRT on 2022/10/12.
//

#import <tspl/BasicTSPLArg.h>
#import "TSPLFont.h"
#import "TSPLRotation.h"
NS_ASSUME_NONNULL_BEGIN

@interface TText : BasicTSPLArg
@property (nonatomic , readonly) TText *(^x)(int startX);//起始x坐标
@property (nonatomic , readonly) TText *(^y)(int startY);//起始y坐标
@property (nonatomic , readonly) TText *(^font)(TFont fnt);//字体
@property (nonatomic , readonly) TText *(^rotation)(TRotation rot);//旋转角度：可选参数 0，90，180，270
@property (nonatomic , readonly) TText *(^xmulti)(int xmul);//横向放大倍数
@property (nonatomic , readonly) TText *(^ymulti)(int ymul);//纵向放大倍数
@property (nonatomic , readonly) TText *(^isBold)(BOOL bold);//是否加粗
@property (nonatomic , readonly) TText *(^content)(NSString * cnt);//内容
@end

NS_ASSUME_NONNULL_END
