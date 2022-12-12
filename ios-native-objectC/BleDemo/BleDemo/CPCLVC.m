//
//  CPCLVC.m
//  BleDemo
//
//  Created by IPRT on 2022/11/22.
//

#import "CPCLVC.h"
#import <cpcl/cpcl.h>
#import <cpcl/BasicCPCL.h>
@interface CPCLVC ()
@property (nonatomic , strong)UITextField *tfNum;
@property (nonatomic , strong)UILabel *labStatus;
@property (nonatomic) NSLock *lock;
@property (nonatomic) NSThread* myThread;
@property (nonatomic , strong) CBPeripheral *currentConnectedPeripheral;
@property (nonatomic , strong) BasicCPCL *basicCPCL;
@property (nonatomic , strong) Lifecycle *lifeCycle;
@end

@implementation CPCLVC

- (void)viewDidLoad {
    [super viewDidLoad];
    _lifeCycle = [[Lifecycle alloc]init];
    _lifeCycle.connectedDevice(self.device);
    _basicCPCL = [[BasicCPCL alloc]init];
    _basicCPCL.BasicCPCL(_lifeCycle, CPCLPrinter_GENERIC);
    __weak typeof (self) weakSelf = self;
    _basicCPCL.read = ^(NSData * _Nonnull revData, NSError * _Nullable error) {
     
        
    };
   
    _basicCPCL.bleDidConnectPeripheral = ^(CBPeripheral * _Nonnull peripheral) {
        __strong typeof (weakSelf) strongSelf = weakSelf;
        strongSelf.labStatus.text = [NSString stringWithFormat:@"连接状态：%@ 连接成功",peripheral.name];
    };
    _basicCPCL.bleDidDisconnectPeripheral = ^(CBPeripheral * _Nonnull peripheral, NSError * _Nonnull error) {
        __strong typeof (weakSelf) strongSelf = weakSelf;
        strongSelf.labStatus.text = [NSString stringWithFormat:@"连接状态：%@ 连接断开",peripheral.name];
    };
    _basicCPCL.bleDidFailToConnectPeripheral = ^(CBPeripheral * _Nonnull peripheral, NSError * _Nonnull error) {
        __strong typeof (weakSelf) strongSelf = weakSelf;
        strongSelf.labStatus.text = [NSString stringWithFormat:@"连接状态：%@ 连接失败",peripheral.name];
    };
    _basicCPCL.didStart = ^(BOOL result) {
        __strong typeof (weakSelf) strongSelf = weakSelf;
        if(!result){
            strongSelf.labStatus.text = [NSString stringWithFormat:@"连接状态：%@ 打印机开启失败",strongSelf.peripheral.name];
        }
    };
    self.titleStr = @"CPCL";
    [self.contentView addSubview:self.tfNum];
    
    UIButton *btn1 =[[UIButton alloc]initWithFrame:CGRectMake(20 , 64, ([UIScreen mainScreen].bounds.size.width - 60)/2.0, 50)];
    [btn1 setTitle:@"打印图片" forState:UIControlStateNormal];
    [btn1 setBackgroundColor:UIColor.lightGrayColor];
    [btn1 addTarget:self action:@selector(printBarcodeAction) forControlEvents:UIControlEventTouchUpInside];
    btn1.layer.cornerRadius = 10;
    btn1.layer.masksToBounds = YES;
    [btn1 setTitleColor:UIColor.blackColor forState:UIControlStateNormal];
    btn1.titleLabel.font = [UIFont systemFontOfSize:14];
    [self.contentView addSubview:btn1];
    UIButton *btn2 =[[UIButton alloc]initWithFrame:CGRectMake(([UIScreen mainScreen].bounds.size.width )/2.0 +10 , 64,([UIScreen mainScreen].bounds.size.width - 60)/2.0, 50)];
    [btn2 setTitle:@"打印二维码" forState:UIControlStateNormal];
    [btn2 setBackgroundColor:UIColor.lightGrayColor];
    [btn2 addTarget:self action:@selector(printQrcodeAction) forControlEvents:UIControlEventTouchUpInside];
    btn2.layer.cornerRadius = 10;
    btn2.layer.masksToBounds = YES;
    [btn2 setTitleColor:UIColor.blackColor forState:UIControlStateNormal];
    btn2.titleLabel.font = [UIFont systemFontOfSize:14];
    [self.contentView addSubview:btn2];
    UIButton *btn3 =[[UIButton alloc]initWithFrame:CGRectMake(20 , 134, [UIScreen mainScreen].bounds.size.width - 40, 50)];
    [btn3 setTitle:@"打印模版 76*130" forState:UIControlStateNormal];
    [btn3 setBackgroundColor:UIColor.lightGrayColor];
    [btn3 addTarget:self action:@selector(printModeAction) forControlEvents:UIControlEventTouchUpInside];
    btn3.layer.cornerRadius = 10;
    btn3.layer.masksToBounds = YES;
    [btn3 setTitleColor:UIColor.blackColor forState:UIControlStateNormal];
    btn3.titleLabel.font = [UIFont systemFontOfSize:14];
    [self.contentView addSubview:btn3];
    UIButton *btn4 =[[UIButton alloc]initWithFrame:CGRectMake(20 , 194, [UIScreen mainScreen].bounds.size.width - 40, 50)];
    [btn4 setTitle:@"打印测试" forState:UIControlStateNormal];
    [btn4 setBackgroundColor:UIColor.lightGrayColor];
    [btn4 addTarget:self action:@selector(printTestAction) forControlEvents:UIControlEventTouchUpInside];
    btn4.layer.cornerRadius = 10;
    btn4.layer.masksToBounds = YES;
    [btn4 setTitleColor:UIColor.blackColor forState:UIControlStateNormal];
    btn4.titleLabel.font = [UIFont systemFontOfSize:14];
    [self.contentView addSubview:btn4];
    [self.contentView addSubview:self.labStatus];
    self.labStatus.text = [NSString stringWithFormat:@"连接状态：%@ 连接成功",self.peripheral.name];
    [self.labStatus mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.mas_equalTo(self.contentView);
        make.bottom.mas_equalTo(self.contentView).mas_offset(-[UIDevice p_safeDistanceBottom]);
        make.height.mas_equalTo(44);
    }];
    // Do any additional setup after loading the view.
}
-(void)printImage{
    [_lock lock];
    _basicCPCL.page([[CPage alloc]init].width(608).height(600)).image([[CImage alloc]init].image([UIImage imageNamed:@"test"]).startX(0).startY(0)).print([[CPrint alloc]init]).write();
    [_lock unlock];
}
-(void)printBarcodeAction{
    [self printImage];
}
-(void)printQrcodeAction{
_basicCPCL.page([[CPage alloc]init].width(100).height(100))
    .text([[CText alloc]init].content(@"helloworld"))
    .print([[CPrint alloc]init]);
    NSLog(@"____:%@",[[_basicCPCL command] hex]);
    _basicCPCL.write();
}
-(void)printTestAction{
    _myThread = [[NSThread alloc] initWithTarget:self selector:@selector(printText) object:self];
        [_myThread start];
}

-(void)printText{
    [_lock lock];
//    Byte bytes[3] = { 0x10,0xFF,0xBF};
//        NSData *data = [[NSData alloc]initWithBytes:bytes length:3];
//    Builder *builder = [Builder commandWithBinary:data];
//    builder.isNewline = false;
    //        Raw *raw = [Raw createRawWithBuilder:builder];
 
//
//        .page
//    ([[CPage alloc]init]
//                    .width(100)
//                    .height(100))
//    .text([[CText alloc]init].content(@"哈哈哈哈哈哈"))
//    .print([[CPrint alloc]init])
//                    .
//    .write();
//    Command *command = [_basicCPCL command];

//    NSLog(@"String:%@\ndata:%@\nhex:%@",[command string],[command binary],[command hex]);
//    _basicCPCL.write();
//    Command *command1 = [_basicCPCL command];
//
//    NSLog(@"end:\nString:%@\ndata:%@\nhex:%@",[command1 string],[command1 binary],[command1 hex]);
//    [self safeWriteAndRead:_basicCPCL];
    [_lock unlock];
}
-(void)printModeAction{
    int sampleNumber = 1;
    [_lock lock];
    _basicCPCL.page([[CPage alloc]init].width(608).height(1040).num(sampleNumber))
            .box([[CBox alloc]init].topLeftX(0).topLeftY(1).bottomRightX(598).bottomRightY(664).width(2))
            .line([[CLine alloc]init].startX(0).startY(88).endX(598).endY(88).lineWidth(2))
            .line([[CLine alloc]init].startX(0).startY(88+128).endX(598).endY(88+128).lineWidth(2) )
            .line([[CLine alloc]init].startX(0).startY(88+128+80).endX(598).endY(88+128+80).lineWidth(2) )
            .line([[CLine alloc]init].startX(0).startY(88+128+80+144).endX(598-56-16).endY(88+128+80+144).lineWidth(2) )
            .line([[CLine alloc]init].startX(0).startY(88+128+80+144+128).endX(598-56-16).endY(88+128+80+144+128).lineWidth(2) )
            .line([[CLine alloc]init].startX(52).startY(88+128+80).endX(52).endY(88+128+80+144+128).lineWidth(2) )
            .line([[CLine alloc]init].startX(598-56-16).startY(88+128+80).endX(598-56-16).endY(664).lineWidth(2) )
            .bar([[CBar alloc]init].x(120).y(100).lineWidth(1).height(80).content(@"1234567890").codeType(CODE128).codeRotation(CCODEROTATION_0))
            .text([[CText alloc]init].textX(120+12).textY(88+20+76).font(TSS24).content(@"1234567890") )
            .text([[CText alloc]init].textX(12).textY(88 +128 + 80 +32).font(TSS24).content(@"收") )
            .text([[CText alloc]init].textX(12).textY(88 +128 + 80 +96).font(TSS24).content(@"件") )
            .text([[CText alloc]init].textX(12).textY(88+128+80+144+32).font(TSS24).content(@"发") )
            .text([[CText alloc]init].textX(12).textY(88+128+80+144+80).font(TSS24).content(@"件") )
            .text([[CText alloc]init].textX(52+20).textY(88+128+80+144+128+16).font(TSS24).content(@"签收人/签收时间") )
            .text([[CText alloc]init].textX(430).textY(88+128+80+144+128+36).font(TSS24).content(@"月") )
            .text([[CText alloc]init].textX(490).textY(88+128+80+144+128+36).font(TSS24).content(@"日") )
            .text([[CText alloc]init].textX(52+20).textY(88+128+80+24).font(TSS24).content(@"收姓名 13777777777") )
            .text([[CText alloc]init].textX(52+20).textY(88 +128+80+24+32).font(TSS24).content(@"南京市浦口区威尼斯水城七街区七街区") )
            .text([[CText alloc]init].textX(52+20).textY(88+128+80+144+24).font(TSS24).content(@"名字 13777777777") )
            .text([[CText  alloc]init].textX(52+20).textY(88+128+80+144+24+32).font(TSS24).content(@"南京市浦口区威尼斯水城七街区七街区") )
            .text([[CText alloc]init].textX(598-56-5).textY(88 +128+80+104).font(TSS24).content(@"派") )
            .text([[CText alloc]init].textX(598-56-5).textY(88 +128+80+160).font(TSS24).content(@"件") )
            .text([[CText alloc]init].textX(598-56-5).textY(88 +128+80+208).font(TSS24).content(@"联") )
            .box([[CBox alloc]init].topLeftX(0).topLeftY(1).bottomRightX(598).bottomRightY(968).width(2) )
            .line([[CLine alloc]init].startX(0).startY(696+80).endX(598).endY(696+80).lineWidth(2) )
            .line([[CLine alloc]init].startX(0).startY(696+80+136).endX(598-56-16).endY(696+80+136).lineWidth(2) )
            .line([[CLine alloc]init].startX(52).startY(80).endX(52).endY(696+80+136).lineWidth(2) )
            .line([[CLine alloc]init].startX(598-56-16).startY(80).endX(598-56-16).endY(968).lineWidth(2) )
            .bar([[CBar alloc]init].x(320).y(696-4).lineWidth(1).height(56).content(@"1234567890").codeType(CODE128).codeRotation(CCODEROTATION_0) )
            .text([[CText alloc]init].textX(320+8).textY(696+54).font(TSS16).content(@"1234567890") )
            .text([[CText alloc]init].textX(12).textY(696+80+35).font(TSS24).content(@"发") )
            .text([[CText alloc]init].textX(12).textY(696+80+84).font(TSS24).content(@"件") )
            .text([[CText alloc]init].textX(52+20).textY(696+80+28).font(TSS24).content(@"名字 13777777777") )
            .text([[CText alloc]init].textX(52+20).textY(696+80+28+32).font(TSS24).content(@"南京市浦口区威尼斯水城七街区七街区") )
            .text([[CText alloc]init].textX(598-56-5).textY(696+80+50).font(TSS24).content(@"客") )
            .text([[CText alloc]init].textX(598-56-5).textY(696+80+82).font(TSS24).content(@"户") )
            .text([[CText alloc]init].textX(598-56-5).textY(696+80+106).font(TSS24).content(@"联") )
            .text([[CText  alloc]init].textX(12+8).textY(696+80+136+22-5).font(TSS24).content(@"物品：几个快递 12kg") )
            .box([[CBox alloc]init].topLeftX(598-56-16-120).topLeftY(696+80+136+11).bottomRightX(598-56-16-16).bottomRightY(968-11).width(2) )
            .text([[CText alloc]init].textX(598-56-16-120+17).textY(696+80+136+11+6).font(TSS24).content(@"已验视") )
            .print([[CPrint alloc]init] ).feed();
    Command *command = [_basicCPCL command];
//    NSLog(@"String:%@\ndata:%@\nhex:%@",[command string],[command binary],[command hex]);
   NSString *str = [self safeWriteAndRead:_basicCPCL];
    NSLog(@"----:%@",str);
    [_lock unlock];
}
-(NSString *)safeWriteAndRead:(PSDK *)psdk{
    @try {
        WroteReporter *reporter = psdk.write();
        if(![reporter getIsOk]) @throw @"写入失败";
        sleep(200);
        return @"可能写入成功";
//        NSData *bytes = psdk
    } @catch (NSException *exception) {
        return @"写入可能失败";
    } @finally {
        
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
        lab.text = @"样单数";
        lab.font = [UIFont systemFontOfSize:14];
        lab.textAlignment = NSTextAlignmentRight;
        lab.textColor = UIColor.blackColor;
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
/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
