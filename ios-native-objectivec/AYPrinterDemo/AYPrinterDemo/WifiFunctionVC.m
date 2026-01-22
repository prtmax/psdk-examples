//
//  WifiFunctionVC.m
//  AYPrinterDemo
//
//  Created by aiyin on 5/29/25.
//

#import "WifiFunctionVC.h"

typedef NS_ENUM(NSUInteger, ReadMark) {
  WifiSet,
  WifiName,
  WifiPassword,
  WifiState,
  WifiDHCP,
  IpGet,
};


@interface WifiFunctionVC ()<UITextFieldDelegate>

@property(assign, nonatomic) ReadMark mark;
@property(strong, nonatomic) NSMutableData *revData;
@property (weak, nonatomic) IBOutlet UILabel *displayLabel;
@property (weak, nonatomic) IBOutlet UITextField *nameTextF;
@property (weak, nonatomic) IBOutlet UITextField *pwdTextF;
@property (assign, nonatomic) NSInteger selectedSegmentIndex;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *setIpHeight;
@property (weak, nonatomic) IBOutlet UITextField *ipTextF;
@property (weak, nonatomic) IBOutlet UITextField *maskTextF;
@property (weak, nonatomic) IBOutlet UITextField *gatewayTextF;

@end

@implementation WifiFunctionVC

- (void)viewDidLoad {
  [super viewDidLoad];
  // Do any additional setup after loading the view from its nib.
  self.revData = [NSMutableData data];
  __weak typeof(self) weakSelf = self;
  self.bleHelper.onDataReceived = ^(NSData *data) {
    NSLog(@"onDataReceived : %@", data);
    [weakSelf.revData appendData:data];
  };
  self.nameTextF.delegate = self;
  self.pwdTextF.delegate = self;
  self.ipTextF.delegate = self;
  self.maskTextF.delegate = self;
  self.gatewayTextF.delegate = self;
  _setIpHeight.constant = 0;
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(bleStateDisconnected) name:@"BleStateDisconnected" object:nil];
}


- (void)viewDidDisappear:(BOOL)animated {
  [super viewDidAppear:animated];
  [self.bleHelper disconnect];
}

- (void)bleStateDisconnected {
  NSLog(@"设备已断开");
  [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - wifi
- (IBAction)setWifi:(id)sender {
  if (_nameTextF.text.length < 1) {
    NSLog(@"请输入wifi名称");
    return;
  }
  if (_pwdTextF.text.length < 1) {
    NSLog(@"请输入wifi密码");
    return;
  }
  
  WifiCommand *wifi = [WifiCommand new];
  [wifi setSSID:_nameTextF.text pwd: _pwdTextF.text];
  self.mark = WifiSet;
  
  [self.bleHelper writeCommands:wifi.commands];
  [self performSelector:@selector(readafterDelay) withObject:nil afterDelay:0.2];
}

- (IBAction)wifiName:(id)sender {
  WifiCommand *wifi = [WifiCommand new];
  [wifi getSSID];
  
  self.mark = WifiName;
  [self.bleHelper writeCommands:wifi.commands];
  [self performSelector:@selector(readafterDelay) withObject:nil afterDelay:0.2];
}


- (IBAction)wifiPasswd:(id)sender {
  WifiCommand *wifi = [WifiCommand new];
  [wifi getPassword];
  self.mark = WifiPassword;
  [self.bleHelper writeCommands:wifi.commands];
  [self performSelector:@selector(readafterDelay) withObject:nil afterDelay:0.2];
}

- (IBAction)wifiState:(id)sender {
  WifiCommand *wifi = [WifiCommand new];
  [wifi state];
  self.mark = WifiState;
  [self.bleHelper writeCommands:wifi.commands];
  [self performSelector:@selector(readafterDelay) withObject:nil afterDelay:0.2];
}

- (IBAction)wifiDHCP:(id)sender {
  WifiCommand *wifi = [WifiCommand new];
  [wifi getDHCP];
  self.mark = WifiDHCP;
  [self.bleHelper writeCommands:wifi.commands];
  [self performSelector:@selector(readafterDelay) withObject:nil afterDelay:0.5];
//  [self readTimeOut:1];
}

- (void)readafterDelay {
  NSString *string = [self.revData toRawString];
  NSLog(@"string: %@", string);
  self.revData = [NSMutableData data];
  switch (self.mark) {
    case WifiName:
      self.displayLabel.text = [NSString stringWithFormat:@"wifi 名称: %@", string];
      break;
    case WifiPassword:
      self.displayLabel.text = [NSString stringWithFormat:@"wifi 密码: %@", string];
      break;
    case WifiState: {
        BOOL isConnected = [string containsString:@"Connected"];
        self.displayLabel.text = [NSString stringWithFormat:@"wifi 连接状态: %@", isConnected ? @"已连接" : @"未连接"];
    }
      break;
    case WifiDHCP: {
        BOOL isDynamics = [string hasPrefix:@"1"];
        self.displayLabel.text = [NSString stringWithFormat:@"DHCP: %@", isDynamics ? @"动态" : @"静态"];
    }
      break;
    case IpGet: {
      NSLog(@"获取ip: %@", self.revData);
      NSArray *infos = [string componentsSeparatedByString:@"\r\n"];
      if (infos.count < 2) {
        return;
      }
      self.displayLabel.text = [NSString stringWithFormat:@"ip: %@\n子网掩码: %@\n网关: %@", infos[0], infos[1], infos[2]];
    }
      break;
    default:
      break;
  }
}

#pragma mark - ip
- (IBAction)ipModeChange:(UISegmentedControl *)sender {
  self.selectedSegmentIndex = sender.selectedSegmentIndex;
  _setIpHeight.constant = sender.selectedSegmentIndex == 0 ? 1 : 102;
}

- (IBAction)setIP:(id)sender {
  WifiCommand *wifi = [WifiCommand new];
  if (self.selectedSegmentIndex == 0) {
    [wifi setDHCP];
    [self.bleHelper writeCommands:wifi.commands];
    return;
  }
  
  if([self.ipTextF.text componentsSeparatedByString:@"."].count != 4) {
    NSLog(@"请输入正确的ip");
    return;
  }
  if([self.maskTextF.text componentsSeparatedByString:@"."].count != 4) {
    NSLog(@"请输入正确的子网掩码");
    return;
  }
  if([self.gatewayTextF.text componentsSeparatedByString:@"."].count != 4) {
    NSLog(@"请输入正确的网关");
    return;
  }
  
  [wifi setIP:self.ipTextF.text mask:self.maskTextF.text gateway:self.gatewayTextF.text];
  [self.bleHelper writeCommands:wifi.commands];
}

- (IBAction)getIP:(id)sender {
  WifiCommand *wifi = [WifiCommand new];
  [wifi getIP];
  [wifi getMask];
  [wifi getGateway];
  self.mark = IpGet;
  [self.bleHelper writeCommands:wifi.commands];
  [self performSelector:@selector(readafterDelay) withObject:nil afterDelay:0.6];
}

#pragma mark - UITextFieldDelegate
- (BOOL)textFieldShouldReturn:(UITextField *)textField {
  [textField resignFirstResponder];
  return YES;
}

@end
