//
//  PImageTool.h
//  father
//
//  Created by IPRT on 2022/12/7.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIkit.h>
NS_ASSUME_NONNULL_BEGIN

@interface PImageTool : NSObject
+(NSData *)Beeprt_DrawPic_pdfBy:(NSUInteger)x start_y:(NSUInteger)y img:(UIImage*)img Size:(CGSize) targetSize compress:(BOOL)compress;
+(NSData *)codeBy:(NSData *)source;
+ (UIImage *)imageByScalingBy:(UIImage *)sourceImage ToSize:(CGSize)targetSize;
+(UIImage *)addImageBy:(UIImage*)img;
@end

NS_ASSUME_NONNULL_END
