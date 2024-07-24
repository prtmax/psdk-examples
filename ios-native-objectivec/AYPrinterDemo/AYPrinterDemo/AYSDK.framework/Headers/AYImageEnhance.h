//
//  AYImageEnhance.h
//  AYSDK
//
//  Created by aiyin on 2024/7/9.
//

#import <Foundation/Foundation.h>
@class UIImage;

@interface AYImageEnhance : NSObject

// 图片锐化
+ (UIImage *)sharpenImage:(UIImage *)image;

// 弗洛伊德-斯坦伯格抖动算法
//+ (UIImage *)ditheringByFloydSteinberg:(UIImage *)image;

@end

