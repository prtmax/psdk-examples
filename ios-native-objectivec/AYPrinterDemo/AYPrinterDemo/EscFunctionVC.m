//
//  EscFunctionVC.m
//  AYPrinterDemo
//
//  Created by aiyin on 2023/9/18.
//

#import "EscFunctionVC.h"

@interface EscFunctionVC ()<UITextFieldDelegate>

@property (weak, nonatomic) IBOutlet UILabel *copiesLabel;
@property (weak, nonatomic) IBOutlet UIStepper *stepper;
@property (weak, nonatomic) IBOutlet UILabel *displayLabel;
@property (weak, nonatomic) IBOutlet UIProgressView *otaProgressView;
@property (strong, nonatomic) AYOtaHelper *ota;
@property (strong, nonatomic) AYEscCommand *esc;
@property (assign, nonatomic) int copies;
@property (assign, nonatomic) bool isLabel;
@property (assign, nonatomic) bool isPrinting;
@property (assign, nonatomic) bool isCompress;

@end

@implementation EscFunctionVC

- (void)viewDidLoad {
    [super viewDidLoad];
    self.copies = _copiesLabel.text.intValue;
    self.esc = [AYEscCommand new];
    [self initCallBack];
}

- (IBAction)stepperValueChanged:(UIStepper *)sender {
    self.copies = sender.value;
    self.copiesLabel.text = [NSString stringWithFormat:@"%d", self.copies];
}

- (void)initCallBack {
    __weak typeof(self) weakSelf = self;
    // 所以打印机数据接收
    self.bleHelper.onDataReceived = ^(NSData *data) {
        NSLog(@"收到数据: %@", data);
    };
    // 查询回调
    self.bleHelper.escQueryChange = ^(EQuery type, NSData *data) {
        Byte *bytes = (Byte *)[data bytes];
      NSLog(@"查询数据: %@", data);
        switch (type) {
            case QueryInfo:
                // 对应信息： 蓝牙名称 | 经典蓝牙 mac | ble mac | 打印机固件版本 | sn号 | 电量
                NSLog(@"打印机信息：%@", data);
                weakSelf.displayLabel.text = [NSString stringWithFormat:@"打印机信息：%@", [data toRawString]];
                break;
          case QueryState:{
            
                // * 0:打印机正常
                // * 其他（根据"位"判断打印机状态）
                // * 第0位：1：正在打印
                // * 第1位：1：纸舱盖开
                // * 第2位：1：缺纸
                // * 第3位：1：电池电压低
                // * 第4位：1：打印头过热
                NSLog(@"打印机状态：%@", data);
                bool isOK = YES;
                NSMutableArray *states = [NSMutableArray array];
                if ((bytes[0] & 0x01) == 0x01) {
                  [states addObject:@"正在打印"];
                  isOK = NO;
                }
                if ((bytes[0] & 0x02) == 0x02) {
                  [states addObject:@"纸舱盖开"];
                  isOK = NO;
                }
                if ((bytes[0] & 0x04) == 0x04) {
                  [states addObject:@"缺纸"];
                  isOK = NO;
                }
                if ((bytes[0] & 0x08) == 0x08) {
                  [states addObject:@"电池电压低"];
                  isOK = NO;
                }
                if ((bytes[0] & 0x10) == 0x10) {
                  [states addObject:@"打印头过热"];
                  isOK = NO;
                }
                if (isOK) {
                  [states addObject:@"良好"];
                }
            NSLog(@"states: %@", states);
            weakSelf.displayLabel.text = [NSString stringWithFormat:@"打印机状态：%@", [states componentsJoinedByString: @"+"]];
          }
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
         NSLog(@"escSettingChange : %ld, data: %@", type, data);
        switch (type) {
            case SetShutTime:
                NSLog(@"设置关机时间成功...");
                weakSelf.displayLabel.text = @"设置关机时间成功...";
                break;
            case SetThickness:
                NSLog(@"设置浓度成功...");
                weakSelf.displayLabel.text = @"设置浓度成功...";
                break;
            case SetLabelGap: {
                if ([data.toRawString isEqualToString:@"OK"]) {
                    [weakSelf.esc clean];
                    [weakSelf.esc enable];
                    [weakSelf.esc linedots:10];
                    [weakSelf.esc position];
                    [weakSelf.esc stopPrintJob];
                    [weakSelf.bleHelper writeCommands:weakSelf.esc.commands];
                    weakSelf.displayLabel.text = @"设置学习标签缝隙成功";
                } else {
                    weakSelf.displayLabel.text = @"设置学习标签缝隙失败";
                }
            }
                break;
            default:
                break;
        }
    };
    
    // 打印成功回调
    self.bleHelper.onPrintSuccess = ^(NSData *data) {
        if (!weakSelf.isPrinting) {
            return;
        }
        // NSLog(@"打印成功： %@, 剩余份数： %d", data, weakSelf.copies);
        if (weakSelf.copies <= 0) {
            weakSelf.isPrinting = NO;
            weakSelf.displayLabel.text = @"打印完成";
            weakSelf.copies = weakSelf.copiesLabel.text.intValue;
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
                    NSLog(@"打印机过热");
                }
                if ((bytes[1] & (Byte)0x02) ==  (Byte)0x02) {
                    NSLog(@"打印机开盖");
                }
                if ((bytes[1] & (Byte)0x04) ==  (Byte)0x04) {
                    NSLog(@"打印机缺纸");
                }
                if ((bytes[1] & (Byte)0x08) ==  (Byte)0x08) {
                    NSLog(@"打印机低压");
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

- (IBAction)compressChange:(UISwitch *)sender {
    self.isCompress = sender.isOn;
}
#pragma mark - 打印/print
/// 标签纸 / 黑标纸
- (IBAction)labelPrint {
    [self.esc clean];
    [self.esc wake];
    [self.esc enable];
//    [self.esc contentPosition:EPositionCenter];
    [self.esc image:[UIImage imageNamed:@"shouji.png"] compress:self.isCompress mode:Normal];
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
//    Xnip2024-09-07_08-24-20.png
    UIImage *image = [UIImage imageNamed:@"dithered-image4.png"];
//    image = [image dither];
//
//  image = [AYImageEnhance ditheringByFloydSteinberg:image];
    
    [self.esc clean];
    [self.esc wake];
    [self.esc enable];
    [self.esc linedots:80];
    [self.esc image:image compress:self.isCompress mode:Normal];
    [self.esc linedots:80];
    [self.esc stopPrintJob];
    
    self.isLabel = NO;
    self.isPrinting = YES;
    [self.bleHelper writeCommands:self.esc.commands];
  NSMutableData *data = [NSMutableData data];
  for (NSData *cmd in self.esc.commands) {
    [data appendData:cmd];
  }
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

- (IBAction)printerInfo:(id)sender {
    if (self.isPrinting) return;
    [self.esc clean];
    [self.esc printerInfo];
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
   
  
  UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"设置溶度" message:nil preferredStyle:UIAlertControllerStyleAlert];
  UIAlertAction *tsplAction = [UIAlertAction actionWithTitle:@"高" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
    [self.esc clean];
    [self.esc thickness:EThicknessHigh];
    [self.bleHelper writeCommands:self.esc.commands];
  }];
  UIAlertAction *escAction = [UIAlertAction actionWithTitle:@"中" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
    [self.esc clean];
    [self.esc thickness:EThicknessMedium];
    [self.bleHelper writeCommands:self.esc.commands];
  }];
  UIAlertAction *cpclAction = [UIAlertAction actionWithTitle:@"低" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
    [self.esc clean];
    [self.esc thickness:EThicknessLow];
    [self.bleHelper writeCommands:self.esc.commands];
  }];
  UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
      [self.bleHelper disconnect];
  }];
  
  [alertController addAction:tsplAction];
  [alertController addAction:escAction];
  [alertController addAction:cpclAction];
  [alertController addAction:cancelAction];
  [self presentViewController:alertController animated:YES completion:nil];
}

- (IBAction)learnLabelGap:(id)sender {
    if (self.isPrinting) return;
    [self.esc clean];
    [self.esc learnLabelGap];
    [self.bleHelper writeCommands:self.esc.commands];
}

#pragma mark - OTA升级/OTA Upgrade
#warning 仅适用于部分机型，请勿随意升级
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
                weakSelf.ota = nil;
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
