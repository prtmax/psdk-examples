//
//  UIDevice+PAddition.h
//  BleDemo
//
//  Created by IPRT on 2022/11/22.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIDevice(PAddition)
+(CGFloat)p_safeDistanceTop;
+(CGFloat)p_safeDistanceBottom;
+(CGFloat)p_statusBarHeigh;
+(CGFloat)p_navigationBarHeight;
+(CGFloat)p_navigationFullHeight;
+(CGFloat)p_tabBarHeight;
+(CGFloat)p_tabBarFullHeight;
@end

NS_ASSUME_NONNULL_END
