//
//  TSPLVC.m
//  BleDemo
//
//  Created by IPRT on 2022/11/22.
//

#import "TSPLVC.h"
#import <tspl/tspl.h>
#import <tspl/GenericTSPL.h>

@interface TSPLVC ()

@property (weak, nonatomic) IBOutlet UILabel *stateLab;
@property (nonatomic) NSLock *lock;
@property (nonatomic) NSThread* myThread;
@property (nonatomic, strong) BasicTSPL *basicTspl;
@property (nonatomic, strong) Lifecycle *lifeCycle;

@end

@implementation TSPLVC

- (void)viewDidLoad {
    [super viewDidLoad];
    _lifeCycle = [[Lifecycle alloc]init];
    _lifeCycle.connectedDevice(self.device);
    _basicTspl = [[BasicTSPL alloc]init];
    _basicTspl.BasicTSPL(_lifeCycle, TSPLPrinter_GENERIC);
    __weak typeof (self) weakSelf = self;
    _basicTspl.read = ^(NSData * _Nonnull revData, NSError * _Nullable error) {
        NSLog(@"----:%@",revData);
    };
    _basicTspl.bleDidConnectPeripheral = ^(CBPeripheral * _Nonnull peripheral) {
        __strong typeof (weakSelf) strongSelf = weakSelf;
        strongSelf.stateLab.text = [NSString stringWithFormat:NSLocalizedString(@"connect.status.succeed:%@", nil),peripheral.name];
    };
    _basicTspl.bleDidDisconnectPeripheral = ^(CBPeripheral * _Nonnull peripheral, NSError * _Nonnull error) {__strong typeof (weakSelf) strongSelf = weakSelf;
        strongSelf.stateLab.text = [NSString stringWithFormat:NSLocalizedString(@"connect.status.disconnected:%@", nil),peripheral.name];
    };
    _basicTspl.bleDidFailToConnectPeripheral = ^(CBPeripheral * _Nonnull peripheral, NSError * _Nonnull error) {
        __strong typeof (weakSelf) strongSelf = weakSelf;
            strongSelf.stateLab.text = [NSString stringWithFormat:NSLocalizedString(@"connect.status.failed:%@", nil),peripheral.name];
    };
    _basicTspl.didStart = ^(BOOL result) {
        __strong typeof (weakSelf) strongSelf = weakSelf;
        if(!result){
            strongSelf.stateLab.text = [NSString stringWithFormat:NSLocalizedString(@"connect.status.turn_on:%@", nil),strongSelf.peripheral.name];
        }
    };
 
    self.stateLab.text = [NSString stringWithFormat:NSLocalizedString(@"connect.status.succeed:%@", nil),self.peripheral.name];
}

- (IBAction)printImage {
    _myThread = [[NSThread alloc] initWithTarget:self selector:@selector(printImageAction) object:self];
    [_myThread start];
}

-(void)printImageAction{
    [_lock lock];
//    NSString *str = @"SELFTEST";
//    Raw *raw = [Raw createWithText:str];
    
    TImage *tImage = [TImage new]
                    .image([UIImage imageNamed:@"miandan.jpg"])
                    .x(10)
                    .y(10)
                    .width(300)
                    .height(450)
                    .reverse(YES);
    
    _basicTspl
    .page([[TPage alloc]init].width(75).height(130))
    .direction([[TDirection alloc]init].direction(UP_OUT).mirror(NO_MIRROR))
    .cut(true)
    .gap(NO)
    .speed(6)
    .density(10)
    .cls()
    .image(tImage)
    .print();

    _basicTspl.write();
    
    [_lock unlock];
}

- (IBAction)printTemplate{
    _myThread = [[NSThread alloc] initWithTarget:self selector:@selector(printTemplateInMyThread) object:self];
    [_myThread start];
}

-(void)printTemplateInMyThread {
    _basicTspl.page([[TPage alloc]init].width(75).height(130))
    .direction([[TDirection alloc]init].direction(UP_OUT).mirror(NO_MIRROR))
    .gap(NO)
    .cut(true)
    .speed(6)
    .density(6)
    .cls()
    .bar([[TBar alloc]init].x(300).y(10).width(4).height(90))
    .bar([[TBar alloc]init].x(30).y(100).width(740).height(4))
    .bar([[TBar alloc]init].x(30).y(880).width(740).height(4))
    .bar([[TBar alloc]init].x(30).y(1300).width(740).height(4))
    .text([[TText alloc]init].x(400).y(25).font(TSS24).xmulti(3).ymulti(3).content(@"上海浦东"))
    .text([[TText alloc]init].x(30).y(120).font(TSS24).xmulti(1).ymulti(1).content(@"发  件  人：张三 (电话 874236021)"))
    .text([[TText alloc]init].x(30).y(150).font(TSS24).xmulti(1).ymulti(1).content(@"发件人地址：广州省 深圳市 福田区 思创路123号\"工业园\"1栋2楼"))
    .text([[TText alloc]init].x(30).y(200).font(TSS24).xmulti(1).ymulti(1).content(@"收  件  人：李四 (电话 13899658435)"))
    .text([[TText alloc]init].x(30).y(230).font(TSS24).xmulti(1).ymulti(1).content(@"收件人地址：上海市 浦东区 太仓路司务小区9栋1105室"))
    .text([[TText alloc]init].x(30).y(700).font(TSS16).xmulti(1).ymulti(1).content(@"各類郵件禁寄、限寄的範圍，除上述規定外，還應參閱「中華人民共和國海關對"))
    .text([[TText alloc]init].x(30).y(720).font(TSS16).xmulti(1).ymulti(1).content(@"进出口邮递物品监管办法”和国家法令有关禁止和限制邮寄物品的规定，以及邮"))
    .text([[TText alloc]init].x(30).y(740).font(TSS16).xmulti(1).ymulti(1).content(@"寄物品的规定，以及邮电部转发的各国（地区）邮 政禁止和限制。"))
    .text([[TText alloc]init].x(30).y(760).font(TSS16).xmulti(1).ymulti(1).content(@"寄件人承诺不含有法律规定的违禁物品。"))
    .barcode([[TBarCode alloc]init].x(80).y(300).codeType(CODE_128).height(90).showType(SHOW_CENTER).cellwidth(4).content(@"873456093465"))
    .barcode([[TBarCode alloc]init].x(550).y(910).codeType(CODE_128).height(50).showType(SHOW_CENTER).cellwidth(2).content(@"873456093465"))
    .box([[TBox alloc]init].startX(40).startY(500).endX(340).endY(650).width(4).radius(20))
    .text([[TText alloc]init].x(60).y(520).font(TSS24).xmulti(1).ymulti(1).content(@"寄件人签字："))
    .text([[TText alloc]init].x(130).y(625).font(TSS32).xmulti(1).ymulti(1).content(@"2015-10-30 09:09"))
    .text([[TText alloc]init].x(50).y(1000).font(TSS32).xmulti(2).ymulti(3).content(@"广东 ---- 上海浦东"))
    .circle([[TCircle alloc]init].startX(670).startY(1170).width(6).radius(100))
    .text([[TText alloc]init].x(670).y(1170).font(TSS24).xmulti(3).ymulti(3).content(@"碎"))
    .qrcode([[TQRCode alloc]init].x(620).y(620).correctLevel(H).cellWidth(4).content(@"www.qrprt.com   www.qrprt.com   www.qrprt.com"))
    .print();
    
    Command *command = [_basicTspl command];
    NSString * str = [[command string] stringByReplacingOccurrencesOfString:@"\r\n" withString:@"-"];
    NSLog(@"打印的指令String：%@\n-----str:%@",[command string],str);
    
    _basicTspl.write();
}

@end
