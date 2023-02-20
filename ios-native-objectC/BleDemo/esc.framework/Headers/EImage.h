//
//  EImage.h
//  ESC
//
//  Created by IPRT on 2022/10/13.
//

#import "BasicESCArg.h"
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
typedef enum {
    NORMAL              = 0,
    DOUBLE_WIDTH        = 1,
    DOUBLE_HEIGHT       = 2,
    DOUBLE_WIDTH_HEIGHT = 3
} Mode;
NS_ASSUME_NONNULL_BEGIN

@interface EImage : BasicESCArg
@property (nonatomic , readonly) EImage *(^image)(UIImage *img);
@property (nonatomic , readonly) EImage *(^width)(int imageWidth);
@property (nonatomic , readonly) EImage *(^height)(int imageHeight);
@property (nonatomic , readonly) EImage *(^mode)(Mode imageMode);
@property (nonatomic , readonly) EImage *(^compress)(BOOL isCompress);
@property (nonatomic , readonly) EImage *(^reverse)(BOOL isReverse);
@end

NS_ASSUME_NONNULL_END
