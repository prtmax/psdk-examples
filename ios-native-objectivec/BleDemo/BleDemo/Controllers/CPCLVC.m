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

@property (nonatomic) NSLock *lock;
@property (nonatomic) NSThread* myThread;
@property (nonatomic , strong) CBPeripheral *currentConnectedPeripheral;
@property (nonatomic , strong) BasicCPCL *basicCPCL;
@property (nonatomic , strong) Lifecycle *lifeCycle;

@property (weak, nonatomic) IBOutlet UILabel *countTitleLab;
@property (weak, nonatomic) IBOutlet UITextField *countTxf;
@property (weak, nonatomic) IBOutlet UILabel *stateLab;

@end

@implementation CPCLVC

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setUpUI];
    _lifeCycle = [[Lifecycle alloc]init];
    _lifeCycle.connectedDevice(self.device);
    _basicCPCL = [[BasicCPCL alloc]init];
    _basicCPCL.BasicCPCL(_lifeCycle, CPCLPrinter_GENERIC);
    __weak typeof (self) weakSelf = self;
    _basicCPCL.read = ^(NSData * _Nonnull revData, NSError * _Nullable error) {
     
        
    };
   
    _basicCPCL.bleDidConnectPeripheral = ^(CBPeripheral * _Nonnull peripheral) {
        __strong typeof (weakSelf) strongSelf = weakSelf;
        strongSelf.stateLab.text = [NSString stringWithFormat:NSLocalizedString(@"connect.status.succeed:%@", nil),peripheral.name];
    };
    _basicCPCL.bleDidDisconnectPeripheral = ^(CBPeripheral * _Nonnull peripheral, NSError * _Nonnull error) {
        __strong typeof (weakSelf) strongSelf = weakSelf;
        strongSelf.stateLab.text = [NSString stringWithFormat:NSLocalizedString(@"connect.status.disconnected:%@", nil),peripheral.name];
    };
    _basicCPCL.bleDidFailToConnectPeripheral = ^(CBPeripheral * _Nonnull peripheral, NSError * _Nonnull error) {
        __strong typeof (weakSelf) strongSelf = weakSelf;
        strongSelf.stateLab.text = [NSString stringWithFormat:NSLocalizedString(@"connect.status.failed:%@", nil),peripheral.name];
    };
    _basicCPCL.didStart = ^(BOOL result) {
        __strong typeof (weakSelf) strongSelf = weakSelf;
        if(!result){
            strongSelf.stateLab.text = [NSString stringWithFormat:NSLocalizedString(@"connect.status.turn_on:%@", nil),strongSelf.peripheral.name];
        }
    };
    
}

- (void)setUpUI {
    self.stateLab.text = [NSString stringWithFormat:NSLocalizedString(@"connect.status.succeed:%@", nil), self.peripheral.name];
}


#pragma mark - click
- (IBAction)printImage {
    [_lock lock];
    _basicCPCL.page([[CPage alloc]init].width(608).height(600)).image([[CImage alloc]init].image([UIImage imageNamed:@"stamp.jpg"]).startX(0).startY(0).reverse(false).compress(false)).print([[CPrint alloc]init]).write();
    [_lock unlock];
}

- (IBAction)printQRCode {
    _basicCPCL.page([CPage new].width(100).height(100))
    .qrcode([CQRCode new].content(@"123456789"))
    .print([CPrint new]);
    
    _basicCPCL.write();
}

- (IBAction)selfTest {
    Byte bytes[3] = {0x10, 0xFF, 0xbf};
    _basicCPCL.raw([Raw createWithBinary:[NSData dataWithBytes:bytes length:3]]);
    
    _basicCPCL.write();
}


- (IBAction)printTemplate {
    _myThread = [[NSThread alloc] initWithTarget:self selector:@selector(printTemplateInMyThread) object:self];
    [_myThread start];
}

- (void)printTemplateInMyThread {
    int sampleNumber = 1;
    [_lock lock];
    _basicCPCL
    .page([[CPage alloc]init].width(608).height(1040).num(sampleNumber))
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
    
   NSString *str = [self safeWriteAndRead:_basicCPCL];
    NSLog(@"----:%@",str);
    [_lock unlock];
}


-(NSString *)safeWriteAndRead:(PSDK *)psdk{
    @try {
        WroteReporter *reporter = psdk.write();
        if(![reporter getIsOk]) @throw NSLocalizedString(@"write.failed", nil);
        sleep(200);
        return NSLocalizedString(@"write.success", nil);
    } @catch (NSException *exception) {
        return NSLocalizedString(@"write.fail", nil);
    } @finally {
        
    }
}

@end
