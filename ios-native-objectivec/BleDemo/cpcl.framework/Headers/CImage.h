//
//  CImage.h
//  CPCL
//
//  Created by IPRT on 2022/10/10.
//

#import "BasicCPCLArg.h"

NS_ASSUME_NONNULL_BEGIN

/**
 * 图片
 */
@interface CImage : BasicCPCLArg

/// 图片起始x坐标
@property (nonatomic, readonly) CImage *(^startX)(int imageStartX);
/// 图片起始y坐标
@property (nonatomic, readonly) CImage *(^startY)(int imageStartY);
/// 图片宽度
@property (nonatomic, readonly) CImage *(^width)(int imageWidth);
/// 图片高度
@property (nonatomic, readonly) CImage *(^height)(int imageHeight);
/// 图片
@property (nonatomic, readonly) CImage *(^image)(UIImage * img);
/// 是否压缩
@property (nonatomic, readonly) CImage *(^compress)(BOOL isCompress);
/// 是否反色
@property (nonatomic, readonly) CImage *(^reverse)(BOOL isReverse);

@end

NS_ASSUME_NONNULL_END
