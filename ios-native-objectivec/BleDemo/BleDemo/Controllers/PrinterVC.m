//
//  ViewController.m
//  BleDemo
//
//  Created by IPRT on 2022/11/21.
//

#import "PrinterVC.h"
#import <ibridge/IbridgeBleApi.h>
#import <ibridge/BLEAdvertisementData.h>
#import <esc/BasicESC.h>
#import <adapter/ConnectedDevice.h>
#import <fsc/FscBleApi.h>
#import <appleble/appleble.h>
#import "ESCVC.h"
#import "TSPLVC.h"
#import "CPCLVC.h"

typedef enum : NSUInteger {
    ESC,
    TSPL,
    CPCL,
} CommandType;

@interface PrinterVC ()<UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate, FscBleApiInterfaceDelegate, IbridgeBleApiInterfaceDelegate, AppleBleDelegate>

@property (weak, nonatomic) IBOutlet UITextField *searchTxf;
@property (weak, nonatomic) IBOutlet UITableView *tableview;
@property (weak, nonatomic) IBOutlet UIButton *searchBtn;

@property(nonatomic, strong) NSArray *dataSource;
@property(nonatomic, strong) NSMutableArray *allDataSource;
@property(nonatomic, strong) NSMutableArray *searchDataSource;
@property(nonatomic, strong) IbridgeBleApi *ibridgeBleDevice;
@property(nonatomic, strong) FscBleApi *fscBleDevice;
@property(nonatomic, strong) AppleBle *appleBleDevice;
@property(nonatomic, assign) BOOL isSearch;
@property(nonatomic, strong) BasicESC *basicESC;
@property(nonatomic, strong) Lifecycle *lifeCycle;
@property(nonatomic, assign) CommandType commandType;
@property(nonatomic, strong) CBPeripheral *currentPeripheral;

@end

@implementation PrinterVC

- (void)viewDidLoad {
    [super viewDidLoad];
//    self.device = [IbridgeBleApi sharedInstance]; // esc 指令
//    self.device = [FscBleApi sharedInstance]; // cpcl 指令
//    self.device = [AppleBle sharedInstance]; // tspl 指令
    [IbridgeBleApi sharedInstance].delegate = self;
    [AppleBle sharedInstance].delegate = self;
    NSLog(@"viewDidLoad appleBle: %@",  [AppleBle sharedInstance]);
    
    [self setUp];
}

- (void)setUp {
    self.title = @"打印机列表";
    self.searchTxf.placeholder = [NSString stringWithString:NSLocalizedString(@"name.bluetooth.enter", nil)];
    [_searchBtn setTitle:NSLocalizedString(@"scan.start", nil) forState:UIControlStateNormal];
}

#pragma mark - click
- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [self.view endEditing:YES];
}

-(IBAction)scanClick:(UIButton *)btn {
    NSString *btnTitle = [btn currentTitle];
    if([btnTitle isEqualToString:NSLocalizedString(@"scan.stop", nil)]) {
        [btn setTitle:NSLocalizedString(@"scan.start", nil) forState:UIControlStateNormal];
        [self.device stopScanPrinters];
    }else{
        [btn setTitle:NSLocalizedString(@"scan.stop", nil) forState:UIControlStateNormal];
        [[AppleBle sharedInstance] startScanPrinters];
        [[IbridgeBleApi sharedInstance] startScanPrinters];
    }
}

-(void)selectArgType:(void(^)(void))callBack {
    UIAlertController *alertController =  [UIAlertController alertControllerWithTitle:NSLocalizedString(@"select.instruction.type", nil) message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    
    UIAlertAction *CPCLAction = [UIAlertAction actionWithTitle:@"CPCL" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        self.commandType = CPCL;
        self.device = [AppleBle sharedInstance];
        if(callBack) callBack();
    }];
    UIAlertAction *TSPLAction = [UIAlertAction actionWithTitle:@"TSPL" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        self.commandType = TSPL;
        self.device = [AppleBle sharedInstance];
        if(callBack) callBack();
    }];
    UIAlertAction *ESCAction = [UIAlertAction actionWithTitle:@"ESC" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        self.commandType = ESC;
        self.device = [IbridgeBleApi sharedInstance];
        if(callBack) callBack();
    }];
    UIAlertAction *cancel = [UIAlertAction actionWithTitle:NSLocalizedString(@"cancle", nil) style:UIAlertActionStyleCancel handler:nil];
    
    [alertController addAction:CPCLAction];
    [alertController addAction:TSPLAction];
    [alertController addAction:ESCAction];
    [alertController addAction:cancel];
    [self presentViewController:alertController animated:YES completion:nil];
}

#pragma mark - ble
- (void)bleDidConnectPeripheral:(nonnull CBPeripheral *)peripheral {
    BaseVC *vc = nil;
    switch (self.commandType) {
        case ESC: {
            vc = [[ESCVC alloc] init];
            [self.device start:@"FF00" on:peripheral];
        }
            break;
        case CPCL: {
            vc = [[CPCLVC alloc] init];
        }
            break;
        case TSPL: {
            vc = [[TSPLVC alloc] init];
        }
            break;
    }
    vc.device = self.device;
    vc.peripheral = self.currentPeripheral;
    vc.navBackCallBack = ^{
        self.device.delegate = self;
    };
    [self.navigationController pushViewController:vc animated:YES];
}


-(void)bleDidFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error { }

-(void)bleDidDiscoverDevies:(CBPeripheral *)peripheral advertisementData:(BLEAdvertisementData *)advertisementData RSSI:(NSNumber *)RSSI{
    if(peripheral.name){
        
        NSLog(@"peripheral.name: %@  ---- advertisementData: %@", peripheral.name, advertisementData.manufacturerData);
        
        BOOL isContain = NO;
        for (CBPeripheral *currentPeripheral in self.allDataSource) {
            if([currentPeripheral.identifier isEqual:peripheral.identifier]){
                isContain = YES;
            }
        }
        if(!isContain){
            [self.allDataSource addObject:peripheral];
            if(!self.isSearch){
                self.dataSource = self.allDataSource;
                [self.tableview reloadData];
            }
        }
    }
}
- (void)bleDidDiscoverPrinters:(nonnull CBPeripheral *)peripheral RSSI:(nullable NSNumber *)RSSI {
    if(peripheral.name){
        BOOL isContain = NO;
        for (CBPeripheral *currentPeripheral in self.allDataSource) {
            if([currentPeripheral.identifier isEqual:peripheral.identifier]){
                isContain = YES;
            }
        }
        if(!isContain){
            [self.allDataSource addObject:peripheral];
            if(!self.isSearch){
                self.dataSource = self.allDataSource;
                [self.tableview reloadData];
            }
        }
    }
}
-(void)didServicesFound:(CBPeripheral *)peripheral services:(NSArray<CBService *> *)services{
    NSLog(@"serviceUUIDString-----:%@",services);
}

#pragma mark - UITextFieldDelegate
- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string{
    if(textField.text.length > 0){
        [self.searchDataSource removeAllObjects];
        _isSearch = YES;
        for (CBPeripheral *object in self.allDataSource) {
            if([object.name containsString:textField.text]){
                [self.searchDataSource addObject:object];
                self.dataSource = self.searchDataSource;
                [self.tableview reloadData];
            }
        }
    }else{
        _isSearch = NO;
        self.dataSource = self.allDataSource;
        [self.tableview reloadData];
    }
    
   return YES;
}

#pragma mark - tableView
-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return self.dataSource.count;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
    if(cell == nil){
        cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"cell"];
    }
    CBPeripheral *peripheral = self.dataSource[indexPath.row];
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    cell.textLabel.text = peripheral.name;
    cell.detailTextLabel.text = [NSString stringWithFormat:@"%@", peripheral.identifier];
    cell.detailTextLabel.textColor = UIColor.lightGrayColor;
    
    return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    [self.view endEditing:YES];
    self.currentPeripheral = self.dataSource[indexPath.row];
    
    [self selectArgType:^{
        NSLog(@"selectArgType: %@, %@", self.device, self.currentPeripheral);
        [self.device connect:self.currentPeripheral];
    }];
    
    [[AppleBle sharedInstance] stopScanPrinters];
    [[IbridgeBleApi sharedInstance] stopScanPrinters];
    [[AppleBle sharedInstance] disconnect];
    [[IbridgeBleApi sharedInstance] disconnect];
}

#pragma mark - lazy
-(NSMutableArray *)allDataSource{
    if(!_allDataSource){
        _allDataSource = [NSMutableArray new];
    }
    return _allDataSource;
}

-(NSMutableArray *)searchDataSource{
    if(!_searchDataSource){
        _searchDataSource = [NSMutableArray new];
    }
    return _searchDataSource;
}
@end
