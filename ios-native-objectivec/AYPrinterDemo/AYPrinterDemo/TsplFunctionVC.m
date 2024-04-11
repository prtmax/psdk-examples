//
//  TsplFunctionVC.m
//  AYPrinterDemo
//
//  Created by aiyin on 2023/9/13.
//

#import "TsplFunctionVC.h"

@interface TsplFunctionVC ()

@end

@implementation TsplFunctionVC

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
}

- (IBAction)imagePtint:(id)sender {
    UIImage *image = [UIImage imageNamed:@"test.jpg"];
    TsplCommand *tspl = [TsplCommand new];
    [tspl pageWidth:76 height:130];
    [tspl direction:0 mirror:0];
    [tspl speed:5];
    [tspl density:5];
    [tspl enableCut:YES];
    [tspl enableGap:YES];
    [tspl cls];
    [tspl image:image x:0 y:0 compress:YES];
    [tspl print:1];
    
    [self.bleHelper writeCommands:tspl.commands];
}

- (IBAction)commandPrint:(id)sender {
    TsplCommand *tspl = [TsplCommand new];
    [tspl pageWidth:76 height:130];
    [tspl cls];
    [tspl density:10];
    [tspl circleX:0 y:0 diameter:76 * 8 thinkness:5];
    [tspl lineX:0 y:10 endX:480 endY:10 width:2 lineType:0];
    [tspl lineX:0 y:34 endX:480 endY:34 width:2 lineType:1];
    [tspl lineX:0 y:58 endX:480 endY:58 width:2 lineType:2];
    [tspl lineX:0 y:83 endX:480 endY:83 width:2 lineType:3];
    [tspl lineX:0 y:107 endX:480 endY:107 width:2 lineType:4];
    [tspl print:1];
    
    [self.bleHelper writeCommands:tspl.commands];
}

- (IBAction)selfTest:(id)sender {
    TsplCommand *tspl = [TsplCommand new];
    [tspl selfTest];
    
    [self.bleHelper writeCommands:tspl.commands];
}

#warning 仅适用于部分机型，请勿随意升级
- (IBAction)otaUpdate:(id)sender {
   NSString *filepath = [[NSBundle mainBundle] pathForResource:@"QR-888 FWQR_SFUBE_BQ_VER_01_240201.ALLAY" ofType:nil];

    NSLog(@"%@", filepath);
    NSData* filedata = [NSData dataWithContentsOfFile:filepath];
    NSMutableArray<NSData *> *dadas = [NSMutableArray array];
    [dadas addObject:filedata];
    [self.bleHelper writeCommands:dadas];
}


@end
