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
        
    };
}

- (IBAction)printImage:(id)sender {
    UIImage *image = [UIImage imageNamed:@"handsomeMan.jpeg"];
    CpclCommand *cpcl = [CpclCommand new];
    [cpcl pageWidth:76 * 8 height:76 * 8 copies:1];
    [cpcl image:image x:0 y:0 compress:NO];
    [cpcl print:NO];
    
    [self.bleHelper writeCommands:cpcl.commands];
}




@end
