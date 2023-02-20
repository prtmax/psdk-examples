//
//  CImage.h
//  CPCL
//
//  Created by IPRT on 2022/10/10.
//

#import "BasicCPCLArg.h"

NS_ASSUME_NONNULL_BEGIN

@interface CImage : BasicCPCLArg
@property (nonatomic, readonly) CImage *(^startX)(int imageStartX);
@property (nonatomic, readonly) CImage *(^startY)(int imageStartY);
@property (nonatomic, readonly) CImage *(^width)(int imageWidth);
@property (nonatomic, readonly) CImage *(^height)(int imageHeight);
@property (nonatomic, readonly) CImage *(^image)(UIImage * img);
@property (nonatomic, readonly) CImage *(^compress)(BOOL isCompress);
@property (nonatomic, readonly) CImage *(^reverse)(BOOL isReverse);

@end

NS_ASSUME_NONNULL_END
