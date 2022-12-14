//
//  TTextBox.h
//  TSPL
//
//  Created by IPRT on 2022/10/12.
//

#import <tspl/BasicTSPLArg.h>
#import "TSPLFont.h"
#import "TSPLRotation.h"
NS_ASSUME_NONNULL_BEGIN

@interface TTextBox : BasicTSPLArg
@property (nonatomic , readonly) TTextBox *(^x)(int startX);//起始x坐标
@property (nonatomic , readonly) TTextBox *(^y)(int startY);//起始y坐标
@property (nonatomic , readonly) TTextBox *(^font)(TFont fnt);//字体
@property (nonatomic , readonly) TTextBox *(^rotation)(TRotation rot);//旋转角度：可选参数 0，90，180，270
@property (nonatomic , readonly) TTextBox *(^rotationType)(BOOL rType);//false: 旋转每一个字 true：整体旋转
@property (nonatomic , readonly) TTextBox *(^mulX)(int xmul);//横向放大倍数
@property (nonatomic , readonly) TTextBox *(^mulY)(int ymul);//纵向放大倍数
@property (nonatomic , readonly) TTextBox *(^width)(int w);//文本框宽度
@property (nonatomic , readonly) TTextBox *(^lineSpace)(int space);//行间距
@property (nonatomic , readonly) TTextBox *(^isBold)(BOOL bold);//是否加粗
@property (nonatomic , readonly) TTextBox *(^content)(NSString * cnt);//内容

@end

NS_ASSUME_NONNULL_END
