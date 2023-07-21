//
//  ESCVC.m
//  BleDemo
//
//  Created by IPRT on 2022/11/22.
//

#import "ESCVC.h"
#import "DataTool.h"
#import "Types.h"

@interface ESCVC ()<ConnectedDeviceDelegate>

@property (nonatomic) NSLock *lock;
@property (nonatomic) NSThread * myThread;
@property (nonatomic, assign) SEARCHTYPE searchType;
@property (nonatomic, strong) BasicESC *basicESC;
@property (nonatomic, strong) Lifecycle *lifeCycle;
@property (strong, nonatomic) ReadOptions *options;
@property (assign, nonatomic) int count;

@property (weak, nonatomic) IBOutlet UILabel *countLab;
@property (weak, nonatomic) IBOutlet UITextField *countTxf;
@property (weak, nonatomic) IBOutlet UILabel *resultLab;
@property (weak, nonatomic) IBOutlet UILabel *stateLab;

@end

@implementation ESCVC

- (void)viewDidLoad {
    [super viewDidLoad];
    _lifeCycle = [[Lifecycle alloc]init];
    _lifeCycle.connectedDevice(self.device);
    _basicESC = [[BasicESC alloc] init];
    _basicESC.BasicESC(_lifeCycle, ESCPrinter_GENERIC);
    __weak typeof (self) weakSelf = self;
    
    self.countLab.text = NSLocalizedString(@"sample.number", nil);;
    
    _basicESC.bleDidConnectPeripheral = ^(CBPeripheral * _Nonnull peripheral) {
        NSLog(@"bleDidConnectPeripheral...");
        __strong typeof (weakSelf) strongSelf = weakSelf;
        [strongSelf.device start:@"FF00" on:peripheral];
        strongSelf.stateLab.text = [NSString stringWithFormat:NSLocalizedString(@"connect.status.succeed:%@", nil),peripheral.name];
    };
    _basicESC.bleDidDisconnectPeripheral = ^(CBPeripheral * _Nonnull peripheral, NSError * _Nonnull error) {
        __strong typeof (weakSelf) strongSelf = weakSelf;
        NSLog(@"⚠️⚠️⚠️ device: %@ did disconnect ⚠️⚠️⚠️", peripheral.name);
        [strongSelf.navigationController popViewControllerAnimated:YES];
    };
    _basicESC.bleDidFailToConnectPeripheral = ^(CBPeripheral * _Nonnull peripheral, NSError * _Nonnull error) {
        NSLog(@"bleDidFailToConnectPeripheral...");
        __strong typeof (weakSelf) strongSelf = weakSelf;
            strongSelf.stateLab.text = [NSString stringWithFormat:NSLocalizedString(@"connect.status.failed:%@", nil),peripheral.name];
    };
    _basicESC.didStart = ^(BOOL result) {
        __strong typeof (weakSelf) strongSelf = weakSelf;
        if(!result){
            strongSelf.stateLab.text = [NSString stringWithFormat:NSLocalizedString(@"connect.status.turn_on:%@", nil),strongSelf.peripheral.name];
        }
    };
    
    _basicESC.read = ^(NSData *revData, NSError *error) {
        NSLog(@"_basicESC.read : %@", revData);
//        __strong typeof (weakSelf) strongSelf = weakSelf;
        if(revData == nil) return;
        const Byte *revByte = revData.bytes;
        if(revData.length == 2 && revByte[0] == (Byte)0xFE){
            switch (revByte[1]) {
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
         
        
        if (revData.length == 2 && revByte[0] == (Byte)0xFF) {
            
            if ((revByte[1]) ==  0) {
                NSLog(@"打印机正常");
            } else {
                if ((revByte[1] & (Byte)0x01) ==  (Byte)0x01) {
                    NSLog(@"打印机缺纸");
                }
                if ((revByte[1] & (Byte)0x02) ==  (Byte)0x02) {
                    NSLog(@"打印机开盖");
                }
                if ((revByte[1] & (Byte)0x03) ==  (Byte)0x03) {
                    NSLog(@"打印机过热");
                }
                if ((revByte[1] & (Byte)0x04) ==  (Byte)0x04) {
                    NSLog(@"打印机低电量");
                }
                if ((revByte[1] & (Byte)0x08) ==  (Byte)0x08) {
                    NSLog(@"打印机自动返回合盖，前提要打印机支持此功能");
                }
            }
        }
    };
    
    self.stateLab.text = [NSString stringWithFormat:NSLocalizedString(@"connect.status.succeed:%@", nil) ,self.peripheral.name];
    
    [self performSelector:@selector(printerInfo) withObject:nil afterDelay:2];
}

- (void)printerInfo {
    NSLog(@"printerInfo");
    _searchType = PRINTERINFOR;
    _basicESC.printerInfo().write();
    [self read];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self.device disconnect];
}

#pragma mark - 点击
- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [self.view endEditing:YES];
}

- (IBAction)labelPrint {
    self.count = self.countTxf.text.intValue;
    _myThread = [[NSThread alloc] initWithTarget:self selector:@selector(labelPaperPrint) object:nil];
    [_myThread start];
}

-(void)labelPaperPrint {
    [_lock lock];
    _basicESC.paperType(paperTypeOne).write();
    _basicESC.enable().write();
    for (int i = 0; i < self.count; i++) {
        EImage *arg = [[EImage alloc]init].image([UIImage imageNamed:@"stamp.jpg"]).width(0).height(0).mode(NORMAL).reverse(false).compress(false);
        _basicESC.wakeup().lineDot(30).image(arg).lineDot(0x64).position().write();
        _basicESC.stopJob().write();
        self.options.callBack = ^(NSData *revData, NSError *error) {
            NSLog(@"labelPaperPrint : %@", revData);
        };
    }
    [_lock unlock];
}

- (IBAction)continuousPrint {
    self.count = self.countTxf.text.intValue;
    self.options = nil;
    _myThread = [[NSThread alloc] initWithTarget:self selector:@selector(continuousPaperPrint) object:nil];
    [_myThread start];
}

-(void)continuousPaperPrint {
    _basicESC.paperType(paperTypeTwo).write();
    for (int i = 0; i< self.count; i++) {
        [_lock lock];
        EImage *arg = [[EImage alloc]init].image([UIImage imageNamed:@"stamp.jpg"]).width(0).height(0).mode(NORMAL).reverse(false).compress(false);
        _basicESC.enable().wakeup().image(arg).lineDot(20).stopJob().write();
        self.options.callBack = ^(NSData *revData, NSError *error) {
            if(error || !revData) return;
            // NSLog(@"continuousPaperPrint : %@", revData);
        };
        [_basicESC read:self.options];
        [_lock unlock];
    }
}

- (IBAction)batteryLevel {
    self.searchType = BATTERYVOL;
    _basicESC.batteryVolume().write();
    [self read];
}

- (IBAction)btName {
    self.searchType = BTNAME;
    _basicESC.name().write();
    [self read];
}

- (IBAction)btVersion {
    self.searchType = BTVERSION;
    _basicESC.version().write();
    [self read];
}

- (IBAction)snNum {
    self.searchType = PRINTERSN;
    _basicESC.sn().write();
    [self read];
}

- (IBAction)printerState {
    self.searchType = PRINTSTATUS;
    _basicESC.state().write();
    [self read];
}

- (IBAction)printerMac {
    self.searchType = MAC;
    _basicESC.mac().write();
    [self read];
}

- (IBAction)printerFirmwareVersion {
    self.searchType = PRINTERVERSION;
    _basicESC.printerVersion().write();
    [self read];
}

- (IBAction)printerModel {
    self.searchType = PRINTERMODEL;
    _basicESC.model().write();
    [self read];
}
- (IBAction)nfcClick {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"NFC" message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    UIAlertAction *action1 = [UIAlertAction actionWithTitle:@"标签纸张信息" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        self.searchType = NfcPaper;
        self.basicESC.nfcPaper().write();
        [self read];
    }];
    UIAlertAction *action2 = [UIAlertAction actionWithTitle:@"标签UID" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        self.searchType = NfcUID;
        self.basicESC.nfcUID().write();
        [self read];
    }];
    UIAlertAction *action3 = [UIAlertAction actionWithTitle:@"标签使用长度" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        self.searchType = NfcUsedLength;
        self.basicESC.nfcUsedLength().write();
        [self read];
    }];
    UIAlertAction *action4 = [UIAlertAction actionWithTitle:@"标签剩余长度" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        self.searchType = NfcRestLength;
        self.basicESC.nfcRestLength().write();
        [self read];
    }];
    UIAlertAction *cancle = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {}];
    
    [alert addAction:action1];
    [alert addAction:action2];
    [alert addAction:action3];
    [alert addAction:action4];
    [alert addAction:cancle];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)read {
    __weak typeof (self) weakSelf = self;
    self.options.callBack = ^(NSData * _Nonnull revData, NSError * _Nullable error) {
        if(error || !revData) return;
        [weakSelf readData:revData];
    };
    [self.basicESC read:self.options];
}

#pragma mark - update
-(void)readData:(NSData *)revData{
    if(revData == nil) return;
    NSString *text = [NSString string];
    Byte *revByte = (Byte *)[revData bytes];
    NSString *receivedStr = [DataTool dataToString:revData];
    switch (_searchType) {
        case PRINTERINFOR:
            text = [NSString stringWithFormat:@"%@: %@",NSLocalizedString(@"print.info", nil) , [DataTool dataToString:revData]];
            break;
        case BTNAME:
            text = [NSString stringWithFormat:@"%@: %@",NSLocalizedString(@"name.bluetooth", nil) , [DataTool dataToString:revData]];
            break;
        case PRINTSTATUS:
            text = [NSString stringWithFormat:@"%@: %hhu", NSLocalizedString(@"status.printer", nil), revByte[0]];
            break;
        case BATTERYVOL:
            text = [NSString stringWithFormat:@"%@: %hhu ",NSLocalizedString(@"battery.level", nil) , revByte[1]];
            break;
        case MAC:
            text = [NSString stringWithFormat:@"%@: %@", NSLocalizedString(@"MAC.address.bluetooth", nil), [DataTool dataToHex:revData]];
            break;
        case BTVERSION:
            text = [NSString stringWithFormat:@"%@: %@", NSLocalizedString(@"version.bluetooth_firmware", nil), [DataTool dataToString:revData]];
            break;
        case PRINTERVERSION:
            text = [NSString stringWithFormat:@"%@: %@",NSLocalizedString(@"version.printer_firmware", nil), [DataTool dataToString:revData]];
            break;
        case PRINTERSN:
            text = [NSString stringWithFormat:@"%@: %@",NSLocalizedString(@"SN.printer", nil), [DataTool dataToString:revData]];
            break;
        case PRINTERMODEL:
            text = [NSString stringWithFormat:@"%@: %@",NSLocalizedString(@"model.printer", nil), [DataTool dataToString:revData]];
            break;
        case NfcPaper: {
                if(receivedStr != nil && [receivedStr isEqualToString:@"ER"]) {
                    text = @"纸张信息: ER";
                } else if (receivedStr != nil) {
                    text = [NSString stringWithFormat:@"纸张信息: %@", receivedStr];
                    NSArray *infos = [receivedStr componentsSeparatedByString:@"|"];
                    NSMutableDictionary *paperInfo = [NSMutableDictionary dictionary];
                    [paperInfo setValue:infos[0] forKey:@"pModel"];  // 纸张型号
                    [paperInfo setValue:infos[1] forKey:@"pWidth"];  // 纸张宽度
                    [paperInfo setValue:infos[2] forKey:@"pHeight"]; // 纸张高度
                    [paperInfo setValue:infos[3] forKey:@"color"];   // 颜色: 1 代表白色
                    NSLog(@"\n纸张信息: %@", paperInfo);
                }
            }
            break;
        case NfcUID: {
            text = [NSString stringWithFormat:@"纸张UID: %@", [[DataTool dataToHex:revData].uppercaseString stringByReplacingOccurrencesOfString:@" " withString:@":"] ];
            if(receivedStr != nil && [receivedStr isEqualToString:@"ER"]) {
                text = @"纸张UID: ER";
            }
        }
            break;
        case NfcUsedLength: {
            int value = CFSwapInt32BigToHost(*(int*)([revData bytes]));
            text = [NSString stringWithFormat:@"纸张使用长度: %d", value];
            if(receivedStr != nil && [receivedStr isEqualToString:@"ER"]) {
                text = @"纸张使用长度: ER";
            }
        }
            break;
        case NfcRestLength: {
            int value = CFSwapInt32BigToHost(*(int*)([revData bytes]));
            text = [NSString stringWithFormat:@"纸张剩余长度: %d", value];
            if(receivedStr != nil && [receivedStr isEqualToString:@"ER"]) {
                text = @"纸张剩余长度: ER";
            }
        }
            break;
            
        default:
            break;
    }
    NSLog(@"%s - %@", __func__, revData);
    NSLog(@"%s - %@", __func__, text);
    
    self.resultLab.text = text;
}

#pragma mark - lazy
- (ReadOptions *)options {
    if(!_options) {
        _options = [ReadOptions new].timeout(1000);
    }
    return _options;
}

@end
