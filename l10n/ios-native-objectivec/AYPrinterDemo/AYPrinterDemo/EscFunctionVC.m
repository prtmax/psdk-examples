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
    // 所有打印机数据接收 / Receive all raw printer data.
    self.bleHelper.onDataReceived = ^(NSData *data) {
        NSLog(AYLocalizedString(@"收到数据: %@"), data);
    };
    // 查询回调 / Query callback.
    self.bleHelper.escQueryChange = ^(EQuery type, NSData *data) {
        Byte *bytes = (Byte *)[data bytes];
      NSLog(AYLocalizedString(@"查询数据: %@"), data);
        switch (type) {
            case QueryInfo:
                // 对应信息：蓝牙名称 | 经典蓝牙 MAC | BLE MAC | 打印机固件版本 | SN 号 | 电量 / Response fields: Bluetooth name | classic Bluetooth MAC | BLE MAC | printer firmware | SN | battery.
                NSLog(AYLocalizedString(@"打印机信息：%@"), data);
                weakSelf.displayLabel.text = [NSString stringWithFormat:AYLocalizedString(@"打印机信息：%@"), [data toRawString]];
                break;
          case QueryState:{
            
                // * 0: 打印机正常 / 0 means printer is ready.
                // * 其他（根据“位”判断打印机状态）/ Other values are interpreted bit by bit.
                // * 第0位：1：正在打印 / Bit 0: printing.
                // * 第1位：1：纸舱盖开 / Bit 1: paper cover open.
                // * 第2位：1：缺纸 / Bit 2: out of paper.
                // * 第3位：1：电池电压低 / Bit 3: low battery voltage.
                // * 第4位：1：打印头过热 / Bit 4: printhead overheated.
                NSLog(AYLocalizedString(@"打印机状态：%@"), data);
                bool isOK = YES;
                NSMutableArray *states = [NSMutableArray array];
                if ((bytes[0] & 0x01) == 0x01) {
                  [states addObject:AYLocalizedString(@"正在打印")];
                  isOK = NO;
                }
                if ((bytes[0] & 0x02) == 0x02) {
                  [states addObject:AYLocalizedString(@"纸舱盖开")];
                  isOK = NO;
                }
                if ((bytes[0] & 0x04) == 0x04) {
                  [states addObject:AYLocalizedString(@"缺纸")];
                  isOK = NO;
                }
                if ((bytes[0] & 0x08) == 0x08) {
                  [states addObject:AYLocalizedString(@"电池电压低")];
                  isOK = NO;
                }
                if ((bytes[0] & 0x10) == 0x10) {
                  [states addObject:AYLocalizedString(@"打印头过热")];
                  isOK = NO;
                }
                if (isOK) {
                  [states addObject:AYLocalizedString(@"良好")];
                }
            NSLog(@"states: %@", states);
            weakSelf.displayLabel.text = [NSString stringWithFormat:AYLocalizedString(@"打印机状态：%@"), [states componentsJoinedByString:@"+"]];
          }
                break;
            case QueryBatteryVol:
                NSLog(AYLocalizedString(@"电量: %d"), bytes[1]);
                weakSelf.displayLabel.text = [NSString stringWithFormat:AYLocalizedString(@"电量: %d"), bytes[1]];
                break;
            case QueryMac:
                NSLog(AYLocalizedString(@"蓝牙mac地址: %@"), [data toHexString]);
                weakSelf.displayLabel.text = [NSString stringWithFormat:AYLocalizedString(@"蓝牙mac地址: %@"), [data toHexString]];
                break;
            case QuerySN:
                NSLog(AYLocalizedString(@"打印机sn：%@"), [data toRawString]);
                weakSelf.displayLabel.text = [NSString stringWithFormat:AYLocalizedString(@"打印机sn：%@"), [data toRawString]];
                break;
            case QueryBtName:
                NSLog(AYLocalizedString(@"打印机名称：%@"), [data toRawString]);
                weakSelf.displayLabel.text = [NSString stringWithFormat:AYLocalizedString(@"打印机名称：%@"), [data toRawString]];
                break;
            case QueryBtVersion:
                NSLog(AYLocalizedString(@"蓝牙固件版本：%@"), [data toRawString]);
                weakSelf.displayLabel.text = [NSString stringWithFormat:AYLocalizedString(@"蓝牙固件版本：%@"), [data toRawString]];
                break;
            case QueryVersion:
                NSLog(AYLocalizedString(@"打印机固件版本：%@"), [data toRawString]);
                weakSelf.displayLabel.text = [NSString stringWithFormat:AYLocalizedString(@"打印机固件版本：%@"), [data toRawString]];
                break;
            case QueryModel:
                NSLog(AYLocalizedString(@"打印机型号：%@"), [data toRawString]);
                weakSelf.displayLabel.text = [NSString stringWithFormat:AYLocalizedString(@"打印机型号：%@"), [data toRawString]];
                break;
            case QueryShutTime:
                NSLog(AYLocalizedString(@"关机时间：%d"), bytes[1]);
                weakSelf.displayLabel.text = [NSString stringWithFormat:AYLocalizedString(@"关机时间：%d 分钟"), bytes[1]];
                break;
                
            default:
                break;
        }
    };
    
    // 设置回调 / Settings callback.
    self.bleHelper.escSettingChange = ^(ESet type, NSData *data) {
         NSLog(@"escSettingChange : %ld, data: %@", type, data);
        switch (type) {
            case SetShutTime:
                NSLog(@"%@", AYLocalizedString(@"设置关机时间成功..."));
                weakSelf.displayLabel.text = AYLocalizedString(@"设置关机时间成功...");
                break;
            case SetThickness:
                NSLog(@"%@", AYLocalizedString(@"设置浓度成功..."));
                weakSelf.displayLabel.text = AYLocalizedString(@"设置浓度成功...");
                break;
            case SetLabelGap: {
                if ([data.toRawString isEqualToString:@"OK"]) {
                    [weakSelf.esc clean];
                    [weakSelf.esc enable];
                    [weakSelf.esc linedots:10];
                    [weakSelf.esc position];
                    [weakSelf.esc stopPrintJob];
                    [weakSelf.bleHelper writeCommands:weakSelf.esc.commands];
                    weakSelf.displayLabel.text = AYLocalizedString(@"设置学习标签缝隙成功");
                } else {
                    weakSelf.displayLabel.text = AYLocalizedString(@"设置学习标签缝隙失败");
                }
            }
                break;
            default:
                break;
        }
    };
    
    // 打印成功回调 / Print success callback.
    self.bleHelper.onPrintSuccess = ^(NSData *data) {
        if (!weakSelf.isPrinting) {
            return;
        }
        // NSLog(@"打印成功： %@, 剩余份数： %d", data, weakSelf.copies); // 调试打印进度 / Debug remaining copies.
        if (weakSelf.copies <= 0) {
            weakSelf.isPrinting = NO;
            weakSelf.displayLabel.text = AYLocalizedString(@"打印完成");
            weakSelf.copies = weakSelf.copiesLabel.text.intValue;
            return;
        };
        if (weakSelf.isLabel) {
            [weakSelf labelPrint];
        } else {
            [weakSelf continuousPrint];
        }
    };
    
    // 打印机反馈回调 / Printer auto-report callback.
    self.bleHelper.onPrinterAutoReport = ^(NSData *data) {
        // NSLog(@"收到打印机反馈： %@", data); // 调试原始反馈数据 / Debug raw auto-report data.
        const Byte *bytes = data.bytes;
        /// 主动上报纸张类型 / Auto-reported paper type.
        if(data.length == 2 && bytes[0] == (Byte)0xFE){
            switch (bytes[1]) {
                case 1:
                    NSLog(@"%@", AYLocalizedString(@"onPaperError: 折叠黑标纸"));
                    break;
                case 2:
                    NSLog(@"%@", AYLocalizedString(@"onPaperError: 连续卷简纸"));
                    break;
                case 3:
                    NSLog(@"%@", AYLocalizedString(@"onPaperError: 不干胶缝隙纸"));
                    break;
                    
                default:
                    break;
            }
        }
         
        /// 上报设备状态 / Auto-reported device status.
        if (data.length == 2 && bytes[0] == (Byte)0xFF) {
            if ((bytes[1]) ==  0) {
                NSLog(@"%@", AYLocalizedString(@"打印机正常"));
            } else {
                if ((bytes[1] & (Byte)0x01) ==  (Byte)0x01) {
                    NSLog(@"%@", AYLocalizedString(@"打印机过热"));
                }
                if ((bytes[1] & (Byte)0x02) ==  (Byte)0x02) {
                    NSLog(@"%@", AYLocalizedString(@"打印机开盖"));
                }
                if ((bytes[1] & (Byte)0x04) ==  (Byte)0x04) {
                    NSLog(@"%@", AYLocalizedString(@"打印机缺纸"));
                }
                if ((bytes[1] & (Byte)0x08) ==  (Byte)0x08) {
                    NSLog(@"%@", AYLocalizedString(@"打印机低压"));
                }
                if ((bytes[1] & (Byte)0x10) ==  (Byte)0x10) {
                    NSLog(@"%@", AYLocalizedString(@"请使用PikDik品牌标签，获得更好的打印体验"));
                }
            }
        }
        
        /// 上报中止打印机状态命令 / Auto-reported cancel-print command status.
        if (data.length == 2 && bytes[0] == (Byte)0xFD) {
            switch (bytes[1]) {
                case 1:
                    NSLog(@"%@", AYLocalizedString(@"开始清除当前页面打印任务（中止命令）"));
                    break;
                case 2:
                    NSLog(@"%@", AYLocalizedString(@"清除当前打印任务结束"));
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
/// 标签纸 / 黑标纸 / Label paper or black mark paper.
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
    NSLog(@"%@", AYLocalizedString(@"打印中，请勿发其他指令，会有干扰！！！"));
}

/// 连续纸 / Continuous paper.
- (IBAction)continuousPrint {
//    Xnip2024-09-07_08-24-20.png // 调试截图名 / Debug screenshot name.
    UIImage *image = [UIImage imageNamed:@"qmsht.jpg"];
    
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
    NSLog(@"%@", AYLocalizedString(@"打印中，请勿发其他指令，会有干扰！！！"));
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
   
  
  UIAlertController *alertController = [UIAlertController alertControllerWithTitle:AYLocalizedString(@"设置溶度") message:nil preferredStyle:UIAlertControllerStyleAlert];
  UIAlertAction *tsplAction = [UIAlertAction actionWithTitle:AYLocalizedString(@"高") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
    [self.esc clean];
    [self.esc thickness:EThicknessHigh];
    [self.bleHelper writeCommands:self.esc.commands];
  }];
  UIAlertAction *escAction = [UIAlertAction actionWithTitle:AYLocalizedString(@"中") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
    [self.esc clean];
    [self.esc thickness:EThicknessMedium];
    [self.bleHelper writeCommands:self.esc.commands];
  }];
  UIAlertAction *cpclAction = [UIAlertAction actionWithTitle:AYLocalizedString(@"低") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
    [self.esc clean];
    [self.esc thickness:EThicknessLow];
    [self.bleHelper writeCommands:self.esc.commands];
  }];
  UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:AYLocalizedString(@"取消") style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
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
#warning 仅适用于部分机型，请勿随意升级 / Only supported on some models. Do not upgrade casually.
- (IBAction)ota:(id)sender {
    if (self.isPrinting) return;
    __weak typeof(self) weakSelf = self;
    self.ota.progressChange = ^(int progress) {
        weakSelf.displayLabel.text = [NSString stringWithFormat:AYLocalizedString(@"升级进度：%d / 100"), progress];
        [weakSelf.otaProgressView setProgress:progress / 100.0];
    };
    self.ota.otaStateChange = ^(OtaState state) {
        switch (state) {
            case OtaStateStart:
                NSLog(@"%@", AYLocalizedString(@"开始升级"));
                break;
            case OtaStateFail:
                NSLog(@"%@", AYLocalizedString(@"升级失败"));
                weakSelf.displayLabel.text = AYLocalizedString(@"开始升级");
                break;
            case OtaStateSuccess:
                NSLog(@"%@", AYLocalizedString(@"升级成功"));
                weakSelf.displayLabel.text = AYLocalizedString(@"升级成功");
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
