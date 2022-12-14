//
//  UIDevice+PAddition.m
//  BleDemo
//
//  Created by IPRT on 2022/11/22.
//

#import "UIDevice+PAddition.h"

@implementation UIDevice(PAddition)
+(CGFloat)p_safeDistanceTop{
    if(@available(iOS 13.0,*)){
        NSSet *set = [UIApplication sharedApplication].connectedScenes;
        UIWindowScene *windowSence = [set anyObject];
        UIWindow *window = windowSence.windows.firstObject;
        return window.safeAreaInsets.top;
    }else if(@available(iOS 11.0, *)){
        UIWindow *window = [UIApplication sharedApplication].windows.firstObject;
        return window.safeAreaInsets.top;
    }
    return 0;
}
+(CGFloat)p_safeDistanceBottom{
    if(@available(iOS 13.0, *)){
        NSSet *set = [UIApplication sharedApplication].connectedScenes;
        UIWindowScene *windowScene = [set anyObject];
        UIWindow *window = windowScene.windows.firstObject;
        return window.safeAreaInsets.bottom;
    }else if (@available(iOS 11.0,*)){
        UIWindow *window = [UIApplication sharedApplication].windows.firstObject;
        return window.safeAreaInsets.bottom;
    }
    return 0;
}
+(CGFloat)p_statusBarHeigh{
    if(@available(iOS 13.0, *)){
        NSSet *set = [UIApplication sharedApplication].connectedScenes;
        UIWindowScene *windowScene = [set anyObject];
        UIStatusBarManager *statusBarManager = windowScene.statusBarManager;
        return statusBarManager.statusBarFrame.size.height;
    }else{
        return [UIApplication sharedApplication].statusBarFrame.size.height;
    }
}
+(CGFloat)p_navigationBarHeight{
    return 44.0f;
}
+(CGFloat)p_navigationFullHeight{
    return [UIDevice p_statusBarHeigh] +[UIDevice p_navigationBarHeight];
}
+(CGFloat)p_tabBarHeight{
    return 49.0f;
}
+(CGFloat)p_tabBarFullHeight{
    return [UIDevice p_tabBarHeight] +[UIDevice p_safeDistanceBottom];
}
@end
