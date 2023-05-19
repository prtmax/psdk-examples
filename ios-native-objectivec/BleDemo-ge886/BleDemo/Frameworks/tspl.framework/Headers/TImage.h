//
//  TImage.h
//  TSPL
//
//  Created by IPRT on 2022/10/12.
//

#import <tspl/BasicTSPLArg.h>
#import <tspl/TSPLImageMode.h>
#import <UIKit/UIKit.h>
NS_ASSUME_NONNULL_BEGIN

/**
 * 图片
 */
@interface TImage : BasicTSPLArg

/// 图片起始x坐标
@property (nonatomic , readonly) TImage *(^x)(int originX);
/// 图片起始y坐标
@property (nonatomic , readonly) TImage *(^y)(int originY);
/// 图片
@property (nonatomic , readonly) TImage *(^image)(UIImage *img);
/// 图片宽度
@property (nonatomic , readonly) TImage *(^width)(int imageWidth);
/// 图片高度
@property (nonatomic , readonly) TImage *(^height)(int imageHeight);
/// 是否压缩
@property (nonatomic , readonly) TImage *(^compress)(BOOL isCompress);
/// 图片模式
@property (nonatomic , readonly) TImage *(^mode)(TImageMode imageMode);
/// 是否反色
@property (nonatomic , readonly) TImage *(^reverse)(BOOL isReverse);
@end

NS_ASSUME_NONNULL_END
