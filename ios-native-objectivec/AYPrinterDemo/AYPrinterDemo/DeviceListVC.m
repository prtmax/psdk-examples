//
//  ViewController.m
//  AYPrinterDemo
//
//  Created by aiyin on 2023/9/12.
//

#import "DeviceListVC.h"
#import "TsplFunctionVC.h"
#import "EscFunctionVC.h"
#import "CpclFunctionVC.h"

#define CellIdentifier @"cellId"

@interface DeviceListVC ()<BleHelperDelegate, UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate>

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UISearchBar *searchBar;
@property (strong, nonatomic) NSMutableArray<AYPrinter *> *printers;

@end

@implementation DeviceListVC

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.bleHelper.delegate = self;
    self.searchBar.delegate = self;
    self.tableView.tableFooterView = [UIView new];
    NSLog(@"SDK INFO: %@", [SdkInfo info]);
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.bleHelper disconnect];
    [self scan];
}

- (IBAction)scan {
    [self.printers removeAllObjects];
    [self.tableView reloadData];
    [self.bleHelper startScan];
}

#pragma mark - BleHelperDelegate
- (void)bleHelperDidUpdateState:(CBManagerState)state {
    if(state == CBManagerStatePoweredOn) {
        [self scan];
        return;
    }
    NSLog(@"蓝牙异常");
}

- (void)bleHelperDiscoverPeripheral:(AYPrinter *)printer {
    //    float dist = [self calcDistByRSSI:RSSI.intValue];
    //    NSLog(@"%@ 的距离是： %f", peripheral.name, dist);
    // NSLog(@"self.searchBar.text： %@", self.searchBar.text);
    if (![printer.name containsString:self.searchBar.text] && self.searchBar.text.length != 0) {
        return;
    }
    BOOL isExist = NO;
    for (AYPrinter *p in self.printers) {
        if ([p.uuid isEqualToString:printer.uuid]) {
            isExist = YES;
            if (!p.mac.length) {
                [self.printers replaceObjectAtIndex:[self.printers indexOfObject:p] withObject:printer];
                [self.tableView reloadData];
            }
            break;
        }
    }
    if (!isExist) {
        NSLog(@"发现设备 name：%@, uuid: %@, mac: %@", printer.name, printer.uuid, printer.mac);
        [self.printers addObject:printer];
        [self.tableView reloadData];
    }
}

////传入RSSI值，返回距离（单位：米）。其中，A参数赋了59，n
//- (float)calcDistByRSSI:(int)rssi {
//    int iRssi = abs(rssi);
//    float power = (iRssi - 59) / (10 * 1.2);
//    return pow(10, power);
//}

- (void)bleHelperDidChangeConnectState:(BleState)state peripheral:(CBPeripheral *)peripheral {
    NSLog(@"bleHelperDidChangeConnectState: %ld", state);
    if (state == BleStateConnected) {
        
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"指令类型" message:nil preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *tsplAction = [UIAlertAction actionWithTitle:@"TSPL" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            TsplFunctionVC *vc = [[TsplFunctionVC alloc] init];
            vc.navigationItem.title = peripheral.name;
            [self.navigationController pushViewController:vc animated:YES];
        }];
        UIAlertAction *escAction = [UIAlertAction actionWithTitle:@"ESC" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            EscFunctionVC *vc = [[EscFunctionVC alloc] init];
            vc.navigationItem.title = peripheral.name;
            [self.navigationController pushViewController:vc animated:YES];
        }];
        UIAlertAction *cpclAction = [UIAlertAction actionWithTitle:@"CPCL" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            CpclFunctionVC *vc = [[CpclFunctionVC alloc] init];
            vc.navigationItem.title = peripheral.name;
            [self.navigationController pushViewController:vc animated:YES];
        }];
        UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
            [self.bleHelper disconnect];
        }];
        
        [alertController addAction:tsplAction];
        [alertController addAction:escAction];
        [alertController addAction:cpclAction];
        [alertController addAction:cancelAction];
        [self presentViewController:alertController animated:YES completion:nil];
    }
}

#pragma mark - UISearchBarDelegate
- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
    [self.view endEditing:YES];
    [self scan];
}

#pragma mark - UITableViewDataSource
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.printers.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if(cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
    }
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    AYPrinter *printer = self.printers[indexPath.row];
    cell.textLabel.text = printer.name;
    cell.detailTextLabel.text = printer.uuid;
    
    return cell;
}

#pragma mark - UITableViewDelegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    AYPrinter *printer = self.printers[indexPath.row];
    [self.bleHelper stopScan];
    [self.bleHelper connect:printer];
}

#pragma mark - lazy
- (NSMutableArray<AYPrinter *> *)printers {
    if(!_printers) {
        _printers = [NSMutableArray array];
    }
    return _printers;
}

@end
