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
#import <fsc/FscBleApi.h>
#import <esc/esc.h>
#import <father/father.h>
NS_ASSUME_NONNULL_BEGIN
typedef void (^ButtonClick)(void);
@interface BaseVC : UIViewController
@property(nonatomic , strong) NSString *titleStr;
-(void)backHandler;
@property(nonatomic , strong) UIView *contentView;
-(void)isNeedBackBtn:(BOOL)isNeed;
@property (nonatomic , strong) ConnectedDevice *device;
@property (nonatomic , strong) CBPeripheral *peripheral;
@property (nonatomic , copy) ButtonClick backClick;
@end

NS_ASSUME_NONNULL_END
