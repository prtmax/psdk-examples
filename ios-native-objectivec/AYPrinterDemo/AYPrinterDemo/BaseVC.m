//
//  BaseVC.m
//  AYPrinterDemo
//
//  Created by aiyin on 2023/9/18.
//

#import "BaseVC.h"

@interface BaseVC ()

@end

@implementation BaseVC

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.bleHelper = [AYBleHelper shareInstance];
}

@end
