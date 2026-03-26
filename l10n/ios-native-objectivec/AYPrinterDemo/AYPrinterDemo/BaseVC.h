//
//  BaseVC.h
//  AYPrinterDemo
//
//  Created by aiyin on 2023/9/18.
//

#import <UIKit/UIKit.h>
#import <AYSDK/AYSDK.h>

#define AYLocalizedString(key) NSLocalizedString((key), nil)

NS_ASSUME_NONNULL_BEGIN

@interface BaseVC : UIViewController

@property (strong, nonatomic) AYBleHelper *bleHelper;

- (void)applyLocalization;

@end

NS_ASSUME_NONNULL_END
