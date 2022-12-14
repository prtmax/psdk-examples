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

@interface TImage : BasicTSPLArg
@property (nonatomic , readonly) TImage *(^x)(int originX);
@property (nonatomic , readonly) TImage *(^y)(int originY);
@property (nonatomic , readonly) TImage *(^image)(UIImage *img);
@property (nonatomic , readonly) TImage *(^width)(int imageWidth);
@property (nonatomic , readonly) TImage *(^height)(int imageHeight);
@property (nonatomic , readonly) TImage *(^compress)(BOOL isCompress);
@property (nonatomic , readonly) TImage *(^mode)(TImageMode imageMode);
//@property (nonatomic , readonly) TImage *(^reverse)(BOOL reverse);反色调
@end

NS_ASSUME_NONNULL_END
