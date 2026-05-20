//
//  EscWifiVC.m
//  AYPrinterDemo
//
//  Created by aiyin on 4/22/26.
//

#import "EscWifiVC.h"

typedef NS_ENUM(NSUInteger, WifiOperation) {
  WifiOperatioSet,
  WifiOperatioGetState,
  WifiOperatioGetKey,
  WifiOperatioGetSN,
  WifiOperatioSetKey,
  WifiOperatioSetHost,
};

@interface EscWifiVC ()

@property (weak, nonatomic) IBOutlet UITextField *wifiNameTF;
@property (weak, nonatomic) IBOutlet UITextField *wifiPwdTF;
@property (weak, nonatomic) IBOutlet UITextField *keyTF;
@property (weak, nonatomic) IBOutlet UILabel *displayLabel;
@property (strong, nonatomic) AYEscCommand *esc;
@property (assign, nonatomic) WifiOperation operation;

@end

@implementation EscWifiVC

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
  __weak typeof(self) weakSelf = self;
  self.esc = [AYEscCommand new];
  // 所以打印机数据接收 xmiprt8888
  self.bleHelper.onDataReceived = ^(NSData *data) {
      NSLog(@"收到数据: %@", data);
    Byte *bytes = (Byte *)[data bytes];
    NSString *str = [data toRawString];
    switch (weakSelf.operation) {
      case WifiOperatioSet:
        NSLog(@"配网：%@", [[data toRawString] isEqualToString:@"OK"] ? @"成功" : @"失败");
        weakSelf.displayLabel.text = [NSString stringWithFormat:@"配网：%@", [[data toRawString] isEqualToString:@"OK"] ? @"成功" : @"失败"];
        break;
      case WifiOperatioGetState: {
          //成功返回 FC 00（0x00:未连接 0x01:热点连接成功 0x02:IOT连接成功(云联接)），失败无 返回
          if (bytes[0] != 0xFC) return;
          NSString *state;
          if (bytes[1] == 0x00) {
            state = @"未连接";
          } else if (bytes[1] == 0x01) {
            state = @"热点连接成功";
          } else if (bytes[1] == 0x02) {
            state = @"IOT连接成功(云联接)";
          }
          weakSelf.displayLabel.text = [NSString stringWithFormat:@"wifi连接状态：%@", state];
      }
        break;
      case WifiOperatioGetKey:
        NSLog(@"设备秘钥：%@", str);
        weakSelf.displayLabel.text = [NSString stringWithFormat:@"设备秘钥：%@", str];
        break;
      case WifiOperatioGetSN:
        NSLog(@"打印机sn：%@", str);
        weakSelf.displayLabel.text = [NSString stringWithFormat:@"打印机sn：%@", str];
        break;
      case WifiOperatioSetKey:
        NSLog(@"设置密钥：%@", [[data toRawString] isEqualToString:@"OK"] ? @"成功" : @"失败");
        break;
      case WifiOperatioSetHost:
        NSLog(@"设置域名：%@", [[data toRawString] isEqualToString:@"OK"] ? @"成功" : @"失败");
        break;
        
      default:
        break;
    }
  };
}


-(IBAction)setWifi {
  if (!self.wifiNameTF.text.length) {
    NSLog(@"请输入wifi名称");
    return;
  }
  if (!self.wifiPwdTF.text.length) {
    NSLog(@"请输入wifi密码");
    return;
  }
  self.operation = WifiOperatioSet;
  [self.esc clean];
  [self.esc setWifiName:self.wifiNameTF.text pwd:self.wifiPwdTF.text mode:0];
  [self.bleHelper writeCommands:self.esc.commands];
}

/**
 * 查询配网是否成功
 * 成功返回 FC 00（0x00:未连接 0x01:热点连接成功 0x02:IOT连接成功(云联接)），失败无 返回
 */
- (IBAction)getWifiState {
  self.operation = WifiOperatioGetState;
  [self.esc clean];
  [self.esc getWifiState];
  [self.bleHelper writeCommands:self.esc.commands];
}


/**
 * 获取设备sn
 */
- (IBAction)getSN {
  self.operation = WifiOperatioGetSN;
  [self.esc clean];
  [self.esc sn];
  [self.bleHelper writeCommands:self.esc.commands];
}

/**
 * 获取设备秘钥
 */
- (IBAction)getKey {
  self.operation = WifiOperatioGetKey;
  [self.esc clean];
  [self.esc getKey];
  [self.bleHelper writeCommands:self.esc.commands];
}

/**
 * 设置设备秘钥
 */
- (IBAction)setKey {
  if (!self.keyTF.text.length) {
    NSLog(@"请输入密钥");
    return;
  }
  self.operation = WifiOperatioSetKey;
  [self.esc clean];
  [self.esc setKey:self.keyTF.text];
  [self.bleHelper writeCommands:self.esc.commands];
}

/**
 * 设置域名
 */
- (IBAction)setHost {
  self.operation = WifiOperatioSetHost;
  [self.esc clean];
  // 自定义域名，可多个
  NSArray *hostArray = @[
      @"https://aliyuncs.com",
      @"https://iprtapp.com",
//      @"https://aynapp.aiyinprinter.com.cn",
//      @"https://aynapp.aiyinprinter.com",
//      @"https://aynapp.aiyin.com",
//      @"https://aynapp.ai-yin.cn",
//      @"https://aynapp.ai-yin.com",
//      @"https://aynapp.ai-yin.com.cn"
  ];
  [self.esc setHosts:hostArray];
  [self.bleHelper writeCommands:self.esc.commands];
}

@end
