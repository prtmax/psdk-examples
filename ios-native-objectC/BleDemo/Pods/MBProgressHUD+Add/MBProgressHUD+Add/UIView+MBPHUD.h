//
//  UIView+MBPHUD.h
//  HBGovSwift
//
//  Created by 余汪送 on 2017/12/11.
//  Copyright © 2017年 capsule. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MBProgressHUD/MBProgressHUD.h>

typedef NS_ENUM(NSInteger, MBPHUDProgressStyle) {
    MBPHUDProgressStyleNormal,
    MBPHUDProgressStyleBar,
    MBPHUDProgressStyleAnnular
};

NS_ASSUME_NONNULL_BEGIN

@interface UIView (MBPHUD)

@property (weak, nonatomic) MBProgressHUD *HUD;

- (void)showHUD;
- (void)showHUDWithMessage:(nullable NSString *)message;
- (void)showHUDMessage:(NSString *)message;

- (void)showHUDWithImage:(UIImage *)image;
- (void)showHUDWithImage:(UIImage *)image message:(nullable NSString *)message;

- (void)showHUDProgressHUD;
- (void)showHUDProgressWithMessage:(nullable NSString *)message;
- (void)showHUDProgressWithMessage:(nullable NSString *)message style:(MBPHUDProgressStyle)style;
- (void)updateHUDProgress:(CGFloat)progress;

- (void)hideHUD;
- (void)hideHUDCompletion:(nullable void(^)(void))completion;

@end

NS_ASSUME_NONNULL_END

