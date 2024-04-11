//
//  EscFunctionVC.m
//  AYPrinterDemo
//
//  Created by aiyin on 2023/9/18.
//

#import "EscFunctionVC.h"

@interface EscFunctionVC ()<UITextFieldDelegate>

@property (weak, nonatomic) IBOutlet UITextField *copiesTextF;
@property (weak, nonatomic) IBOutlet UILabel *displayLabel;
@property (weak, nonatomic) IBOutlet UIProgressView *otaProgressView;
@property (strong, nonatomic) AYOtaHelper *ota;
@property (strong, nonatomic) EscCommand *esc;
@property (assign, nonatomic) int copies;
@property (assign, nonatomic) bool isLabel;
@property (assign, nonatomic) bool isPrinting;

@end

@implementation EscFunctionVC

- (void)viewDidLoad {
    [super viewDidLoad];
    self.copiesTextF.delegate = self;
    self.esc = [EscCommand new];
    [self initCallBack];
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    self.copies = [textField.text intValue];
}

- (void)initCallBack {
    __weak typeof(self) weakSelf = self;
    // 查询回调
    self.bleHelper.escQueryChange = ^(EQuery type, NSData *data) {
        Byte *bytes = (Byte *)[data bytes];
        switch (type) {
            case QueryState:
                NSLog(@"打印机状态：%@", data);
                weakSelf.displayLabel.text = [NSString stringWithFormat:@"打印机状态：%@", data];
                break;
            case QueryBatteryVol:
                NSLog(@"电量: %d ",  bytes[1]);
                weakSelf.displayLabel.text = [NSString stringWithFormat:@"电量: %d",  bytes[1]];
                break;
            case QueryMac:
                NSLog(@"蓝牙mac地址: %@", [data toHexString]);
                weakSelf.displayLabel.text = [NSString stringWithFormat:@"蓝牙mac地址: %@", [data toHexString]];
                break;
            case QuerySN:
                NSLog(@"打印机sn：%@", [data toRawString]);
                weakSelf.displayLabel.text = [NSString stringWithFormat:@"打印机sn：%@", [data toRawString]];
                break;
            case QueryBtName:
                NSLog(@"打印机名称：%@", [data toRawString]);
                weakSelf.displayLabel.text = [NSString stringWithFormat:@"打印机名称：%@", [data toRawString]];
                break;
            case QueryBtVersion:
                NSLog(@"蓝牙固件版本：%@", [data toRawString]);
                weakSelf.displayLabel.text = [NSString stringWithFormat:@"蓝牙固件版本：%@", [data toRawString]];
                break;
            case QueryVersion:
                NSLog(@"打印机固件版本：%@", [data toRawString]);
                weakSelf.displayLabel.text = [NSString stringWithFormat:@"打印机固件版本：%@", [data toRawString]];
                break;
            case QueryModel:
                NSLog(@"打印机型号：%@", [data toRawString]);
                weakSelf.displayLabel.text = [NSString stringWithFormat:@"打印机型号：%@", [data toRawString]];
                break;
            case QueryShutTime:
                NSLog(@"关机时间：%d", bytes[1]);
                weakSelf.displayLabel.text = [NSString stringWithFormat:@"关机时间：%d 分钟", bytes[1]];
                break;
                
            default:
                break;
        }
    };
    
    // 设置回调
    self.bleHelper.escSettingChange = ^(ESet type, NSData *data) {
        // NSLog(@"escSettingChange : %ld, data: %@", type, data);
        switch (type) {
            case SetShutTime:
                NSLog(@"设置关机时间成功...");
                weakSelf.displayLabel.text = @"设置关机时间成功...";
                break;
            case SetThickness:
                NSLog(@"设置浓度成功...");
                weakSelf.displayLabel.text = @"设置浓度成功...";
                break;
                
            default:
                break;
        }
    };
    
    // 打印成功回调
    self.bleHelper.onPrintSuccess = ^(NSData *data) {
        // NSLog(@"打印成功： %@", data);
        if (weakSelf.copies <= 0) {
            weakSelf.isPrinting = NO;
            weakSelf.displayLabel.text = @"打印完成";
            weakSelf.copies = weakSelf.copiesTextF.text.intValue;
            return;
        };
        if (weakSelf.isLabel) {
            [weakSelf labelPrint];
        } else {
            [weakSelf continuousPrint];
        }
    };
    
    // 打印机反馈回调
    self.bleHelper.onPrinterAutoReport = ^(NSData *data) {
        // NSLog(@"收到打印机反馈： %@", data);
        const Byte *bytes = data.bytes;
        /// 主动上报纸张类型
        if(data.length == 2 && bytes[0] == (Byte)0xFE){
            switch (bytes[1]) {
                case 1:
                    NSLog(@"onPaperError: 折叠黑标纸");
                    break;
                case 2:
                    NSLog(@"onPaperError: 连续卷简纸");
                    break;
                case 3:
                    NSLog(@"onPaperError: 不干胶缝隙纸");
                    break;
                    
                default:
                    break;
            }
        }
         
        /// 上报设备状态
        if (data.length == 2 && bytes[0] == (Byte)0xFF) {
            if ((bytes[1]) ==  0) {
                NSLog(@"打印机正常");
            } else {
                if ((bytes[1] & (Byte)0x01) ==  (Byte)0x01) {
                    NSLog(@"打印机缺纸");
                }
                if ((bytes[1] & (Byte)0x02) ==  (Byte)0x02) {
                    NSLog(@"打印机开盖");
                }
                if ((bytes[1] & (Byte)0x03) ==  (Byte)0x03) {
                    NSLog(@"打印机过热");
                }
                if ((bytes[1] & (Byte)0x04) ==  (Byte)0x04) {
                    NSLog(@"打印机低电量");
                }
                if ((bytes[1] & (Byte)0x08) ==  (Byte)0x08) {
                    NSLog(@"打印机合盖，前提要打印机支持此功能");
                }
                if ((bytes[1] & (Byte)0x10) ==  (Byte)0x10) {
                    NSLog(@"请使用PikDik品牌标签，获得更好的打印体验");
                }
            }
        }
        
        /// 上报中止打印机状态命令
        if (data.length == 2 && bytes[0] == (Byte)0xFD) {
            switch (bytes[1]) {
                case 1:
                    NSLog(@"开始清除当前页面打印任务（中止命令）");
                    break;
                case 2:
                    NSLog(@"清除当前打印任务结束");
                    break;
                    
                default:
                    break;
            }
        }
    };
}

#pragma mark - 打印/print
/// 标签纸
- (IBAction)labelPrint {
    [self.esc clean];
    [self.esc wake];
    [self.esc enable];
    [self.esc image:[UIImage imageNamed:@"蚊香液.png"] compress:NO mode:Normal];
    [self.esc position];
    [self.esc stopPrintJob];

    self.isLabel = YES;
    self.isPrinting = YES;
    [self.bleHelper writeCommands:self.esc.commands];
    self.copies -= 1;
    NSLog(@"打印中，请勿发其他指令，会有干扰！！！");
}

/// 连续纸
- (IBAction)continuousPrint {
    [self.esc clean];
    [self.esc wake];
    [self.esc enable];
    [self.esc linedots:80];
    [self.esc image:[UIImage imageNamed:@"wenshen_dd.jpg"] compress:YES mode:Normal];
    [self.esc linedots:80];
    [self.esc stopPrintJob];
    
    self.isLabel = NO;
    self.isPrinting = YES;
    [self.bleHelper writeCommands:self.esc.commands];
    self.copies -= 1;
    NSLog(@"打印中，请勿发其他指令，会有干扰！！！");
}

#pragma mark - 查询/query
- (IBAction)printerState:(id)sender {
    if (self.isPrinting) return;
    [self.esc clean];
    [self.esc state];
    [self.bleHelper writeCommands:self.esc.commands];
}

- (IBAction)printerBatteryVol:(id)sender {
    if (self.isPrinting) return;
    [self.esc clean];
    [self.esc batteryVol];
    [self.bleHelper writeCommands:self.esc.commands];
}

- (IBAction)printerMac:(id)sender {
    if (self.isPrinting) return;
    [self.esc clean];
    [self.esc mac];
    [self.bleHelper writeCommands:self.esc.commands];
}

- (IBAction)PrinterSN:(id)sender {
    if (self.isPrinting) return;
    [self.esc clean];
    [self.esc sn];
    [self.bleHelper writeCommands:self.esc.commands];
}

- (IBAction)printerBtname:(id)sender {
    if (self.isPrinting) return;
    [self.esc clean];
    [self.esc btName];
    [self.bleHelper writeCommands:self.esc.commands];
}

- (IBAction)printerBtVersion:(id)sender {
    if (self.isPrinting) return;
    [self.esc clean];
    [self.esc btVersion];
    [self.bleHelper writeCommands:self.esc.commands];
}

- (IBAction)printerVersion:(id)sender {
    if (self.isPrinting) return;
    [self.esc clean];
    [self.esc printerVersion];
    [self.bleHelper writeCommands:self.esc.commands];
}

- (IBAction)PrinterModel:(id)sender {
    if (self.isPrinting) return;
    [self.esc clean];
    [self.esc printerModel];
    [self.bleHelper writeCommands:self.esc.commands];
}

- (IBAction)shutTime:(id)sender {
    if (self.isPrinting) return;
    [self.esc clean];
    [self.esc shutTime];
    [self.bleHelper writeCommands:self.esc.commands];
}

#pragma mark - 设置/setting
- (IBAction)setShutTime:(id)sender {
    if (self.isPrinting) return;
    [self.esc clean];
    [self.esc shutTime:30];
    [self.bleHelper writeCommands:self.esc.commands];
}

- (IBAction)setThickness:(id)sender {
    if (self.isPrinting) return;
    [self.esc clean];
    [self.esc thickness:EThicknessHigh];
    [self.bleHelper writeCommands:self.esc.commands];
}

#pragma mark - OTA升级/OTA Upgrade
- (IBAction)ota:(id)sender {
    if (self.isPrinting) return;
    __weak typeof(self) weakSelf = self;
    self.ota.progressChange = ^(int progress) {
        weakSelf.displayLabel.text = [NSString stringWithFormat:@"升级进度：%d / 100", progress];
        [weakSelf.otaProgressView setProgress:progress / 100.0];
    };
    self.ota.otaStateChange = ^(OtaState state) {
        switch (state) {
            case OtaStateStart:
                NSLog(@"开始升级");
                break;
            case OtaStateFail:
                NSLog(@"升级失败");
                weakSelf.displayLabel.text = @"开始升级";
                break;
            case OtaStateSuccess:
                NSLog(@"升级成功");
                weakSelf.displayLabel.text = @"升级成功";
                [weakSelf.navigationController popViewControllerAnimated:YES];
                break;
                
            default:
                break;
        }
    };
    NSString *filepath = [[NSBundle mainBundle] pathForResource:@"DL-Q2 V1.12.PRTU" ofType:nil];
    NSData* filedata = [NSData dataWithContentsOfFile:filepath];
    
    self.otaProgressView.progress = 0;
    self.otaProgressView.hidden = NO;
    [self.ota otaWithFileData:filedata startAddress:0x1009000];
}

#pragma mark -
- (AYOtaHelper *)ota {
    if (!_ota) {
        _ota = [AYOtaHelper new];
    }
    return _ota;
}

@end
