//
//  CImagezg.h
//  cpcl
//
//  Created by IPRT on 2022/12/3.
//

#import <cpcl/BasicCPCLArg.h>

NS_ASSUME_NONNULL_BEGIN

@interface CImagezg : BasicCPCLArg
@property (nonatomic, readonly) CImagezg *(^startX)(int imageStartX);
@property (nonatomic, readonly) CImagezg *(^startY)(int imageStartY);
@property (nonatomic, readonly) CImagezg *(^width)(int imageWidth);
@property (nonatomic, readonly) CImagezg *(^height)(int imageHeight);
@property (nonatomic, readonly) CImagezg *(^compress)(BOOL isCompress);
@property (nonatomic ,readonly) CImagezg *(^image)(UIImage *img);
@property (nonatomic, readonly) CImagezg *(^reverse)(BOOL isReverse);

@end

NS_ASSUME_NONNULL_END
