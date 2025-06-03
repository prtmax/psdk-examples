//
//  NetPrintVC.m
//  AYPrinterDemo
//
//  Created by aiyin on 5/30/25.
//

#import "NetPrintVC.h"

@interface NetPrintVC ()<AYNetHelperDelegate>

@property (strong, nonatomic) AYNetHelper *netHelper;
@property (weak, nonatomic) IBOutlet UITextField *ipTextF;
@property (weak, nonatomic) IBOutlet UITextField *portTextF;
@property (weak, nonatomic) IBOutlet UIButton *connectBtn;
@property (weak, nonatomic) IBOutlet UIButton *disconnectBtn;
@property (weak, nonatomic) IBOutlet UILabel *stateLabel;
@property (assign, nonatomic) NSInteger selectedSegmentIndex;

@end

@implementation NetPrintVC

- (void)viewDidLoad {
  [super viewDidLoad];
  // Do any additional setup after loading the view from its nib.
  self.title = @"NET打印";
  
  self.netHelper.delegate = self;
  self.disconnectBtn.enabled = NO;
  self.stateLabel.text = @"未连接";
}

- (IBAction)connect:(id)sender {
  NSLog(@"ip: %@", _ipTextF.text);
  NSLog(@"port: %d", [_portTextF.text intValue]);
  
  [self.netHelper connectIP:_ipTextF.text port:[_portTextF.text intValue]];
}

- (IBAction)disconnect:(id)sender {
  [self.netHelper disconnect];
}

- (IBAction)test:(id)sender {
  
  switch (self.selectedSegmentIndex) {
    case 0: {
      // tspl
//      AYTsplCommand *tspl = [AYTsplCommand new];
//      [tspl selfTest];
      UIImage *image = [UIImage imageNamed:@"image.png"];
      AYTsplCommand *tspl = [AYTsplCommand new];
      [tspl pageWidth:76 height:130];
      [tspl direction:0 mirror:0];
      [tspl cls];
      [tspl image:image x:0 y:0 compress:YES];
      [tspl print:1];
      [self.netHelper write:tspl];
    }
      break;
    case 1: {
      // cpcl
      UIImage *image = [UIImage imageNamed:@"base64-to-image.png"];
      AYCpclCommand *cpcl = [AYCpclCommand new];
      [cpcl pageWidth:76 * 8 height:100 * 8 copies:1];
      [cpcl image:image x:0 y:0 compress:true];
      [cpcl print:NO];
      
      [self.netHelper write:cpcl];
    }
      break;
    case 2: {
      // esc
      UIImage *image = [UIImage imageNamed:@"dithered-image4.png"];
      AYEscCommand *esc = [AYEscCommand new];
      [esc clean];
      [esc wake];
      [esc enable];
      [esc linedots:80];
      [esc image:image compress:NO mode:Normal];
      [esc linedots:80];
      [esc stopPrintJob];
      [self.netHelper write:esc];
    }
      break;
      
    default:
      break;
  }
}
- (IBAction)switchCmd:(UISegmentedControl *)sender {
  self.selectedSegmentIndex = sender.selectedSegmentIndex;
}

#pragma mark - AYNetHelperDelegate
- (void)netConnectStateDidChange:(NetState)state {
  switch (state) {
    case NetStateFailToConnect:
      break;
    case NetStateDisconnected:
      self.connectBtn.enabled = YES;
      self.disconnectBtn.enabled = NO;
      self.stateLabel.text = @"未连接";
      break;
    case NetStateConnected:
      self.connectBtn.enabled = NO;
      self.disconnectBtn.enabled = YES;
      self.stateLabel.text = @"已连接";
      break;
    default:
      break;
  }
}

- (void)netOnReceive:(NSData *_Nullable)data {
  
}

- (AYNetHelper *)netHelper {
  if (!_netHelper) {
    _netHelper = [[AYNetHelper alloc] init];
  }
  return _netHelper;
}

@end
