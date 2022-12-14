#ifdef __OBJC__
#import <UIKit/UIKit.h>
#else
#ifndef FOUNDATION_EXPORT
#if defined(__cplusplus)
#define FOUNDATION_EXPORT extern "C"
#else
#define FOUNDATION_EXPORT extern
#endif
#endif
#endif

#import "UIView+MBPHUD.h"
#import "UIViewController+MBPHUD.h"

FOUNDATION_EXPORT double MBProgressHUD_AddVersionNumber;
FOUNDATION_EXPORT const unsigned char MBProgressHUD_AddVersionString[];

