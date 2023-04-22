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
+ (NSData *)Beeprt_DrawPic_pdfByImg:(UIImage*)img Size:(CGSize) targetSize compress:(BOOL)isCompress reverse:(BOOL)isReverse;
+ (NSData *)codeBy:(NSData *)source;
+ (UIImage *)imageByScalingBy:(UIImage *)sourceImage ToSize:(CGSize)targetSize;
+ (UIImage *)addImageBy:(UIImage*)img;
+ (UIImage *)changeGrayImage:(UIImage *)oldImage ;
+ (UIImage *)inverColorImage:(UIImage *)image;

@end

NS_ASSUME_NONNULL_END
