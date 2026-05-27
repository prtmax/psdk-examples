#import "EMAPIDemoController.h"

#if __has_include(<emapi/emapi.h>)
#import <emapi/emapi.h>
#endif

NSString * const EMAPIDemoControllerDidChangeNotification = @"EMAPIDemoControllerDidChangeNotification";

@interface EMAPIDemoController ()

@property(nonatomic, strong) NSMutableArray<EMAPIDemoDevice *> *devices;
@property(nonatomic, strong) NSMutableArray<EMAPIDemoLogEntry *> *requestLogs;
@property(nonatomic, strong) NSMutableArray<EMAPIDemoLogEntry *> *commandLogs;
@property(nonatomic, strong) NSMutableArray<EMAPIDemoLogEntry *> *reportLogs;
@property(nonatomic, strong, nullable) EMAPIDemoDevice *activeDevice;
@property(nonatomic, strong, nullable) id printer;

@end

@implementation EMAPIDemoController

- (instancetype)init
{
    self = [super init];
    if (self) {
        _devices = [NSMutableArray array];
        _requestLogs = [NSMutableArray array];
        _commandLogs = [NSMutableArray array];
        _reportLogs = [NSMutableArray array];
        _bluetoothEnabled = YES;
    }
    return self;
}

- (BOOL)isBusy
{
    return self.connecting || self.pendingActionLabel.length > 0;
}

- (NSString *)transferProgressText
{
    double percent = self.transferTotalBytes == 0 ? 0 : (double)self.transferSentBytes / (double)self.transferTotalBytes * 100.0;
    return [NSString stringWithFormat:@"OTA 进度：%lu / %lu bytes (%.1f%%)\n最新升级状态：%@",
            (unsigned long)self.transferSentBytes,
            (unsigned long)self.transferTotalBytes,
            percent,
            self.latestUpgradeStatus ?: @"暂无"];
}

- (void)startScan
{
    if ([self isBusy]) {
        return;
    }
    [self.devices removeAllObjects];
    if (self.simulationMode) {
        [self.devices addObject:[EMAPIDemoDevice simulatedPrinter]];
        self.bluetoothEnabled = YES;
        self.scanning = NO;
        [self addCommandLog:@"模拟模式：已生成 1 台模拟蓝牙设备"];
        [self notifyChanged];
        return;
    }
    self.scanning = YES;
    [self addCommandLog:@"开始扫描蓝牙设备；请在此处接入项目最终的 iOS 蓝牙扫描适配器"];
    [self notifyChanged];
}

- (void)stopScan
{
    self.scanning = NO;
    [self addCommandLog:self.simulationMode ? @"模拟模式：扫描已停止" : @"已停止扫描"];
    [self notifyChanged];
}

- (void)connectDevice:(EMAPIDemoDevice *)device
{
    if ([self isBusy]) {
        return;
    }
    self.connecting = YES;
    [self notifyChanged];
    self.activeDevice = device;
    self.connectedDeviceName = device.name;

    if (self.simulationMode || device.isSimulated) {
        self.printer = nil;
        [self emitSimulatedBluetoothReport];
    } else {
#if __has_include(<emapi/emapi.h>)
        if (device.connectedDevice) {
            EMAPIPrinter *printer = [EMAPIPrinter printerWithConnectedDevice:device.connectedDevice timeout:3 maxRetries:1 mtu:self.knownMtu fallbackMtu:512];
            __weak typeof(self) weakSelf = self;
            printer.reportHandler = ^(EMAPIReport *report) {
                [weakSelf handleReport:report];
            };
            self.printer = printer;
        } else {
            [self addCommandLog:@"真实设备连接需要注入 PSDK ConnectedDevice；当前仅保留 EMAPI 调用边界"];
        }
#else
        [self addCommandLog:@"未找到 Objective-C EMAPI SDK 头文件，真实设备连接暂不可用"];
#endif
    }

    self.connected = YES;
    self.connecting = NO;
    self.scanning = NO;
    [self addCommandLog:[NSString stringWithFormat:@"已连接：%@", device.name]];
    [self notifyChanged];
}

- (void)disconnect
{
    self.activeDevice = nil;
    self.printer = nil;
    self.connected = NO;
    self.connectedDeviceName = nil;
    self.latestUpgradeStatus = nil;
    self.transferSentBytes = 0;
    self.transferTotalBytes = 0;
    [self addCommandLog:@"已断开连接"];
    [self notifyChanged];
}

- (void)setSimulationModeEnabled:(BOOL)enabled
{
    if (self.simulationMode == enabled || [self isBusy]) {
        return;
    }
    if (self.connected) {
        [self disconnect];
    }
    self.simulationMode = enabled;
    self.scanning = NO;
    [self.devices removeAllObjects];
    self.bluetoothEnabled = enabled ? YES : self.bluetoothEnabled;
    [self addCommandLog:enabled ? @"已开启模拟模式" : @"已关闭模拟模式"];
    [self notifyChanged];
}

- (void)sleepShutdown
{
    [self runPrinterAction:@"打印机休眠关机" requestBytes:[self requestBytesWithType:0x01 parent:0x01 child:0x02 payload:nil] block:^NSString *(NSError **error) {
        if (self.simulationMode) {
            [self emitSimulatedFlowControlBusy:NO];
            return @"模拟模式：休眠关机指令已接收";
        }
#if __has_include(<emapi/emapi.h>)
        [(EMAPIPrinter *)[self requirePrinter] sleepShutdownWithError:error];
        return @"打印机休眠关机：已发送";
#else
        return [self missingSDKMessage];
#endif
    }];
}

- (void)printSelfTestPage
{
    [self runPrinterAction:@"打印自检页" requestBytes:[self requestBytesWithType:0x01 parent:0x02 child:0x07 payload:nil] block:^NSString *(NSError **error) {
        if (self.simulationMode) {
            return @"模拟模式：自检页打印指令已接收";
        }
#if __has_include(<emapi/emapi.h>)
        [(EMAPIPrinter *)[self requirePrinter] printSelfTestPageWithError:error];
        return @"打印自检页：已发送";
#else
        return [self missingSDKMessage];
#endif
    }];
}

- (void)setShutdownTimeMinutes:(NSInteger)minutes
{
    NSData *payload = [self uint16Payload:minutes];
    [self runPrinterAction:@"设置关机时间" requestBytes:[self requestBytesWithType:0x01 parent:0x01 child:0x03 payload:payload] block:^NSString *(NSError **error) {
        if (self.simulationMode) {
            return [NSString stringWithFormat:@"模拟模式：关机时间已设置为 %ld 分钟", (long)minutes];
        }
#if __has_include(<emapi/emapi.h>)
        [(EMAPIPrinter *)[self requirePrinter] setShutdownTimeMinutes:minutes error:error];
        return [NSString stringWithFormat:@"关机时间已设置为 %ld 分钟", (long)minutes];
#else
        return [self missingSDKMessage];
#endif
    }];
}

- (void)queryRfidUid
{
    [self runPrinterAction:@"查询 RFID 卡 UID" requestBytes:[self requestBytesWithType:0x01 parent:0x05 child:0x01 payload:nil] block:^NSString *(NSError **error) {
        if (self.simulationMode) {
            return @"RFID 卡 UID：04AABBCCDDEE";
        }
#if __has_include(<emapi/emapi.h>)
        NSString *uid = [(EMAPIPrinter *)[self requirePrinter] queryRfidUidWithError:error];
        return [NSString stringWithFormat:@"RFID 卡 UID：%@", uid ?: @"未知"];
#else
        return [self missingSDKMessage];
#endif
    }];
}

- (void)queryRfidCardInfo
{
    [self runPrinterAction:@"查询 RFID 卡信息" requestBytes:[self requestBytesWithType:0x01 parent:0x05 child:0x02 payload:nil] block:^NSString *(NSError **error) {
        if (self.simulationMode) {
            return @"RFID 卡信息\n纸张型号：SIM-L801\n纸张长度：40m\n纸张宽度：80mm\n纸张颜色：white\n纸张物料号：SIM-PAPER-01";
        }
#if __has_include(<emapi/emapi.h>)
        EMAPIRfidCardInfo *info = [(EMAPIPrinter *)[self requirePrinter] queryRfidCardInfoWithError:error];
        return [NSString stringWithFormat:@"RFID 卡信息\n纸张型号：%@\n纸张长度：%@\n纸张宽度：%@\n纸张颜色：%@\n纸张物料号：%@",
                info.paperModel ?: @"未知", info.paperLength ?: @"未知", info.paperWidth ?: @"未知", info.paperColor ?: @"未知", info.paperMaterialNumber ?: @"未知"];
#else
        return [self missingSDKMessage];
#endif
    }];
}

- (void)queryRfidPaperLength
{
    [self runPrinterAction:@"查询卡内纸张长度" requestBytes:[self requestBytesWithType:0x01 parent:0x05 child:0x03 payload:nil] block:^NSString *(NSError **error) {
        if (self.simulationMode) {
            return @"卡内纸张长度：123456";
        }
#if __has_include(<emapi/emapi.h>)
        NSNumber *length = [(EMAPIPrinter *)[self requirePrinter] queryRfidPaperLengthWithError:error];
        return [NSString stringWithFormat:@"卡内纸张长度：%@", length ?: @"未知"];
#else
        return [self missingSDKMessage];
#endif
    }];
}

- (void)setRfidAuthFailureHandling
{
    NSData *payload = [NSData dataWithBytes:(uint8_t[]){0x01} length:1];
    [self runPrinterAction:@"设置 RFID 认证失败处理" requestBytes:[self requestBytesWithType:0x01 parent:0x05 child:0x04 payload:payload] block:^NSString *(NSError **error) {
        if (self.simulationMode) {
            return @"模拟模式：RFID 认证失败处理已设置为 禁止打印";
        }
#if __has_include(<emapi/emapi.h>)
        [(EMAPIPrinter *)[self requirePrinter] setRfidAuthFailureHandling:EMAPIRfidAuthFailurePolicyForbidPrint error:error];
        return @"RFID 认证失败处理：禁止打印";
#else
        return [self missingSDKMessage];
#endif
    }];
}

- (void)setWifiConfigWithSsid:(NSString *)ssid password:(NSString *)password
{
    [self runPrinterAction:@"设置配网信息" requestBytes:nil block:^NSString *(NSError **error) {
        NSString *displaySsid = ssid.length > 0 ? ssid : @"SIM_WIFI";
        if (self.simulationMode) {
            [self emitSimulatedWifiReportWithSsid:displaySsid];
            return [NSString stringWithFormat:@"模拟模式：配网信息已发送：SSID=%@", displaySsid];
        }
#if __has_include(<emapi/emapi.h>)
        [(EMAPIPrinter *)[self requirePrinter] setWifiConfigWithSsid:ssid password:password encryptionMethod:nil error:error];
        return [NSString stringWithFormat:@"配网信息已发送：SSID=%@", ssid];
#else
        return [self missingSDKMessage];
#endif
    }];
}

- (void)queryWifiConnectionState
{
    [self runPrinterAction:@"查询 WIFI 模块连接状态" requestBytes:[self requestBytesWithType:0x41 parent:0x06 child:0x02 payload:nil] block:^NSString *(NSError **error) {
        if (self.simulationMode) {
            return @"WIFI 连接状态：已连接 IoT";
        }
#if __has_include(<emapi/emapi.h>)
        EMAPIWifiConnectionState state = [(EMAPIPrinter *)[self requirePrinter] queryWifiConnectionStateWithError:error];
        return [NSString stringWithFormat:@"WIFI 连接状态：%ld", (long)state];
#else
        return [self missingSDKMessage];
#endif
    }];
}

- (void)queryWifiHotspotInfo
{
    [self runPrinterAction:@"查询 WIFI 模块热点相关信息" requestBytes:[self requestBytesWithType:0x41 parent:0x06 child:0x03 payload:nil] block:^NSString *(NSError **error) {
        if (self.simulationMode) {
            return @"WIFI 模块热点相关信息\nSSID：SIM_AP\nRSSI：-42\nIP：192.168.4.1\n端口：9100";
        }
#if __has_include(<emapi/emapi.h>)
        EMAPIWifiHotspotInfo *info = [(EMAPIPrinter *)[self requirePrinter] queryWifiHotspotInfoWithError:error];
        return [NSString stringWithFormat:@"WIFI 模块热点相关信息\nSSID：%@\nRSSI：%@\nIP：%@\n端口：%@",
                info.ssid ?: @"未知", info.rssi ?: @"未知", info.ip ?: @"未知", info.port ?: @"未知"];
#else
        return [self missingSDKMessage];
#endif
    }];
}

- (void)performWifiFileTransferAtURL:(NSURL *)url fileType:(NSInteger)fileType
{
    [self runPrinterAction:@"WIFI 文件传输" requestBytes:nil block:^NSString *(NSError **error) {
        NSData *data = [self transferDataFromURL:url simulatedLength:(fileType == 0x0002 ? 1024 : (fileType == 0x0003 ? 1536 : 2048)) error:error];
        if (data.length == 0) {
            return nil;
        }
        NSUInteger chunkSize = [self chunkSize];
        self.transferSentBytes = 0;
        self.transferTotalBytes = data.length;
        self.latestUpgradeStatus = @"WIFI 文件传输准备中";
        [self addRequestLogWithTitle:@"WIFI 文件传输文件" message:[NSString stringWithFormat:@"fileType=0x%04lx，准备发送 %lu bytes，chunkSize=%lu", (long)fileType, (unsigned long)data.length, (unsigned long)chunkSize] bytes:data];
#if __has_include(<emapi/emapi.h>)
        if (!self.simulationMode) {
            EMAPIPrinter *printer = (EMAPIPrinter *)[self requirePrinter];
            [printer startWifiFileDownloadWithFileType:fileType totalSize:(uint32_t)data.length error:error];
            [self transferData:data chunkSize:chunkSize handler:^BOOL(NSInteger index, NSData *chunk, NSError **innerError) {
                return [printer transferWifiFileDownloadChunkWithIndex:index data:chunk error:innerError];
            }];
            [printer finishWifiFileDownloadWithError:error];
        } else {
            [self simulateTransferData:data chunkSize:chunkSize status:@"WIFI 文件传输中"];
        }
#else
        if (self.simulationMode) {
            [self simulateTransferData:data chunkSize:chunkSize status:@"WIFI 文件传输中"];
        } else {
            return [self missingSDKMessage];
        }
#endif
        self.latestUpgradeStatus = @"WIFI 文件传输完成";
        return [NSString stringWithFormat:@"%@WIFI 文件传输已完成\n%@", self.simulationMode ? @"模拟模式：" : @"", [self transferProgressText]];
    }];
}

- (void)queryDeviceInfo
{
    [self runPrinterAction:@"查询打印机基本参数" requestBytes:[self requestBytesWithType:0x01 parent:0x01 child:0x01 payload:nil] block:^NSString *(NSError **error) {
        if (self.simulationMode) {
            self.knownMtu = @512;
            return @"打印机基本参数\n设备类型：simulator\n设备型号：EMAPI-SIM-01\n品牌：PSDK\n序列号：SIM0000001\n硬件版本：HW-SIM\n软件版本：SW-SIM\nBoot 版本：BOOT-SIM\nEMAPI MTU：512";
        }
#if __has_include(<emapi/emapi.h>)
        EMAPIPrinterInfo *info = [(EMAPIPrinter *)[self requirePrinter] queryDeviceInfoWithError:error];
        self.knownMtu = info.mtu;
        return [NSString stringWithFormat:@"打印机基本参数\n设备类型：%@\n设备型号：%@\n品牌：%@\n序列号：%@\n硬件版本：%@\n软件版本：%@\nBoot 版本：%@\nEMAPI MTU：%@",
                info.deviceType ?: @"未知", info.deviceModel ?: @"未知", info.brand ?: @"未知", info.serialNumber ?: @"未知",
                info.hardwareVersion ?: @"未知", info.softwareVersion ?: @"未知", info.bootVersion ?: @"未知", info.mtu ?: @"未知"];
#else
        return [self missingSDKMessage];
#endif
    }];
}

- (void)queryPrintStatus
{
    [self runPrinterAction:@"查询打印状态" requestBytes:[self requestBytesWithType:0x01 parent:0x02 child:0x03 payload:nil] block:^NSString *(NSError **error) {
        if (self.simulationMode) {
            return @"打印状态\n纸张状态：1\n开盖状态：0\n低电量：0\n过热：0\n电量百分比：86%\n电池电压：7400 mV\nTPH 温度：28";
        }
#if __has_include(<emapi/emapi.h>)
        EMAPIPrintStatus *status = [(EMAPIPrinter *)[self requirePrinter] queryPrintStatusWithError:error];
        return [NSString stringWithFormat:@"打印状态\n纸张状态：%@\n开盖状态：%@\n低电量：%@\n过热：%@\n电量百分比：%@%%\n电池电压：%@ mV\nTPH 温度：%@",
                status.paperStatus ?: @"未知", status.coverStatus ?: @"未知", status.lowBattery ?: @"未知", status.overheat ?: @"未知",
                status.batteryPercent ?: @"未知", status.batteryVoltage ?: @"未知", status.tphTemperature ?: @"未知"];
#else
        return [self missingSDKMessage];
#endif
    }];
}

- (void)performEscPrintWithImage:(UIImage *)image paperType:(EMAPIDemoEscPaperType)paperType printMode:(NSInteger)printMode thickness:(NSInteger)thickness compress:(BOOL)compress
{
    [self runPrinterAction:@"ESC 图片打印" requestBytes:nil block:^NSString *(NSError **error) {
        UIImage *source = image ?: [self simulatedImage];
        NSData *escData = [EMAPIDemoESCBuilder escDataForImage:source paperType:paperType printMode:printMode thickness:thickness compress:compress error:error];
        if (escData.length == 0) {
            return nil;
        }
        [self addRequestLogWithTitle:@"ESC 指令数据" message:[NSString stringWithFormat:@"生成 %lu bytes ESC 指令", (unsigned long)escData.length] bytes:escData];
        if (!self.simulationMode) {
#if __has_include(<emapi/emapi.h>)
            [(EMAPIPrinter *)[self requirePrinter] printEscData:escData error:error];
#else
            return [self missingSDKMessage];
#endif
        }
        return [NSString stringWithFormat:@"%@ESC 图片打印指令已完成", self.simulationMode ? @"模拟模式：" : @""];
    }];
}

- (void)performOtaAtURL:(NSURL *)url
{
    [self runPrinterAction:@"OTA 升级" requestBytes:nil block:^NSString *(NSError **error) {
        NSData *data = [self transferDataFromURL:url simulatedLength:2048 error:error];
        if (data.length == 0) {
            return nil;
        }
        NSUInteger chunkSize = [self chunkSize];
        self.transferSentBytes = 0;
        self.transferTotalBytes = data.length;
        self.latestUpgradeStatus = @"OTA 准备中";
        [self addRequestLogWithTitle:@"OTA 升级文件" message:[NSString stringWithFormat:@"准备发送 %lu bytes，chunkSize=%lu", (unsigned long)data.length, (unsigned long)chunkSize] bytes:data];
#if __has_include(<emapi/emapi.h>)
        if (!self.simulationMode) {
            EMAPIPrinter *printer = (EMAPIPrinter *)[self requirePrinter];
            [printer startMainControllerOtaWithFileType:1 totalSize:(uint32_t)data.length error:error];
            [self transferData:data chunkSize:chunkSize handler:^BOOL(NSInteger index, NSData *chunk, NSError **innerError) {
                return [printer transferMainControllerOtaChunkWithIndex:index data:chunk error:innerError];
            }];
            [printer finishMainControllerOtaWithError:error];
            [printer upgradeMainControllerWithError:error];
        } else {
            [self emitSimulatedUpgradeStatus:1];
            [self simulateTransferData:data chunkSize:chunkSize status:@"OTA 传输中"];
            [self emitSimulatedUpgradeStatus:0];
        }
#else
        if (self.simulationMode) {
            [self emitSimulatedUpgradeStatus:1];
            [self simulateTransferData:data chunkSize:chunkSize status:@"OTA 传输中"];
            [self emitSimulatedUpgradeStatus:0];
        } else {
            return [self missingSDKMessage];
        }
#endif
        return [NSString stringWithFormat:@"%@OTA 升级命令已完成\n%@", self.simulationMode ? @"模拟模式：" : @"", [self transferProgressText]];
    }];
}

- (void)runPrinterAction:(NSString *)label requestBytes:(NSData *)requestBytes block:(NSString *(^)(NSError **error))block
{
    if ([self isBusy]) {
        return;
    }
    self.pendingActionLabel = label;
    if (requestBytes) {
        [self addRequestLogWithTitle:label message:@"EMAPI 请求帧" bytes:requestBytes];
    }
    [self notifyChanged];
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
        NSError *error = nil;
        NSString *message = nil;
        @try {
            message = block(&error);
        } @catch (NSException *exception) {
            error = [NSError errorWithDomain:@"EMAPIDemo" code:20 userInfo:@{NSLocalizedDescriptionKey: exception.reason ?: exception.name}];
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            if (error || message.length == 0) {
                [self addCommandLog:[self formatError:error]];
            } else {
                [self.commandLogs insertObject:[EMAPIDemoLogEntry entryWithTitle:label message:message bytes:nil] atIndex:0];
            }
            self.pendingActionLabel = nil;
            [self notifyChanged];
        });
    });
}

- (id)requirePrinter
{
    if (self.printer == nil) {
        [NSException raise:NSInternalInconsistencyException format:@"打印机未连接"];
    }
    return self.printer;
}

- (NSString *)missingSDKMessage
{
    return @"Objective-C EMAPI SDK 尚未加入当前 target；请添加本地 PSDK EMAPI framework/source 后重试";
}

- (NSData *)transferDataFromURL:(NSURL *)url simulatedLength:(NSUInteger)length error:(NSError **)error
{
    if (self.simulationMode) {
        NSMutableData *data = [NSMutableData dataWithCapacity:length];
        for (NSUInteger index = 0; index < length; index++) {
            uint8_t byte = (uint8_t)(index & 0xff);
            [data appendBytes:&byte length:1];
        }
        return data;
    }
    if (url == nil) {
        if (error) {
            *error = [NSError errorWithDomain:@"EMAPIDemo" code:10 userInfo:@{NSLocalizedDescriptionKey: @"请选择文件"}];
        }
        return nil;
    }
    return [NSData dataWithContentsOfURL:url options:0 error:error];
}

- (NSUInteger)chunkSize
{
    NSUInteger mtu = self.knownMtu.unsignedIntegerValue > 0 ? self.knownMtu.unsignedIntegerValue : 512;
    return mtu > 16 ? mtu - 16 : 128;
}

- (void)transferData:(NSData *)data chunkSize:(NSUInteger)chunkSize handler:(BOOL(^)(NSInteger index, NSData *chunk, NSError **error))handler
{
    NSInteger index = 1;
    for (NSUInteger offset = 0; offset < data.length; offset += chunkSize) {
        NSUInteger end = MIN(offset + chunkSize, data.length);
        NSData *chunk = [data subdataWithRange:NSMakeRange(offset, end - offset)];
        NSError *error = nil;
        handler(index, chunk, &error);
        self.transferSentBytes = end;
        index += 1;
        dispatch_async(dispatch_get_main_queue(), ^{
            [self notifyChanged];
        });
    }
}

- (void)simulateTransferData:(NSData *)data chunkSize:(NSUInteger)chunkSize status:(NSString *)status
{
    for (NSUInteger offset = 0; offset < data.length; offset += chunkSize) {
        NSUInteger end = MIN(offset + chunkSize, data.length);
        self.transferSentBytes = end;
        self.latestUpgradeStatus = status;
        dispatch_async(dispatch_get_main_queue(), ^{
            [self notifyChanged];
        });
        [NSThread sleepForTimeInterval:0.05];
    }
}

- (UIImage *)simulatedImage
{
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(16, 16), YES, 1);
    [[UIColor whiteColor] setFill];
    UIRectFill(CGRectMake(0, 0, 16, 16));
    [[UIColor blackColor] setFill];
    UIRectFill(CGRectMake(3, 3, 10, 10));
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

- (void)handleReport:(id)report
{
#if __has_include(<emapi/emapi.h>)
    NSString *message = @"未知上报";
    NSData *bytes = nil;
    if ([report isKindOfClass:[EMAPIPrintResultReport class]]) {
        message = [NSString stringWithFormat:@"打印结果上报：%u", ((EMAPIPrintResultReport *)report).result];
    } else if ([report isKindOfClass:[EMAPIPrinterStatusReport class]]) {
        EMAPIPrinterStatusReport *status = (EMAPIPrinterStatusReport *)report;
        message = [NSString stringWithFormat:@"打印机状态上报\n纸张状态：%@\n开盖状态：%@\n电池状态：%@\n过热：%@\nNFC 纸张识别：%@",
                   status.paperStatus ?: @"未知", status.coverStatus ?: @"未知", status.batteryState ?: @"未知", status.overheat ?: @"未知", status.nfcPaperRecognition ?: @"未知"];
    } else if ([report isKindOfClass:[EMAPIFlowControlReport class]]) {
        message = [NSString stringWithFormat:@"流控上报：%@", [(EMAPIFlowControlReport *)report isBusy] ? @"忙" : @"空闲"];
    } else if ([report isKindOfClass:[EMAPIUpgradeStatusReport class]]) {
        message = [NSString stringWithFormat:@"升级状态上报：%u", ((EMAPIUpgradeStatusReport *)report).status];
        self.latestUpgradeStatus = message;
    } else if ([report isKindOfClass:[EMAPIBluetoothConnectionReport class]]) {
        message = [NSString stringWithFormat:@"蓝牙连接上报：%u", ((EMAPIBluetoothConnectionReport *)report).state];
    } else if ([report isKindOfClass:[EMAPIWifiConfigStatusReport class]]) {
        EMAPIWifiConfigStatusReport *wifi = (EMAPIWifiConfigStatusReport *)report;
        message = [NSString stringWithFormat:@"WIFI 配网上报：SSID=%@，状态=%@", wifi.ssid ?: @"未知", wifi.state ?: @"未知"];
    } else if ([report isKindOfClass:[EMAPIUnknownReport class]]) {
        message = @"未知上报";
    }
    EMAPICommand *command = [report command];
    if (command) {
        bytes = [EMAPIFrameCodec encodeCommand:command error:nil];
    }
    [self.reportLogs insertObject:[EMAPIDemoLogEntry entryWithTitle:@"上报解析" message:message bytes:bytes] atIndex:0];
    [self notifyChanged];
#endif
}

- (void)emitSimulatedBluetoothReport
{
    [self addReportLog:@"蓝牙连接上报：1" bytes:[self requestBytesWithType:0x01 parent:0x09 child:0x05 payload:[NSData dataWithBytes:(uint8_t[]){0x01} length:1]]];
}

- (void)emitSimulatedFlowControlBusy:(BOOL)busy
{
    [self addReportLog:[NSString stringWithFormat:@"流控上报：%@", busy ? @"忙" : @"空闲"] bytes:[self requestBytesWithType:0x01 parent:0x09 child:0x03 payload:[NSData dataWithBytes:(uint8_t[]){busy ? 0x01 : 0x00} length:1]]];
}

- (void)emitSimulatedUpgradeStatus:(uint8_t)status
{
    NSString *message = [NSString stringWithFormat:@"升级状态上报：%u", status];
    self.latestUpgradeStatus = message;
    [self addReportLog:message bytes:[self requestBytesWithType:0x01 parent:0x09 child:0x04 payload:[NSData dataWithBytes:&status length:1]]];
}

- (void)emitSimulatedWifiReportWithSsid:(NSString *)ssid
{
    [self addReportLog:[NSString stringWithFormat:@"WIFI 配网上报：SSID=%@，状态=1", ssid] bytes:[self requestBytesWithType:0x41 parent:0x06 child:0x04 payload:[ssid dataUsingEncoding:NSUTF8StringEncoding]]];
}

- (NSData *)requestBytesWithType:(uint8_t)type parent:(uint8_t)parent child:(uint8_t)child payload:(NSData *)payload
{
#if __has_include(<emapi/emapi.h>)
    EMAPICommand *command = [[EMAPICommand alloc] initWithType:type parent:parent child:child payload:payload ?: [NSData data] error:nil];
    return [EMAPIFrameCodec encodeCommand:command error:nil];
#else
    NSMutableData *data = [NSMutableData dataWithBytes:(uint8_t[]){0x1f, type, parent, child} length:4];
    if (payload) {
        [data appendData:payload];
    }
    const uint8_t tail = 0xff;
    [data appendBytes:&tail length:1];
    return data;
#endif
}

- (NSData *)uint16Payload:(NSInteger)value
{
    uint8_t bytes[] = {(uint8_t)((value >> 8) & 0xff), (uint8_t)(value & 0xff)};
    return [NSData dataWithBytes:bytes length:sizeof(bytes)];
}

- (NSString *)formatError:(NSError *)error
{
    if (error == nil) {
        return @"连接或执行错误：未知错误";
    }
    return [NSString stringWithFormat:@"连接或执行错误：%@", error.localizedDescription];
}

- (void)addCommandLog:(NSString *)message
{
    [self.commandLogs insertObject:[EMAPIDemoLogEntry entryWithTitle:@"系统消息" message:message bytes:nil] atIndex:0];
}

- (void)addRequestLogWithTitle:(NSString *)title message:(NSString *)message bytes:(NSData *)bytes
{
    [self.requestLogs insertObject:[EMAPIDemoLogEntry entryWithTitle:title message:message bytes:bytes] atIndex:0];
}

- (void)addReportLog:(NSString *)message bytes:(NSData *)bytes
{
    [self.reportLogs insertObject:[EMAPIDemoLogEntry entryWithTitle:@"上报解析" message:message bytes:bytes] atIndex:0];
}

- (void)notifyChanged
{
    [[NSNotificationCenter defaultCenter] postNotificationName:EMAPIDemoControllerDidChangeNotification object:self];
}

@end
