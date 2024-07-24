//
//  CpclFunctionVC.m
//  AYPrinterDemo
//
//  Created by aiyin on 2023/9/19.
//

#import "CpclFunctionVC.h"

@interface CpclFunctionVC ()

@end

@implementation CpclFunctionVC

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    self.bleHelper.onDataReceived = ^(NSData *data) {
        NSLog(@"收到数据： %@", data);
    };
}

- (IBAction)printImage:(id)sender {
    UIImage *image = [UIImage imageNamed:@"handsomeMan.jpeg"];
    CpclCommand *cpcl = [CpclCommand new];
    [cpcl pageWidth:76 * 8 height:76 * 8 copies:1];
    [cpcl image:image x:0 y:0 compress:YES];
    [cpcl print:NO];
    
    [self.bleHelper writeCommands:cpcl.commands];
}


- (IBAction)printTemplate:(id)sender {
    CpclCommand *cpcl = [CpclCommand new];

    [self.bleHelper writeCommands:cpcl.commands];
}

- (IBAction)sn:(id)sender {
    CpclCommand *cpcl = [CpclCommand new];
    [cpcl readSn];

    [self.bleHelper writeCommands:cpcl.commands];
}

- (IBAction)state:(id)sender {
    CpclCommand *cpcl = [CpclCommand new];
    [cpcl readState];

    [self.bleHelper writeCommands:cpcl.commands];
}

#warning 仅适用于部分机型
- (IBAction)selfTest:(id)sender {
    CpclCommand *cpcl = [CpclCommand new];
    [cpcl selfTest];

    [self.bleHelper writeCommands:cpcl.commands];
}


@end
