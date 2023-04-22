//
//  BaseVC.h
//  BleDemo
//
//  Created by IPRT on 2022/11/22.
//

#import <UIKit/UIKit.h>
#import <Masonry/Masonry.h>
#import "UIDevice+PAddition.h"
#import <father/Commander.h>
#import <father/Command.h>
#import <adapter/ConnectedDevice.h>
#import <esc/esc.h>
#import <father/father.h>

typedef void (^NavBackCallBack)(void);

NS_ASSUME_NONNULL_BEGIN

@interface BaseVC : UIViewController

@property (nonatomic, strong) ConnectedDevice *device;
@property (nonatomic, strong) CBPeripheral *peripheral;
@property (nonatomic, copy) NavBackCallBack navBackCallBack;

@end

NS_ASSUME_NONNULL_END
