//
//  ESCVC.m
//  BleDemo
//
//  Created by IPRT on 2022/11/22.
//

#import "ESCVC.h"
#import "ESCButtonView.h"
@interface ESCVC ()
@property (nonatomic , strong) UILabel *labResult;
@property (nonatomic) NSLock *lock;
@property (nonatomic) NSThread* myThread;
@property (nonatomic , assign) SEARCHTYPE searchType;
@property (nonatomic , strong) CBPeripheral *currentConnectedPeripheral;
@property (nonatomic , strong) BasicESC *basicESC;
@property (nonatomic , strong) Lifecycle *lifeCycle;
@property (nonatomic , strong)ESCButtonView *buttonView;
@property (nonatomic , strong)UITextField *tfNum;
@property (nonatomic , strong)UILabel *labStatus;
@property (nonatomic , assign)int totalCount;
@end

@implementation ESCVC

- (void)viewDidLoad {
    [super viewDidLoad];
    _lifeCycle = [[Lifecycle alloc]init];
    _lifeCycle.connectedDevice(self.device);
    self.titleStr = @"ESC";
    _basicESC = [[BasicESC alloc]init];
    _basicESC.BasicESC(_lifeCycle, ESCPrinter_GENERIC);
    __weak typeof (self) weakSelf = self;
//    _basicESC.read = ^(NSData * _Nonnull revData, NSError * _Nullable error) {
//        if(error){
//            return;
//        }
//         __strong typeof (weakSelf) strongSelf = weakSelf;
//        NSString *text = @"";
//        Byte *revByte = (Byte *)[revData bytes];
//        if(strongSelf->_searchType == BTNAME){
//            text = [NSString stringWithFormat:@"蓝牙名称: %@",  [strongSelf hex2string:revData]];}
//        if(strongSelf->_searchType == PRINTSTATUS) {
//            text = [NSString stringWithFormat:@"打印机状态: %hhu",  revByte[0]];}
//        if(strongSelf->_searchType == BATTERYVOL) {
//            text = [NSString stringWithFormat:@"电池电量: %hhu ",  revByte[1]];}
//        if(strongSelf->_searchType == MAC) {text = [NSString stringWithFormat:@"蓝牙MAC地址: %@",  [strongSelf dataToHex:revData]];}
//        if(strongSelf->_searchType == BTVERSION) {text = [NSString stringWithFormat:@"蓝牙固件版本: %@",  [strongSelf hex2string:revData]];}
//        if(strongSelf->_searchType == PRINTERVERSION) {text = [NSString stringWithFormat:@"打印机固件版本: %@",  [strongSelf hex2string:revData]];}
//        if(strongSelf->_searchType == PRINTERSN) {text = [NSString stringWithFormat:@"打印机SN号: %@",  [strongSelf hex2string:revData]];}
//        if(strongSelf->_searchType == PRINTERMODEL) {text = [NSString stringWithFormat:@"打印机型号: %@",  [strongSelf hex2string:revData]];}
//        strongSelf->_labResult.text = text;
//    };
    _basicESC.bleDidConnectPeripheral = ^(CBPeripheral * _Nonnull peripheral) {
        __strong typeof (weakSelf) strongSelf = weakSelf;
        [strongSelf.device start:@"FF00" on:peripheral];
        strongSelf.labStatus.text = [NSString stringWithFormat:NSLocalizedString(@"connect.status.succeed:%@", nil),peripheral.name];
    };
    _basicESC.bleDidDisconnectPeripheral = ^(CBPeripheral * _Nonnull peripheral, NSError * _Nonnull error) {__strong typeof (weakSelf) strongSelf = weakSelf;
        strongSelf.labStatus.text = [NSString stringWithFormat:NSLocalizedString(@"connect.status.disconnected:%@", nil) ,peripheral.name];
    };
    _basicESC.bleDidFailToConnectPeripheral = ^(CBPeripheral * _Nonnull peripheral, NSError * _Nonnull error) {
        __strong typeof (weakSelf) strongSelf = weakSelf;
            strongSelf.labStatus.text = [NSString stringWithFormat:NSLocalizedString(@"connect.status.failed:%@", nil),peripheral.name];
    };
    _basicESC.didStart = ^(BOOL result) {
        __strong typeof (weakSelf) strongSelf = weakSelf;
        if(!result){
            strongSelf.labStatus.text = [NSString stringWithFormat:NSLocalizedString(@"connect.status.turn_on:%@", nil),strongSelf.peripheral.name];
        }
    };
    [self.contentView addSubview:self.tfNum];
    _buttonView = [[ESCButtonView alloc]init];
    [self.contentView addSubview:_buttonView];
    [_buttonView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.mas_equalTo(self.contentView);
        make.top.mas_equalTo(self.tfNum.mas_bottom).mas_offset(20);
        make.height.mas_equalTo(350);
    }];
    _buttonView.nameClick = ^{
        __strong typeof (weakSelf) strongSelf = weakSelf;
        strongSelf->_searchType = BTNAME ;
        [strongSelf nameAction];
    };
    _buttonView.printClick = ^{
        __strong typeof (weakSelf) strongSelf = weakSelf;
        [strongSelf printAction];
    };
    //打印机状态
    _buttonView.printerStatusClick = ^{
        __strong typeof (weakSelf) strongSelf = weakSelf;
        strongSelf->_searchType = PRINTSTATUS;
        [strongSelf printerStatusAction];
        
    };
    //电池电量
    _buttonView.batteryLevelClick = ^{
        __strong typeof (weakSelf) strongSelf = weakSelf;
        strongSelf->_searchType = BATTERYVOL;
        [strongSelf batteryLevelAction];
    };
    //蓝牙MAC地址
    _buttonView.bleMACAddressClick = ^{
        __strong typeof (weakSelf) strongSelf = weakSelf;
        strongSelf->_searchType = MAC;
        [strongSelf bleMACAddressAction];
    };
    //蓝牙固件版本
    _buttonView.bleFirmwareVersionClick = ^{
        __strong typeof (weakSelf) strongSelf = weakSelf;
        strongSelf->_searchType = BTVERSION;
        [strongSelf bleFirmwareVersionAction];
    };
    //打印机固件版本
    _buttonView.printerFirmwareVersionClick = ^{
        __strong typeof (weakSelf) strongSelf = weakSelf;
        strongSelf->_searchType = PRINTERVERSION;
        [strongSelf printerFirmwareVersionAction];
    };
    //打印机SN号
    _buttonView.printerSNNumberClick = ^{
        __strong typeof (weakSelf) strongSelf = weakSelf;
        strongSelf->_searchType = PRINTERSN;
        [strongSelf printerSNNumberAction];
    };
    //打印机型号
    _buttonView.printerModelClick = ^{
        __strong typeof (weakSelf) strongSelf = weakSelf;
        strongSelf->_searchType = PRINTERMODEL;
        [strongSelf printerModelAction];
    };
  
    //打印机型号
    _buttonView.continuousPaperPrintingClick = ^{
        __strong typeof (weakSelf) strongSelf = weakSelf;
        strongSelf->_searchType = PRINTERMODEL;
        [strongSelf printContinuousPaperPrintingClick];
    };
    //打印机型号
    _buttonView.labelPaperPrintingClick = ^{
        __strong typeof (weakSelf) strongSelf = weakSelf;
        strongSelf->_searchType = PRINTERMODEL;
        [strongSelf printLabelPaperPrintingClick];
    };
  
    _labResult = [[UILabel alloc]init];
    _labResult.font = [UIFont systemFontOfSize:14];
    _labResult.backgroundColor = UIColor.grayColor;
    _labResult.textColor = UIColor.orangeColor;
    _labResult.numberOfLines = 0;
    [self.contentView addSubview:_labResult];
    [_labResult mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.mas_equalTo(self.contentView);
        make.top.mas_equalTo(_buttonView.mas_bottom);
        make.height.mas_equalTo(50);
    }];
    [self.contentView addSubview:self.labStatus];
    self.labStatus.text = [NSString stringWithFormat:NSLocalizedString(@"connect.status.succeed:%@", nil),self.peripheral.name];
    [self.labStatus mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.mas_equalTo(self.contentView);
        make.bottom.mas_equalTo(self.contentView).mas_offset(-[UIDevice p_safeDistanceBottom]);
        make.height.mas_equalTo(44);
    }];
    UITapGestureRecognizer *taprg = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(endEditingAction)];
    [self.buttonView addGestureRecognizer:taprg];
    // Do any additional setup after loading the view.
}
-(void)endEditingAction{
    [self.view endEditing:YES];
}
-(void)readData:(NSData *)revData{
    NSString *text = @"";
    Byte *revByte = (Byte *)[revData bytes];
    if(_searchType == BTNAME){
        text = [NSString stringWithFormat:@"%@: %@",NSLocalizedString(@"name.bluetooth", nil) , [self hex2string:revData]];}
    if(_searchType == PRINTSTATUS) {
        text = [NSString stringWithFormat:@"%@: %hhu", NSLocalizedString(@"status.printer", nil), revByte[0]];}
    if(_searchType == BATTERYVOL) {
        text = [NSString stringWithFormat:@"%@: %hhu ",NSLocalizedString(@"battery.level", nil) , revByte[1]];}
    if(_searchType == MAC) {text = [NSString stringWithFormat:@"%@: %@", NSLocalizedString(@"MAC.address.bluetooth", nil), [self dataToHex:revData]];}
    if(_searchType == BTVERSION) {text = [NSString stringWithFormat:@"%@: %@", NSLocalizedString(@"version.bluetooth_firmware", nil), [self hex2string:revData]];}
    if(_searchType == PRINTERVERSION) {text = [NSString stringWithFormat:@"%@: %@",NSLocalizedString(@"version.printer_firmware", nil),  [self hex2string:revData]];}
    if(_searchType == PRINTERSN) {text = [NSString stringWithFormat:@"%@: %@",NSLocalizedString(@"SN.printer", nil) , [self hex2string:revData]];}
    if(_searchType == PRINTERMODEL) {text = [NSString stringWithFormat:@"%@: %@",NSLocalizedString(@"model.printer", nil) , [self hex2string:revData]];}
    _labResult.text = text;
}
-(void)printAction{
    self.totalCount = [self.tfNum.text intValue];
    _myThread = [[NSThread alloc] initWithTarget:self selector:@selector(printTestAction) object:self.buttonView];
        [_myThread start];
}
-(void)printContinuousPaperPrintingClick{
    _searchType = THICKNESS;
    self.totalCount = [self.tfNum.text intValue];
    _myThread = [[NSThread alloc] initWithTarget:self selector:@selector(printContinuousPaperPrintingAction) object:self.buttonView];
    [_myThread start];
}
-(void)printLabelPaperPrintingClick{
    self.totalCount = [self.tfNum.text intValue];
    _myThread = [[NSThread alloc] initWithTarget:self selector:@selector(printLabelPaperPrintingAction) object:self.buttonView];
    [_myThread start];
}
- (NSString *)hex2string:(NSData *) data{
    return [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
}
#pragma mark -- 打印机状态
-(void)printerStatusAction{
    _basicESC.state().write();
    ReadOptions *options = [[ReadOptions alloc]init].timeout(1000);
    options.callBack = ^(NSData * _Nonnull revData, NSError * _Nullable error) {
        if(error) return;
        [self readData:revData];
    };
    [_basicESC read:options];
}
#pragma mark -- 电池电量
-(void)batteryLevelAction{
    _basicESC.batteryVolume().write();
    ReadOptions *options = [[ReadOptions alloc]init].timeout(1000);
    options.callBack = ^(NSData * _Nonnull revData, NSError * _Nullable error) {
        if(error) return;
        [self readData:revData];
    };
    [_basicESC read:options];
}
#pragma mark -- 蓝牙MAC地址
-(void)bleMACAddressAction{
    _basicESC.mac().write();
    ReadOptions *options = [[ReadOptions alloc]init].timeout(1000);
    options.callBack = ^(NSData * _Nonnull revData, NSError * _Nullable error) {
        if(error) return;
        [self readData:revData];
    };
    [_basicESC read:options];
}
#pragma mark -- 蓝牙固件版本
-(void)bleFirmwareVersionAction{
    _basicESC.version().write();
    ReadOptions *options = [[ReadOptions alloc]init].timeout(1000);
    options.callBack = ^(NSData * _Nonnull revData, NSError * _Nullable error) {
        if(error) return;
        [self readData:revData];
    };
    [_basicESC read:options];
}
#pragma mark -- 打印机固件版本
-(void)printerFirmwareVersionAction{
    _basicESC.printerVersion().write();
    ReadOptions *options = [[ReadOptions alloc]init].timeout(1000);
    options.callBack = ^(NSData * _Nonnull revData, NSError * _Nullable error) {
        if(error) return;
        [self readData:revData];
    };
    [_basicESC read:options];
}
#pragma mark -- 打印机SN号
-(void)printerSNNumberAction{
    _basicESC.sn().write();
    ReadOptions *options = [[ReadOptions alloc]init].timeout(1000);
    options.callBack = ^(NSData * _Nonnull revData, NSError * _Nullable error) {
        if(error) return;
        [self readData:revData];
    };
    [_basicESC read:options];
}
#pragma mark -- 打印机型号
-(void)printerModelAction{
    _basicESC.model().write();
    ReadOptions *options = [[ReadOptions alloc]init].timeout(1000);
    options.callBack = ^(NSData * _Nonnull revData, NSError * _Nullable error) {
        if(error) return;
        [self readData:revData];
    };
    [_basicESC read:options];
}

-(void)printTestAction{
    [_lock lock];
    EImage *arg = [[EImage alloc]init].image([UIImage imageNamed:@"test1"]);
    _basicESC.wakeup().lineDot(16).enable().image(arg).lineDot(0x80).position().write();
    _basicESC.stopJob().write();
    [_lock unlock];
}
-(void)printContinuousPaperPrintingAction{
   
    for (int i = 0; i<self.totalCount; i++) {
        [_lock lock];
        EImage *arg = [[EImage alloc]init].image([UIImage imageNamed:@"dkl"]).width(0).height(0).mode(NORMAL).reverse(false).compress(false);
        _basicESC.wakeup().lineDot(1).enable().image(arg).lineDot(1).write();
        NSLog(@"-----:_---:%@",[[_basicESC command]hex]);
        _basicESC.stopJob().write();
        [_lock unlock];}
}
-(void)printLabelPaperPrintingAction{
    for (int i = 0; i<self.totalCount; i++) {
        [_lock lock];
        EImage *arg = [[EImage alloc]init].image([UIImage imageNamed:@"logo2"]).width(0).height(0);
        _basicESC.wakeup().lineDot(1).enable().image(arg).lineDot(1).position().write();
        _basicESC.stopJob().write();
        [_lock unlock];}
}
-(void)nameAction{
    _basicESC.name().write();
    ReadOptions *options = [[ReadOptions alloc]init].timeout(1000);
    options.callBack = ^(NSData * _Nonnull revData, NSError * _Nullable error) {
        if(error) return;
        [self readData:revData];
    };
    [_basicESC read:options];
}
-(NSString *)dataToHex:(NSData *)data{
    if (data.length){
        NSString *string = [[[[NSString stringWithFormat:@"%@",data]
                              stringByReplacingOccurrencesOfString: @"<" withString: @""]
                             stringByReplacingOccurrencesOfString: @">" withString: @""]
                            stringByReplacingOccurrencesOfString: @" " withString: @""];
        NSString *newstring = @"";
        int count = 0;
        for (int i = 0; i < string.length; i++) {
            count++;
            newstring = [newstring stringByAppendingString:[string substringWithRange:NSMakeRange(i, 1)]];
            if (count%2 == 0 &&count!= 12&&count!=24) {
                newstring = [NSString stringWithFormat:@"%@:", newstring];
                
            }
            if(count == 12){
                newstring = [NSString stringWithFormat:@"%@   ", newstring];
            }
        }
        return newstring.uppercaseString;
    }else{
        return @"";
    }
}
-(UITextField *)tfNum{
    if(!_tfNum){
        _tfNum = [[UITextField alloc]initWithFrame:CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width - 20, 44)];
        _tfNum.font = [UIFont systemFontOfSize:14];
        _tfNum.text = @"1";
        _tfNum.textColor = UIColor.blackColor;
        _tfNum.keyboardType = UIKeyboardTypeNumberPad;
        UIView *leftView =[[UIView alloc]initWithFrame:CGRectMake(0, 0, 90, 44)];
        UILabel *lab = [[UILabel alloc]initWithFrame:CGRectMake(0, 0, 70, 44)];
        lab.text = NSLocalizedString(@"sample.number", nil);
        lab.textColor = UIColor.blackColor;
        lab.font = [UIFont systemFontOfSize:14];
        lab.textAlignment = NSTextAlignmentRight;
        [leftView addSubview:lab];
        _tfNum.leftView = leftView;
        _tfNum.leftViewMode = UITextFieldViewModeAlways;
        UIView *line = [[UIView alloc]initWithFrame:CGRectMake(90, 43, [UIScreen mainScreen].bounds.size.width - 110, 1)];
        line.backgroundColor = UIColor.blackColor;
        [_tfNum addSubview:line];
    }
    return _tfNum;
}
-(UILabel *)labStatus{
    if(!_labStatus){
        _labStatus = [[UILabel alloc]init];
        _labStatus.font = [UIFont systemFontOfSize:14];
        _labStatus.textColor = UIColor.whiteColor;
        _labStatus.textAlignment = NSTextAlignmentCenter;
        _labStatus.text = @"乱麻中";
        _labStatus.backgroundColor = UIColor.redColor;
    }
    return _labStatus;
}
@end
