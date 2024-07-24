//
//  TsplFunctionVC.m
//  AYPrinterDemo
//
//  Created by aiyin on 2023/9/13.
//

#import "TsplFunctionVC.h"

@interface TsplFunctionVC ()

@property (weak, nonatomic) IBOutlet UILabel *displayLabel;

@end

@implementation TsplFunctionVC

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    __weak typeof(self) weakSelf = self;
    self.bleHelper.onDataReceived = ^(NSData *data) {
        NSLog(@"onDataReceived: %@ - %@", data, data.toRawString);
    };
    self.bleHelper.onTsplDataReceived = ^(TReceivedType type, NSData *data) {
        NSLog(@"onTsplDataReceived: %@ - %@", data, data.toRawString);
        
        switch (type) {
            case TReceivedTypeSN:
                weakSelf.displayLabel.text = [NSString stringWithFormat:@"SN: %@", data.toRawString];
                break;
            case TReceivedTypeVersion:
                weakSelf.displayLabel.text = [NSString stringWithFormat:@"打印机版本号: %@", data.toRawString];
                break;
            case TReceivedPrinterState: {
               const Byte *bytes = data.bytes;
                NSMutableArray *stateArray = [NSMutableArray array];
                if (bytes[0] == (Byte)0x00) {
                    NSLog(@"打印机正常");
                    [stateArray addObject:@"打印机正常"];
                }
                if ((bytes[0]&(Byte)0x01) ==  (Byte)0x01) {
                    NSLog(@"打印机开盖");
                    [stateArray addObject:@"开盖"];
                }
                if ((bytes[0]&(Byte)0x02) ==  (Byte)0x02) {
                     NSLog(@"纸张错误");
                    [stateArray addObject:@"纸张错误"];
                 }
                if ((bytes[0]&(Byte)0x04) ==  (Byte)0x04) {
                     NSLog(@"打印机缺纸");
                    [stateArray addObject:@"缺纸"];
                 }
                if ((bytes[0]&(Byte)0x20) ==  (Byte)0x20) {
                     NSLog(@"打印中");
                    [stateArray addObject:@"打印中"];
                 }
                if ((bytes[0]&(Byte)0x10) ==  (Byte)0x10) {
                     NSLog(@"暂停");
                    [stateArray addObject:@"暂停"];
                }
                if ((bytes[0]&(Byte)0x80) ==  (Byte)0x80) {
                     NSLog(@" 过热");
                    [stateArray addObject:@"过热"];
                }
                
                weakSelf.displayLabel.text = [stateArray componentsJoinedByString:@"&"];
            }
                break;
            case TReceivedBatteryLevel: {
                const Byte *bytes = data.bytes;
                weakSelf.displayLabel.text = [NSString stringWithFormat:@"打印机电量: %d", bytes[3]];
            }
                break;
            case TReceivedPrintSuccess: {
                NSLog(@"打印成功");
                weakSelf.displayLabel.text = @"打印成功";
            }
                break;
            default:
                break;
        }
    };
}

- (IBAction)imagePtint:(id)sender {
    UIImage *image = [UIImage imageNamed:@"unititled.jpg"];
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
    [tspl qrCodeX:50 y:350 ecc:TECCLevelM cellwidth:6 rotation:TRotation_0 content:@"28938928"];
    [tspl textX:100 y:100 font:TFontTSS12 rotation:TRotation_0 xMulti:3 yMulti:3 bold:YES content:@"hello world, 你好"];
    [tspl print:1];
    
    [self.bleHelper writeCommands:tspl.commands];
}

- (IBAction)selfTest:(id)sender {
    TsplCommand *tspl = [TsplCommand new];
    [tspl selfTest];
    
    [self.bleHelper writeCommands:tspl.commands];
}

- (IBAction)sn:(id)sender {
    TsplCommand *tspl = [TsplCommand new];
    [tspl readSN];
    
    [self.bleHelper writeCommands:tspl.commands];
}

- (IBAction)version:(id)sender {
    TsplCommand *tspl = [TsplCommand new];
    [tspl readVersion];
    
    [self.bleHelper writeCommands:tspl.commands];
}

- (IBAction)state:(id)sender {
    TsplCommand *tspl = [TsplCommand new];
    [tspl readPrinterState];
    
    [self.bleHelper writeCommands:tspl.commands];
}

- (IBAction)batteryLevel:(id)sender {
    TsplCommand *tspl = [TsplCommand new];
    [tspl readBatteryLevel];
    
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
