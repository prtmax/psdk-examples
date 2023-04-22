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

/**
 * 文本框
 */
@interface TTextBox : BasicTSPLArg

/// 起始x坐标
@property (nonatomic , readonly) TTextBox *(^x)(int startX);
/// 起始y坐标
@property (nonatomic , readonly) TTextBox *(^y)(int startY);
/// 字体
@property (nonatomic , readonly) TTextBox *(^font)(TFont fnt);
/// 旋转角度：可选参数 0，90，180，270
@property (nonatomic , readonly) TTextBox *(^rotation)(TRotation rot);
/// false: 旋转每一个字 true：整体旋转
@property (nonatomic , readonly) TTextBox *(^rotationType)(BOOL rType);
/// 横向放大倍数
@property (nonatomic , readonly) TTextBox *(^mulX)(int xmul);
/// 纵向放大倍数
@property (nonatomic , readonly) TTextBox *(^mulY)(int ymul);
/// 文本框宽度
@property (nonatomic , readonly) TTextBox *(^width)(int w);
/// 行间距
@property (nonatomic , readonly) TTextBox *(^lineSpace)(int space);
/// 是否加粗
@property (nonatomic , readonly) TTextBox *(^isBold)(BOOL bold);
/// 内容
@property (nonatomic , readonly) TTextBox *(^content)(NSString * cnt);

@end

NS_ASSUME_NONNULL_END
