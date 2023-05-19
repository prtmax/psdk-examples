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
        if(revData == nil) return;
        const Byte *revByte = revData.bytes;
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
    for (int i = 0; i < self.count; i++) {
        [_lock lock];
        EImage *arg = [[EImage alloc]init].image([UIImage imageNamed:@"miandan.jpg"]).width(0).height(0);
        _basicESC.image(arg).position().write();
        // _basicESC.stopJob().write();
        self.options.callBack = ^(NSData *revData, NSError *error) {
            NSLog(@"labelPaperPrint : %@", revData);
        };
        [_lock unlock];
    }
}

- (IBAction)continuousPrint {
    self.count = self.countTxf.text.intValue;
    self.options = nil;
    _myThread = [[NSThread alloc] initWithTarget:self selector:@selector(continuousPaperPrint) object:nil];
    [_myThread start];
}

-(void)continuousPaperPrint {
    for (int i = 0; i< self.count; i++) {
        [_lock lock];
        EImage *arg = [[EImage alloc]init].image([UIImage imageNamed:@"qmsht.jpg"]).width(0).height(0).mode(NORMAL).reverse(false).compress(NO);
        _basicESC.image(arg).write();
        // _basicESC.stopJob().write();
        self.options.callBack = ^(NSData *revData, NSError *error) {
            NSLog(@"continuousPaperPrint : %@", revData);
        };
        [_basicESC read:self.options];
        [_lock unlock];
    }
}

- (IBAction)batteryLevel {
    __block ESCVC *blockSelf = self;
    self.searchType = BATTERYVOL;
    _basicESC.batteryVolume().write();
    self.options.callBack = ^(NSData * _Nonnull revData, NSError * _Nullable error) {
        if(error || !revData) return;
        [blockSelf readData:revData];
    };
    [_basicESC read:self.options];
}

- (IBAction)btName {
    __block ESCVC *blockSelf = self;
    self.searchType = BTNAME;
    _basicESC.name().write();
    self.options.callBack = ^(NSData * _Nonnull revData, NSError * _Nullable error) {
        if(error || !revData) return;
        [blockSelf readData:revData];
    };
    [_basicESC read:self.options];
}

- (IBAction)btVersion {
    __block ESCVC *blockSelf = self;
    self.searchType = BTVERSION;
    _basicESC.version().write();
    self.options.callBack = ^(NSData * _Nonnull revData, NSError * _Nullable error) {
        if(error || !revData) return;
        [blockSelf readData:revData];
    };
    [_basicESC read:self.options];
}

- (IBAction)snNum {
    __block ESCVC *blockSelf = self;
    self.searchType = PRINTERSN;
    _basicESC.sn().write();
    self.options.callBack = ^(NSData * _Nonnull revData, NSError * _Nullable error) {
        if(error || !revData) return;
        [blockSelf readData:revData];
    };
    [_basicESC read:self.options];
}

- (IBAction)printerState {
    __block ESCVC *blockSelf = self;
    self.searchType = PRINTSTATUS;
    _basicESC.state().write();
    self.options.callBack = ^(NSData * _Nonnull revData, NSError * _Nullable error) {
        if(error || !revData) return;
        [blockSelf readData:revData];
    };
    [_basicESC read:self.options];
}

- (IBAction)printerMac {
    __block ESCVC *blockSelf = self;
    self.searchType = MAC;
    _basicESC.mac().write();
    self.options.callBack = ^(NSData * _Nonnull revData, NSError * _Nullable error) {
        if(error || !revData) return;
        [blockSelf readData:revData];
    };
    [_basicESC read:self.options];
}

- (IBAction)printerFirmwareVersion {
    __block ESCVC *blockSelf = self;
    self.searchType = PRINTERVERSION;
    _basicESC.printerVersion().write();
    self.options.callBack = ^(NSData * _Nonnull revData, NSError * _Nullable error) {
        if(error || !revData) return;
        [blockSelf readData:revData];
    };
    [_basicESC read:self.options];
}

- (IBAction)printerModel {
    __block ESCVC *blockSelf = self;
    self.searchType = PRINTERMODEL;
    _basicESC.model().write();
    self.options.callBack = ^(NSData * _Nonnull revData, NSError * _Nullable error) {
        if(error || !revData) return;
        [blockSelf readData:revData];
    };
    [_basicESC read:self.options];
}

- (void)didStart:(BOOL)result {
    
}

#pragma mark - update
-(void)readData:(NSData *)revData{
    if(revData == nil) return;
    NSString *text = [NSString string];
    Byte *revByte = (Byte *)[revData bytes];
    switch (_searchType) {
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
