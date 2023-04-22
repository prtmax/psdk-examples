//
//  ViewController.m
//  BleDemo
//
//  Created by IPRT on 2022/11/21.
//

#import "ViewController.h"
#import <ibridge/IbridgeBleApi.h>
#import <esc/BasicESC.h>
#import <adapter/ConnectedDevice.h>
#import <fsc/FscBleApi.h>
#import <appleble/appleble.h>
#import "UIDevice+PAddition.h"
#import "ESCVC.h"
#import "TSPLVC.h"
#import "CPCLVC.h"
#import "MBProgressHUD.h"

typedef enum : NSUInteger {
    ESC,
    TSPL,
    CPCL,
} CommandType;

@interface ViewController ()<ConnectedDeviceDelegate, IbridgeBleApiInterfaceDelegate,UITableViewDelegate,UITableViewDataSource,UITextFieldDelegate,FscBleApiInterfaceDelegate>

@property (nonatomic , strong) UITableView *tableview;
@property (nonatomic , strong) NSArray *dataSource;
@property (nonatomic , strong) NSMutableArray *allDataSource;
@property (nonatomic , strong) NSMutableArray *searchDataSource;
@property (nonatomic , strong) UITextField *searchTF;
@property (nonatomic , strong) UIView *line;
@property (nonatomic , strong) UIView *headerView;
@property (nonatomic , strong) IbridgeBleApi *ibridgeBleDevice;
@property (nonatomic , strong) FscBleApi *fscBleDevice;
@property (nonatomic , strong) AppleBle *appleBleDevice;
@property (nonatomic , strong) UIButton *footerView;
@property (nonatomic , assign) BOOL isSearch;
@property (nonatomic , strong) BasicESC *basicESC;
@property (nonatomic , strong) Lifecycle *lifeCycle;
@property (nonatomic , assign) CommandType commandType;// 1 ESC 2 CPCL 3 TSPL
@property (nonatomic , strong) CBPeripheral *currentPeripheral;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setUI];
    self.device = [IbridgeBleApi sharedInstance];
//    self.device = [AppleBle sharedInstance];
    self.device.delegate = self;
}

-(void)scanAction{
    if([_footerView.titleLabel.text isEqualToString:NSLocalizedString(@"scan.stop", nil)]){
        [_footerView setTitle:NSLocalizedString(@"scan.start", nil) forState:UIControlStateNormal];
        [self.device stopScanPrinters];
    }else{
        [_footerView setTitle:NSLocalizedString(@"scan.stop", nil) forState:UIControlStateNormal];
        [self.device startScanPrinters];
    }
    
}
-(void)setUI{
    self.title = @"打印机列表";
    self.tableview.tableFooterView = [UIView new];
    [self.view addSubview:self.headerView];
    [self.headerView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.left.right.mas_equalTo(self.view);
        make.height.mas_equalTo(44);
    }];
    [self.view addSubview:self.footerView];
    [self.footerView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.mas_equalTo(self.view);
        make.bottom.mas_equalTo(-[UIDevice p_safeDistanceBottom]);
        make.height.mas_equalTo(44);
    }];
    [self.view addSubview:self.tableview];
    [self.tableview mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.mas_equalTo(self.view);
        make.top.mas_equalTo(self.headerView.mas_bottom);
        make.bottom.mas_equalTo(self.footerView.mas_top);
    }];
   
}
-(void)initData{
    self.isSearch = NO;
}
-(UITableView *)tableview{
    if(!_tableview){
        _tableview = [[UITableView alloc]init];
        _tableview.backgroundColor = UIColor.whiteColor;
        _tableview.delegate = self;
        _tableview.dataSource = self;
    }
    return _tableview;
}
-(UIView *)headerView{
    if(!_headerView){
        _headerView = [[UIView alloc]init];
        _headerView.backgroundColor = UIColor.whiteColor;
        _line = [[UIView alloc]init];
        _line.backgroundColor = UIColor.grayColor;
        [_headerView addSubview:_line];
        [_line mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.mas_equalTo(self->_headerView).mas_offset(20);
            make.bottom.mas_equalTo(self->_headerView);
            make.right.mas_equalTo(self->_headerView).mas_offset(-20);
            make.height.mas_equalTo(1);
        }];
        _searchTF = [[UITextField alloc]init];
        if(@available(iOS 13.0, *)) {
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
                usleep(3000);
                dispatch_async(dispatch_get_main_queue(), ^{
                    self->_searchTF.attributedPlaceholder = [[NSAttributedString alloc]initWithString:NSLocalizedString(@"name.bluetooth.enter", nil) attributes:@{NSForegroundColorAttributeName:[UIColor lightGrayColor]}];
                });
            });
        }
        [_searchTF addTarget:self action:@selector(textFieldTextChange:) forControlEvents:UIControlEventEditingChanged];
        _searchTF.delegate = self;
        [_headerView addSubview:_searchTF];
        [_searchTF mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.mas_equalTo(self->_headerView);
            make.left.right.mas_equalTo(self->_line);
            make.bottom.mas_equalTo(self->_line.mas_top);
        }];
    }
    return _headerView;
}
-(UIButton *)footerView{
    if(!_footerView){
        _footerView = [[UIButton alloc]init];
        _footerView.backgroundColor = UIColor.lightGrayColor;
        [_footerView setTitle:NSLocalizedString(@"scan.start", nil) forState:UIControlStateNormal];
        [_footerView addTarget:self action:@selector(scanAction) forControlEvents:UIControlEventTouchUpInside];
    }
    return _footerView;
}
- (void)bleDataReceived: (NSData *)revData {
  
}

- (void)bleDidConnectPeripheral:(nonnull CBPeripheral *)peripheral {
    [MBProgressHUD hideHUDForView:self.view animated:YES];
    BaseVC *vc = nil;
    switch (self.commandType) {
        case ESC: {
            [self.device start:@"FF00" on:peripheral];
            vc = [[ESCVC alloc] init];
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
            
        default:
            break;
    }
    vc.device = self.device;
    vc.peripheral = self.currentPeripheral;
    vc.navBackCallBack = ^{
        self.device.delegate = self;
    };
    [self.navigationController pushViewController:vc animated:YES];
}

-(ConnectedDevice *)getNewDeviceWithType:(NSInteger)type{
    if(type == 1){
        return  [IbridgeBleApi sharedInstance];
    }
    if(type == 2){
        return [FscBleApi sharedInstance];
    }
    if(type == 3){
        return [AppleBle sharedInstance];
    }
    return [AppleBle sharedInstance];
}

-(NSString *)getServiceUUIDString:(CBPeripheral *)peripheral{
    NSString *serviceUUIDString = @"";
    for (CBService *service in peripheral.services) {
        for (CBCharacteristic *characteristic in service.characteristics) {
            if (characteristic.properties == CBCharacteristicPropertyWrite) {
                NSString *str = [[NSString alloc]initWithData:characteristic.value encoding:NSUTF8StringEncoding];
                serviceUUIDString = str;
            }else if(characteristic.properties == CBCharacteristicWriteWithResponse){
                NSString *str = [[NSString alloc]initWithData:characteristic.value encoding:NSUTF8StringEncoding];
                serviceUUIDString = str;
            }else if (characteristic.properties == CBCharacteristicPropertyRead){
                NSString *str = [[NSString alloc]initWithData:characteristic.value encoding:NSUTF8StringEncoding];
                serviceUUIDString = str;
            }else{
                NSLog(@"没有这属性");
            }
        }
    }
    return serviceUUIDString;
}
-(void)bleDidFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error{
    [MBProgressHUD hideHUDForView:self.view animated:YES];
}
-(void)bleDidDiscoverDevies:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI{
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
-(void)textFieldTextChange:(UITextField *)textField{
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
    
}
-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return 1;
}
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
    cell.textLabel.textColor = UIColor.redColor;
    cell.detailTextLabel.text = [NSString stringWithFormat:@"%@", peripheral.identifier];
    cell.detailTextLabel.textColor = UIColor.grayColor;
    cell.backgroundColor = UIColor.whiteColor;
    return cell;
}
-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    [self.view endEditing:YES];
    self.currentPeripheral = self.dataSource[indexPath.row];
    [self.device stopScanPrinters];
    [self.device disconnect];
    [self selectArgType:^{
        [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        [self.device connect:self.currentPeripheral];
    }];
}
-(void)selectArgType:(void(^)(void))callBack {
    UIAlertController *alertController =  [UIAlertController alertControllerWithTitle:NSLocalizedString(@"select.instruction.type", nil) message:@"alertVCMessage" preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction* actionDefault = [UIAlertAction actionWithTitle:@"CPCL" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        self.commandType = CPCL;
        if(callBack) callBack();
    }];
    UIAlertAction* actionDestructive = [UIAlertAction actionWithTitle:@"TSPL" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
        self.commandType = TSPL;
        if(callBack) callBack();
    }];
    UIAlertAction* actionCancel = [UIAlertAction actionWithTitle:@"ESC" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        self.commandType = ESC;
        if(callBack) callBack();
    }];
    [alertController addAction:actionDefault];
    [alertController addAction:actionDestructive];
    [alertController addAction:actionCancel];
    [self presentViewController:alertController animated:YES completion:nil];
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
