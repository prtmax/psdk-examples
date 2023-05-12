//
//  EImage.h
//  ESC
//
//  Created by IPRT on 2022/10/13.
//

#import "BasicESCArg.h"
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
/**
 * 图片模式
 */
typedef enum {
    /// 正常打印
    NORMAL              = 0,
    /// 倍宽打印
    DOUBLE_WIDTH        = 1,
    /// 倍高打印
    DOUBLE_HEIGHT       = 2,
    /// 倍宽倍高打印
    DOUBLE_WIDTH_HEIGHT = 3
} Mode;
NS_ASSUME_NONNULL_BEGIN
/**
 * 图片
 */
@interface EImage : BasicESCArg

/// 图片
@property (nonatomic , readonly) EImage *(^image)(UIImage *img);
/// 图片宽度
@property (nonatomic , readonly) EImage *(^width)(int imageWidth);
/// 图片高度
@property (nonatomic , readonly) EImage *(^height)(int imageHeight);
/// 图片高度
@property (nonatomic , readonly) EImage *(^mode)(Mode imageMode);
/// 是否压缩
@property (nonatomic , readonly) EImage *(^compress)(BOOL isCompress);
/// 是否反色
@property (nonatomic , readonly) EImage *(^reverse)(BOOL isReverse);

@end

NS_ASSUME_NONNULL_END
