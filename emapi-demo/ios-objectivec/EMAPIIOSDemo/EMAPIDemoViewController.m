#import "EMAPIDemoViewController.h"
#import "EMAPIDemoController.h"

typedef NS_ENUM(NSInteger, EMAPIDemoPage) {
    EMAPIDemoPageScan = 0,
    EMAPIDemoPageFunction = 1,
};

@interface EMAPIDemoViewController () <UITableViewDataSource, UITableViewDelegate, UIDocumentPickerDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate>

@property(nonatomic, strong) EMAPIDemoController *controller;
@property(nonatomic, strong) UISegmentedControl *pageControl;
@property(nonatomic, strong) UISegmentedControl *logControl;
@property(nonatomic, strong) UITableView *tableView;
@property(nonatomic, strong) UIStackView *operationBar;
@property(nonatomic, assign) NSInteger selectedLogIndex;
@property(nonatomic, copy) NSURL *selectedWifiFileURL;
@property(nonatomic, copy) NSURL *selectedOtaURL;
@property(nonatomic, strong) UIImage *selectedEscImage;
@property(nonatomic, assign) NSInteger documentPickerPurpose;
@property(nonatomic, strong) UISwitch *simulationSwitch;
@property(nonatomic, strong) UISegmentedControl *escPaperControl;
@property(nonatomic, strong) UISegmentedControl *escModeControl;
@property(nonatomic, strong) UISlider *escThicknessSlider;
@property(nonatomic, strong) UISwitch *escCompressSwitch;
@property(nonatomic, strong) UILabel *escThicknessLabel;

@end

@implementation EMAPIDemoViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.title = @"EMAPI iOS Demo";
    self.view.backgroundColor = UIColor.systemGroupedBackgroundColor;
    self.controller = [[EMAPIDemoController alloc] init];
    self.selectedLogIndex = 0;
    [self buildView];
    [self configureNavigationItems];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(controllerDidChange:) name:EMAPIDemoControllerDidChangeNotification object:self.controller];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)buildView
{
    self.pageControl = [[UISegmentedControl alloc] initWithItems:@[@"扫描", @"功能"]];
    self.pageControl.selectedSegmentIndex = EMAPIDemoPageScan;
    [self.pageControl addTarget:self action:@selector(pageChanged:) forControlEvents:UIControlEventValueChanged];

    self.tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStyleInsetGrouped];
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    self.tableView.translatesAutoresizingMaskIntoConstraints = NO;

    self.operationBar = [[UIStackView alloc] init];
    self.operationBar.axis = UILayoutConstraintAxisVertical;
    self.operationBar.spacing = 8;
    self.operationBar.layoutMargins = UIEdgeInsetsMake(10, 12, 12, 12);
    self.operationBar.layoutMarginsRelativeArrangement = YES;
    self.operationBar.backgroundColor = UIColor.secondarySystemGroupedBackgroundColor;
    self.operationBar.translatesAutoresizingMaskIntoConstraints = NO;

    UIStackView *root = [[UIStackView alloc] initWithArrangedSubviews:@[self.pageControl, self.tableView, self.operationBar]];
    root.axis = UILayoutConstraintAxisVertical;
    root.spacing = 8;
    root.translatesAutoresizingMaskIntoConstraints = NO;
    root.layoutMargins = UIEdgeInsetsMake(12, 12, 0, 12);
    root.layoutMarginsRelativeArrangement = YES;
    [self.view addSubview:root];

    [NSLayoutConstraint activateConstraints:@[
        [root.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor],
        [root.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [root.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [root.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],
        [self.operationBar.heightAnchor constraintGreaterThanOrEqualToConstant:112],
    ]];

    [self rebuildOperationBar];
}

- (void)configureNavigationItems
{
    UIBarButtonItem *settings = [[UIBarButtonItem alloc] initWithTitle:@"设置" style:UIBarButtonItemStylePlain target:self action:@selector(showSettings)];
    UIBarButtonItem *disconnect = [[UIBarButtonItem alloc] initWithTitle:@"断开" style:UIBarButtonItemStylePlain target:self action:@selector(disconnect)];
    disconnect.enabled = self.controller.connected && !self.controller.isBusy;
    self.navigationItem.rightBarButtonItems = self.controller.connected ? @[disconnect, settings] : @[settings];
}

- (void)controllerDidChange:(NSNotification *)notification
{
    [self configureNavigationItems];
    [self rebuildOperationBar];
    [self.tableView reloadData];
}

- (void)pageChanged:(UISegmentedControl *)sender
{
    [self rebuildOperationBar];
    [self.tableView reloadData];
}

- (void)disconnect
{
    [self.controller disconnect];
    self.pageControl.selectedSegmentIndex = EMAPIDemoPageScan;
}

- (void)showSettings
{
    UIViewController *settings = [[UIViewController alloc] init];
    settings.title = @"设置";
    settings.view.backgroundColor = UIColor.systemGroupedBackgroundColor;

    UILabel *section = [self labelWithText:@"测试模式"];
    UILabel *description = [self bodyLabelWithText:@"没有真实蓝牙和打印机时，开启模拟模式进行完整流程验证。"];
    UILabel *title = [self labelWithText:@"模拟模式"];
    UILabel *subtitle = [self bodyLabelWithText:@"生成模拟蓝牙设备，所有 EMAPI 操作返回模拟结果"];
    self.simulationSwitch = [[UISwitch alloc] init];
    self.simulationSwitch.on = self.controller.simulationMode;
    self.simulationSwitch.enabled = !self.controller.isBusy;
    [self.simulationSwitch addTarget:self action:@selector(simulationSwitchChanged:) forControlEvents:UIControlEventValueChanged];

    UIStackView *textColumn = [[UIStackView alloc] initWithArrangedSubviews:@[title, subtitle]];
    textColumn.axis = UILayoutConstraintAxisVertical;
    textColumn.spacing = 4;
    UIStackView *switchRow = [[UIStackView alloc] initWithArrangedSubviews:@[textColumn, self.simulationSwitch]];
    switchRow.axis = UILayoutConstraintAxisHorizontal;
    switchRow.spacing = 12;
    switchRow.alignment = UIStackViewAlignmentCenter;

    UIStackView *stack = [[UIStackView alloc] initWithArrangedSubviews:@[section, description, switchRow]];
    stack.axis = UILayoutConstraintAxisVertical;
    stack.spacing = 12;
    stack.layoutMargins = UIEdgeInsetsMake(20, 20, 20, 20);
    stack.layoutMarginsRelativeArrangement = YES;
    stack.backgroundColor = UIColor.secondarySystemGroupedBackgroundColor;
    stack.layer.cornerRadius = 8;
    stack.translatesAutoresizingMaskIntoConstraints = NO;
    [settings.view addSubview:stack];
    [NSLayoutConstraint activateConstraints:@[
        [stack.topAnchor constraintEqualToAnchor:settings.view.safeAreaLayoutGuide.topAnchor constant:16],
        [stack.leadingAnchor constraintEqualToAnchor:settings.view.leadingAnchor constant:16],
        [stack.trailingAnchor constraintEqualToAnchor:settings.view.trailingAnchor constant:-16],
    ]];
    [self.navigationController pushViewController:settings animated:YES];
}

- (void)rebuildOperationBar
{
    for (UIView *view in self.operationBar.arrangedSubviews) {
        [self.operationBar removeArrangedSubview:view];
        [view removeFromSuperview];
    }

    if (self.pageControl.selectedSegmentIndex == EMAPIDemoPageScan || !self.controller.connected) {
        UIStackView *row = [self horizontalRow];
        [row addArrangedSubview:[self buttonWithTitle:self.controller.scanning ? @"扫描中" : @"开始扫描" action:@selector(startScan)]];
        UIButton *stop = [self buttonWithTitle:@"停止" action:@selector(stopScan)];
        stop.enabled = self.controller.scanning && !self.controller.isBusy;
        [row addArrangedSubview:stop];
        [self.operationBar addArrangedSubview:row];
        return;
    }

    UILabel *title = [self labelWithText:self.controller.pendingActionLabel ? [NSString stringWithFormat:@"正在执行：%@", self.controller.pendingActionLabel] : @"功能区"];
    [self.operationBar addArrangedSubview:title];

    NSArray<NSArray<NSString *> *> *rows = @[
        @[@"休眠关机", @"打印自检页", @"设置关机时间"],
        @[@"RFID UID", @"RFID 信息", @"纸张长度"],
        @[@"RFID 失败处理", @"配网信息", @"WIFI 状态"],
        @[@"热点信息", @"WiFi 文件传输", @"基本参数"],
        @[@"打印状态", @"ESC 打印", @"OTA 升级"],
    ];
    for (NSArray<NSString *> *titles in rows) {
        UIStackView *row = [self horizontalRow];
        for (NSString *buttonTitle in titles) {
            [row addArrangedSubview:[self buttonWithTitle:buttonTitle action:[self selectorForActionTitle:buttonTitle]]];
        }
        [self.operationBar addArrangedSubview:row];
    }
}

- (SEL)selectorForActionTitle:(NSString *)title
{
    NSDictionary<NSString *, NSString *> *selectors = @{
        @"休眠关机": NSStringFromSelector(@selector(sleepShutdown)),
        @"打印自检页": NSStringFromSelector(@selector(printSelfTestPage)),
        @"设置关机时间": NSStringFromSelector(@selector(showShutdownTimeForm)),
        @"RFID UID": NSStringFromSelector(@selector(queryRfidUid)),
        @"RFID 信息": NSStringFromSelector(@selector(queryRfidCardInfo)),
        @"纸张长度": NSStringFromSelector(@selector(queryRfidPaperLength)),
        @"RFID 失败处理": NSStringFromSelector(@selector(setRfidAuthFailureHandling)),
        @"配网信息": NSStringFromSelector(@selector(showWifiForm)),
        @"WIFI 状态": NSStringFromSelector(@selector(queryWifiConnectionState)),
        @"热点信息": NSStringFromSelector(@selector(queryWifiHotspotInfo)),
        @"WiFi 文件传输": NSStringFromSelector(@selector(showWifiFileForm)),
        @"基本参数": NSStringFromSelector(@selector(queryDeviceInfo)),
        @"打印状态": NSStringFromSelector(@selector(queryPrintStatus)),
        @"ESC 打印": NSStringFromSelector(@selector(showEscPrintForm)),
        @"OTA 升级": NSStringFromSelector(@selector(showOtaForm)),
    };
    return NSSelectorFromString(selectors[title]);
}

- (UIStackView *)horizontalRow
{
    UIStackView *row = [[UIStackView alloc] init];
    row.axis = UILayoutConstraintAxisHorizontal;
    row.spacing = 8;
    row.distribution = UIStackViewDistributionFillEqually;
    return row;
}

- (UIButton *)buttonWithTitle:(NSString *)title action:(SEL)action
{
    UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
    [button setTitle:title forState:UIControlStateNormal];
    button.titleLabel.numberOfLines = 2;
    button.titleLabel.textAlignment = NSTextAlignmentCenter;
    button.backgroundColor = UIColor.tertiarySystemGroupedBackgroundColor;
    button.layer.cornerRadius = 8;
    button.enabled = !self.controller.isBusy && action != NULL;
    [button addTarget:self action:action forControlEvents:UIControlEventTouchUpInside];
    return button;
}

- (UILabel *)labelWithText:(NSString *)text
{
    UILabel *label = [[UILabel alloc] init];
    label.text = text;
    label.font = [UIFont preferredFontForTextStyle:UIFontTextStyleHeadline];
    label.numberOfLines = 0;
    return label;
}

- (UILabel *)bodyLabelWithText:(NSString *)text
{
    UILabel *label = [[UILabel alloc] init];
    label.text = text;
    label.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
    label.textColor = UIColor.secondaryLabelColor;
    label.numberOfLines = 0;
    return label;
}

- (void)simulationSwitchChanged:(UISwitch *)sender
{
    [self.controller setSimulationModeEnabled:sender.isOn];
}

#pragma mark - Scan actions

- (void)startScan
{
    [self.controller startScan];
}

- (void)stopScan
{
    [self.controller stopScan];
}

#pragma mark - EMAPI actions

- (void)sleepShutdown { [self.controller sleepShutdown]; }
- (void)printSelfTestPage { [self.controller printSelfTestPage]; }
- (void)queryRfidUid { [self.controller queryRfidUid]; }
- (void)queryRfidCardInfo { [self.controller queryRfidCardInfo]; }
- (void)queryRfidPaperLength { [self.controller queryRfidPaperLength]; }
- (void)setRfidAuthFailureHandling { [self.controller setRfidAuthFailureHandling]; }
- (void)queryWifiConnectionState { [self.controller queryWifiConnectionState]; }
- (void)queryWifiHotspotInfo { [self.controller queryWifiHotspotInfo]; }
- (void)queryDeviceInfo { [self.controller queryDeviceInfo]; }
- (void)queryPrintStatus { [self.controller queryPrintStatus]; }

- (void)showShutdownTimeForm
{
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"设置关机时间" message:@"设置自动关机等待分钟数" preferredStyle:UIAlertControllerStyleAlert];
    [alert addTextFieldWithConfigurationHandler:^(UITextField *textField) {
        textField.text = @"30";
        textField.placeholder = @"分钟";
        textField.keyboardType = UIKeyboardTypeNumberPad;
    }];
    for (NSNumber *minutes in @[@15, @30, @60]) {
        [alert addAction:[UIAlertAction actionWithTitle:[NSString stringWithFormat:@"%@ 分钟", minutes] style:UIAlertActionStyleDefault handler:^(__unused UIAlertAction *action) {
            [self.controller setShutdownTimeMinutes:minutes.integerValue];
        }]];
    }
    [alert addAction:[UIAlertAction actionWithTitle:@"提交" style:UIAlertActionStyleDefault handler:^(__unused UIAlertAction *action) {
        [self.controller setShutdownTimeMinutes:alert.textFields.firstObject.text.integerValue];
    }]];
    [alert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)showWifiForm
{
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"配网信息" message:@"输入 WiFi 后提交到打印机" preferredStyle:UIAlertControllerStyleAlert];
    [alert addTextFieldWithConfigurationHandler:^(UITextField *textField) {
        textField.placeholder = @"WiFi SSID";
    }];
    [alert addTextFieldWithConfigurationHandler:^(UITextField *textField) {
        textField.placeholder = @"WiFi 密码";
        textField.secureTextEntry = YES;
    }];
    [alert addAction:[UIAlertAction actionWithTitle:@"提交配网信息" style:UIAlertActionStyleDefault handler:^(__unused UIAlertAction *action) {
        [self.controller setWifiConfigWithSsid:alert.textFields.firstObject.text ?: @"" password:alert.textFields.lastObject.text ?: @""];
    }]];
    [alert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)showWifiFileForm
{
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"WiFi 文件传输" message:@"文件类型\n0x0001 WiFi主控升级文件(.bin)\n0x0002 日历图像文件\n0x0003 待机图像文件" preferredStyle:UIAlertControllerStyleActionSheet];
    [alert addAction:[UIAlertAction actionWithTitle:@"选择文件" style:UIAlertActionStyleDefault handler:^(__unused UIAlertAction *action) {
        [self pickDocumentForPurpose:1];
    }]];
    [alert addAction:[UIAlertAction actionWithTitle:@"开始传输 0x0001" style:UIAlertActionStyleDefault handler:^(__unused UIAlertAction *action) {
        [self.controller performWifiFileTransferAtURL:self.selectedWifiFileURL fileType:0x0001];
    }]];
    [alert addAction:[UIAlertAction actionWithTitle:@"开始传输 0x0002" style:UIAlertActionStyleDefault handler:^(__unused UIAlertAction *action) {
        [self.controller performWifiFileTransferAtURL:self.selectedWifiFileURL fileType:0x0002];
    }]];
    [alert addAction:[UIAlertAction actionWithTitle:@"开始传输 0x0003" style:UIAlertActionStyleDefault handler:^(__unused UIAlertAction *action) {
        [self.controller performWifiFileTransferAtURL:self.selectedWifiFileURL fileType:0x0003];
    }]];
    [alert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)showOtaForm
{
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"OTA 升级" message:self.controller.simulationMode ? @"模拟模式可不选文件，直接使用内置模拟包" : @"选择 OTA 文件后再开始" preferredStyle:UIAlertControllerStyleActionSheet];
    [alert addAction:[UIAlertAction actionWithTitle:@"选择 OTA 文件" style:UIAlertActionStyleDefault handler:^(__unused UIAlertAction *action) {
        [self pickDocumentForPurpose:2];
    }]];
    [alert addAction:[UIAlertAction actionWithTitle:@"开始 OTA 升级" style:UIAlertActionStyleDefault handler:^(__unused UIAlertAction *action) {
        [self.controller performOtaAtURL:self.selectedOtaURL];
    }]];
    [alert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)showEscPrintForm
{
    UIViewController *form = [[UIViewController alloc] init];
    form.title = @"ESC 打印";
    form.view.backgroundColor = UIColor.systemGroupedBackgroundColor;

    UIButton *pick = [self buttonWithTitle:@"选择图片" action:@selector(pickEscImage)];
    self.escPaperControl = [[UISegmentedControl alloc] initWithItems:@[@"连续", @"间隙", @"黑标"]];
    self.escPaperControl.selectedSegmentIndex = 0;
    self.escModeControl = [[UISegmentedControl alloc] initWithItems:@[@"普通", @"双重", @"灰阶"]];
    self.escModeControl.selectedSegmentIndex = 0;
    self.escThicknessSlider = [[UISlider alloc] init];
    self.escThicknessSlider.minimumValue = 0;
    self.escThicknessSlider.maximumValue = 15;
    self.escThicknessSlider.value = 8;
    [self.escThicknessSlider addTarget:self action:@selector(escThicknessChanged:) forControlEvents:UIControlEventValueChanged];
    self.escThicknessLabel = [self bodyLabelWithText:@"浓度 8"];
    self.escCompressSwitch = [[UISwitch alloc] init];

    UIStackView *compressRow = [[UIStackView alloc] initWithArrangedSubviews:@[[self labelWithText:@"图像压缩"], self.escCompressSwitch]];
    compressRow.axis = UILayoutConstraintAxisHorizontal;
    compressRow.alignment = UIStackViewAlignmentCenter;
    compressRow.distribution = UIStackViewDistributionEqualSpacing;

    UIButton *print = [self buttonWithTitle:@"开始打印" action:@selector(startEscPrintFromForm)];
    UIStackView *stack = [[UIStackView alloc] initWithArrangedSubviews:@[
        [self bodyLabelWithText:@"纸张类型"], self.escPaperControl,
        [self bodyLabelWithText:@"打印模式"], self.escModeControl,
        self.escThicknessLabel, self.escThicknessSlider,
        compressRow, pick, print
    ]];
    stack.axis = UILayoutConstraintAxisVertical;
    stack.spacing = 12;
    stack.layoutMargins = UIEdgeInsetsMake(20, 20, 20, 20);
    stack.layoutMarginsRelativeArrangement = YES;
    stack.translatesAutoresizingMaskIntoConstraints = NO;
    [form.view addSubview:stack];
    [NSLayoutConstraint activateConstraints:@[
        [stack.topAnchor constraintEqualToAnchor:form.view.safeAreaLayoutGuide.topAnchor constant:16],
        [stack.leadingAnchor constraintEqualToAnchor:form.view.leadingAnchor constant:16],
        [stack.trailingAnchor constraintEqualToAnchor:form.view.trailingAnchor constant:-16],
    ]];
    [self.navigationController pushViewController:form animated:YES];
}

- (void)pickEscImage
{
    UIImagePickerController *picker = [[UIImagePickerController alloc] init];
    picker.delegate = self;
    picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    [self presentViewController:picker animated:YES completion:nil];
}

- (void)escThicknessChanged:(UISlider *)slider
{
    self.escThicknessLabel.text = [NSString stringWithFormat:@"浓度 %.0f", slider.value];
}

- (void)startEscPrintFromForm
{
    EMAPIDemoEscPaperType paperType = (EMAPIDemoEscPaperType)self.escPaperControl.selectedSegmentIndex;
    [self.controller performEscPrintWithImage:self.selectedEscImage
                                    paperType:paperType
                                    printMode:self.escModeControl.selectedSegmentIndex
                                    thickness:(NSInteger)round(self.escThicknessSlider.value)
                                     compress:self.escCompressSwitch.isOn];
}

- (void)pickDocumentForPurpose:(NSInteger)purpose
{
    self.documentPickerPurpose = purpose;
    UIDocumentPickerViewController *picker = [[UIDocumentPickerViewController alloc] initWithDocumentTypes:@[@"public.data"] inMode:UIDocumentPickerModeImport];
    picker.delegate = self;
    [self presentViewController:picker animated:YES completion:nil];
}

#pragma mark - Pickers

- (void)documentPicker:(UIDocumentPickerViewController *)controller didPickDocumentsAtURLs:(NSArray<NSURL *> *)urls
{
    if (self.documentPickerPurpose == 1) {
        self.selectedWifiFileURL = urls.firstObject;
    } else if (self.documentPickerPurpose == 2) {
        self.selectedOtaURL = urls.firstObject;
    }
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<UIImagePickerControllerInfoKey,id> *)info
{
    self.selectedEscImage = info[UIImagePickerControllerOriginalImage];
    [picker dismissViewControllerAnimated:YES completion:nil];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    [picker dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Table

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    if (self.pageControl.selectedSegmentIndex == EMAPIDemoPageScan || !self.controller.connected) {
        return 2;
    }
    return 3;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (self.pageControl.selectedSegmentIndex == EMAPIDemoPageScan || !self.controller.connected) {
        return section == 0 ? 1 : MAX(self.controller.devices.count, 1);
    }
    if (section == 0) {
        return 1;
    }
    if (section == 1) {
        return 1;
    }
    return MAX([self selectedLogs].count, 1);
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if (self.pageControl.selectedSegmentIndex == EMAPIDemoPageScan || !self.controller.connected) {
        return section == 0 ? nil : @"设备列表";
    }
    return section == 0 ? nil : (section == 1 ? nil : [self selectedLogTitle]);
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"cell"];
        cell.textLabel.numberOfLines = 0;
        cell.detailTextLabel.numberOfLines = 0;
    }
    cell.accessoryView = nil;
    cell.selectionStyle = UITableViewCellSelectionStyleNone;

    if (self.pageControl.selectedSegmentIndex == EMAPIDemoPageScan || !self.controller.connected) {
        if (indexPath.section == 0) {
            cell.textLabel.text = self.controller.simulationMode ? @"模拟测试台" : @"蓝牙设备";
            cell.detailTextLabel.text = self.controller.simulationMode ? @"无需真实硬件，使用模拟设备验证 EMAPI 流程" : (self.controller.scanning ? @"正在扫描附近打印机" : @"扫描并连接支持 EMAPI 的打印机");
            return cell;
        }
        if (self.controller.devices.count == 0) {
            cell.textLabel.text = @"暂无设备";
            cell.detailTextLabel.text = self.controller.simulationMode ? @"点击开始扫描生成模拟打印机" : @"点击开始扫描查找蓝牙打印机";
            return cell;
        }
        EMAPIDemoDevice *device = self.controller.devices[indexPath.row];
        cell.textLabel.text = device.name;
        cell.detailTextLabel.text = [NSString stringWithFormat:@"%@  %@", device.protocolLabel ?: @"Bluetooth", device.mac.length ? device.mac : @"无 MAC"];
        UIButton *button = [self buttonWithTitle:@"连接" action:@selector(connectFromButton:)];
        button.tag = indexPath.row;
        cell.accessoryView = button;
        cell.selectionStyle = UITableViewCellSelectionStyleDefault;
        return cell;
    }

    if (indexPath.section == 0) {
        cell.textLabel.text = self.controller.connectedDeviceName ?: @"EMAPI 打印机";
        cell.detailTextLabel.text = self.controller.pendingActionLabel ? [NSString stringWithFormat:@"正在执行：%@\n%@", self.controller.pendingActionLabel, self.controller.simulationMode ? @"模拟模式" : @"真实设备"] : [NSString stringWithFormat:@"记录实时显示，操作从底部面板执行\n%@", self.controller.simulationMode ? @"模拟模式" : @"真实设备"];
        return cell;
    }
    if (indexPath.section == 1) {
        self.logControl = [[UISegmentedControl alloc] initWithItems:@[
            [NSString stringWithFormat:@"发送指令 %lu", (unsigned long)self.controller.requestLogs.count],
            [NSString stringWithFormat:@"命令结果 %lu", (unsigned long)self.controller.commandLogs.count],
            [NSString stringWithFormat:@"上报解析 %lu", (unsigned long)self.controller.reportLogs.count],
        ]];
        self.logControl.selectedSegmentIndex = self.selectedLogIndex;
        [self.logControl addTarget:self action:@selector(logChanged:) forControlEvents:UIControlEventValueChanged];
        cell.accessoryView = self.logControl;
        cell.textLabel.text = @"日志";
        cell.detailTextLabel.text = nil;
        return cell;
    }

    NSArray<EMAPIDemoLogEntry *> *logs = [self selectedLogs];
    if (logs.count == 0) {
        cell.textLabel.text = [NSString stringWithFormat:@"暂无%@", [self selectedLogTitle]];
        cell.detailTextLabel.text = nil;
        return cell;
    }
    EMAPIDemoLogEntry *entry = logs[indexPath.row];
    cell.textLabel.text = entry.title;
    cell.detailTextLabel.text = entry.bytes.length > 0 ? [NSString stringWithFormat:@"%@\nbytes: %@", entry.message, [self hexStringForData:entry.bytes]] : entry.message;
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if ((self.pageControl.selectedSegmentIndex == EMAPIDemoPageScan || !self.controller.connected) && indexPath.section == 1 && indexPath.row < self.controller.devices.count) {
        [self.controller connectDevice:self.controller.devices[indexPath.row]];
        self.pageControl.selectedSegmentIndex = EMAPIDemoPageFunction;
    }
}

- (void)connectFromButton:(UIButton *)button
{
    if (button.tag < self.controller.devices.count) {
        [self.controller connectDevice:self.controller.devices[button.tag]];
        self.pageControl.selectedSegmentIndex = EMAPIDemoPageFunction;
    }
}

- (void)logChanged:(UISegmentedControl *)sender
{
    self.selectedLogIndex = sender.selectedSegmentIndex;
    [self.tableView reloadData];
}

- (NSArray<EMAPIDemoLogEntry *> *)selectedLogs
{
    if (self.selectedLogIndex == 0) {
        return self.controller.requestLogs;
    }
    if (self.selectedLogIndex == 1) {
        return self.controller.commandLogs;
    }
    return self.controller.reportLogs;
}

- (NSString *)selectedLogTitle
{
    if (self.selectedLogIndex == 0) {
        return @"发送指令";
    }
    if (self.selectedLogIndex == 1) {
        return @"命令结果";
    }
    return @"上报解析";
}

- (NSString *)hexStringForData:(NSData *)data
{
    const unsigned char *bytes = data.bytes;
    NSMutableArray<NSString *> *parts = [NSMutableArray arrayWithCapacity:data.length];
    for (NSUInteger index = 0; index < data.length; index++) {
        [parts addObject:[NSString stringWithFormat:@"%02X", bytes[index]]];
    }
    return [parts componentsJoinedByString:@" "];
}

@end
