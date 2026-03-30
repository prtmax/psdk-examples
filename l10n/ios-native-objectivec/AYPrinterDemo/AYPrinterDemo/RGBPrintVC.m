//
//  RGBPrintVC.m
//  AYPrinterDemo
//
//  Created by aiyin on 1/31/26.
//

#import "RGBPrintVC.h"
#import "RGBConfig.h"

typedef NS_ENUM(NSInteger, ReadMark) {
    ReadMarkNone = 0,
    ReadMarkOperatePrint,          // 打印操作 / Print operation
    ReadMarkOperateStatus,         // 打印机状态查询 / Printer status query
    ReadMarkOperateBatVol,         // 电量查询 / Battery query
    ReadMarkOperateShutdownTime,   // 设置关机时间 / Set auto shutdown time
    ReadMarkOperateInfo,           // 设备所有信息 / Full device info
    ReadMarkOperateInkBoxInfo,     // 墨盒信息 / Ink cartridge info
    ReadMarkOperateOTA,            // OTA 升级 / OTA upgrade
    ReadMarkOperatePrinterClean,   // 清洁打印头 / Clean printhead
    ReadMarkOperateEjectPaper       // 退纸 / 回纸 / Eject or feed paper back
};


@interface RGBPrintVC ()

@property (strong, nonatomic) AYRGBCommand *rgbCommand;
@property (assign, nonatomic) ReadMark readMark;
@property (weak, nonatomic) IBOutlet UILabel *displayLabel;


@end

@implementation RGBPrintVC

- (void)viewDidLoad {
    [super viewDidLoad];
  self.rgbCommand = [AYRGBCommand new];
  
  __weak typeof(self) weakSelf = self;
  self.bleHelper.onDataReceived = ^(NSData *data) {
    NSLog(@"onDataReceived %@ - %@", data, data.toRawString);
    Byte *bytes = (Byte *)[data bytes];
    switch (weakSelf.readMark) {
      case ReadMarkOperateBatVol:
        [weakSelf parseBatteryStatus:data];
        weakSelf.readMark = ReadMarkNone;
        break;
      case ReadMarkOperateStatus: {
        NSArray<NSString *> *statuses = [weakSelf parsePrinterStatus:data];
        weakSelf.displayLabel.text = [statuses componentsJoinedByString:@"+"];
        weakSelf.readMark = ReadMarkNone;
      }
        break;
      case ReadMarkOperateInfo:
        [weakSelf parseConfigResponse:data];
        weakSelf.readMark = ReadMarkNone;
        break;
      case ReadMarkOperateInkBoxInfo:
        [weakSelf parseInkStatus:data];
        weakSelf.readMark = ReadMarkNone;
        break;
      case ReadMarkOperateEjectPaper:
        break;
      case ReadMarkOperatePrinterClean: {
        weakSelf.readMark = ReadMarkNone;
        if ([data.toRawString hasPrefix:@"PRINTERCLEAN FINISH"]) {
          NSLog(@"%@", AYLocalizedString(@"清洁完成"));
          weakSelf.displayLabel.text = AYLocalizedString(@"清洁完成");
        }
      }
        break;
      case ReadMarkOperatePrint: {
        if (bytes[0] == 0xaa) {
          weakSelf.readMark = ReadMarkNone;
          weakSelf.displayLabel.text = AYLocalizedString(@"打印进度: 100%\n打印完成");
          break;
        }
        int progress = [weakSelf onPrintProcess:data];
        weakSelf.displayLabel.text = [NSString stringWithFormat:AYLocalizedString(@"打印进度: %d"), progress];
      }
        break;
      case ReadMarkOperateOTA: {
          weakSelf.readMark = ReadMarkNone;
          NSString *str = data.toRawString;
          weakSelf.displayLabel.text = [str containsString:@"Error"] ? AYLocalizedString(@"升级失败") : AYLocalizedString(@"升级成功");
      }
        break;
      case ReadMarkNone:
      default:
        break;
    }
  
    if (bytes[0] == 0xff) {
      NSString *statuses = [weakSelf parseStatus:data];
      weakSelf.displayLabel.text = statuses;
    }
  };
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(bleStateDisconnected) name:@"BleStateDisconnected" object:nil];
}

- (void)bleStateDisconnected {
  NSLog(@"%@", AYLocalizedString(@"设备已断开"));
  [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - Click Event
/// 查询电池电量 / Query battery level
- (IBAction)batteryVolume:(UIButton *)sender {
  self.readMark = ReadMarkOperateBatVol;
  [self.rgbCommand clean];
  [self.rgbCommand batteryVolume];
  [self.bleHelper writeCommands:self.rgbCommand.commands];
}

/// 查询打印机当前状态 / Query current printer status
- (IBAction)state:(UIButton *)sender {
  self.readMark = ReadMarkOperateStatus;
  [self.rgbCommand clean];
  [self.rgbCommand state];
  [self.bleHelper writeCommands:self.rgbCommand.commands];
}

/// 设置自动关机时间 / Set auto shutdown time
- (IBAction)setShutdownTime:(UIButton *)sender {
  self.readMark = ReadMarkOperateShutdownTime;
  [self.rgbCommand clean];
  [self.rgbCommand setShutdownTime:1];
  [self.bleHelper writeCommands:self.rgbCommand.commands];
}

/// 查询打印机配置信息 / Query printer configuration
- (IBAction)info:(UIButton *)sender {
  self.readMark = ReadMarkOperateInfo;
  [self.rgbCommand clean];
  [self.rgbCommand info];
  [self.bleHelper writeCommands:self.rgbCommand.commands];
}

/// 查询墨盒 / 碳带信息 / Query ink cartridge or ribbon info
- (IBAction)inkBoxInfo:(UIButton *)sender {
  self.readMark = ReadMarkOperateInkBoxInfo;
  [self.rgbCommand clean];
  [self.rgbCommand inkBoxInfo];
  [self.bleHelper writeCommands:self.rgbCommand.commands];
}

/// 退纸 / Eject paper
- (IBAction)ejectPaper {
  self.readMark = ReadMarkOperateEjectPaper;
  [self.rgbCommand clean];
  [self.rgbCommand ejectPaper];
  [self.bleHelper writeCommands:self.rgbCommand.commands];
}

/// 清洁打印头 / Clean printhead
- (IBAction)printerClean {
  self.readMark = ReadMarkOperatePrinterClean;
  [self.rgbCommand clean];
  [self.rgbCommand printerClean];
  [self.bleHelper writeCommands:self.rgbCommand.commands];
}

/// 打印自测页 / Print self-test page
- (IBAction)selfTest {
  self.readMark = ReadMarkNone;
  [self.rgbCommand clean];
  [self.rgbCommand selfTest];
  [self.bleHelper writeCommands:self.rgbCommand.commands];
}

/// 打印图片 / Print image
- (IBAction)print:(id)sender {
  UIImage *image = [UIImage imageNamed:@"caomei.jpg"];
  self.readMark = ReadMarkOperatePrint;
  NSMutableData *data = [NSMutableData data];
  [self.rgbCommand clean];
  [self.rgbCommand pageWidth:44 height:60];
  [self.rgbCommand cls];
  for (NSData *da in self.rgbCommand.commands) {
    [data appendData:da];
  }
//  * @param quality  图片质量（0:快速 1:精细 2:照片）/ Image quality (0: fast, 1: fine, 2: photo)
//  * @param mode  0:覆盖 1:或 2:异或 3:自定义 4:JPG 5:PNG 6:BMP / Render mode
  [self.rgbCommand image:image x:0 y:0 quality:0 mode:4];
  [self.rgbCommand print:1];
  
  [self.bleHelper writeCommands:self.rgbCommand.commands];
}

/// OTA 升级 / Perform OTA upgrade
- (IBAction)ota:(id)sender{
  NSString *filepath = [[NSBundle mainBundle] pathForResource:@"v138868.RM" ofType:nil];
  NSData* filedata = [NSData dataWithContentsOfFile:filepath];
  NSLog(@"filepath: %@\nfiledata: %@", filepath, filedata);
  
  self.readMark = ReadMarkOperateOTA;
  [self.rgbCommand clean];
  [self.rgbCommand ota:filedata];
  [self.bleHelper writeCommands:self.rgbCommand.commands];
}

#pragma mark - Parsing
/**
 * 解析电池状态 / Parse battery status.
 * @param data 电池状态数据 / Battery status payload.
 * @return 电量，0 表示解析失败 / Battery level, or 0 if parsing fails.
 */
- (NSInteger)parseBatteryStatus:(NSData *)data {
    // 验证数据长度 / Validate payload length
    if (!data || data.length < 12) {
        return 0;
    }

    const unsigned char *bytes = data.bytes;

    // 验证数据头 "BATTERY "（8 字节）/ Validate the "BATTERY " header (8 bytes)
    const unsigned char header[8] = { 'B','A','T','T','E','R','Y',' ' };
    for (int i = 0; i < 8; i++) {
        if (bytes[i] != header[i]) {
            return 0;
        }
    }

    @try {
        // 解析电量百分比（第 9 个字节，下标 8）/ Decode battery percentage from byte 9 (index 8)
        uint8_t batteryByte = bytes[8];
        NSInteger high = (batteryByte >> 4) & 0x0F;
        NSInteger low  = batteryByte & 0x0F;
        NSInteger batteryLevel = high * 10 + low;

        NSLog(AYLocalizedString(@"电量: %ld"), (long)batteryLevel);

        // 解析充电状态（第 10 个字节，下标 9）/ Decode charging state from byte 10 (index 9)
        BOOL isCharging = bytes[9] == 0x01;

        NSLog(AYLocalizedString(@"充电状态: %@"), isCharging ? AYLocalizedString(@"充电中") : AYLocalizedString(@"未充电"));
        self.displayLabel.text = [NSString stringWithFormat:AYLocalizedString(@"电量: %ld\n充电状态: %@"), (long)batteryLevel, isCharging ? AYLocalizedString(@"充电中") : AYLocalizedString(@"未充电")];

        return batteryLevel;
    }
    @catch (NSException *exception) {
        return 0;
    }
}

/// 状态掩码项 / Printer status mask definitions
static NSArray<NSDictionary<NSString *, id> *> *PrinterStatusMasks(void) {
    static NSArray *masks;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        masks = @[
            @{ @"mask": @(0x00000001), @"desc": AYLocalizedString(@"开盖") },
            @{ @"mask": @(0x00000002), @"desc": AYLocalizedString(@"卡纸") },
            @{ @"mask": @(0x00000004), @"desc": AYLocalizedString(@"缺纸") },
            @{ @"mask": @(0x00000008), @"desc": AYLocalizedString(@"缺墨") },
            @{ @"mask": @(0x00000020), @"desc": AYLocalizedString(@"繁忙") },
            @{ @"mask": @(0x00000040), @"desc": AYLocalizedString(@"低压") },
            @{ @"mask": @(0x00000100), @"desc": AYLocalizedString(@"正在取消") },
            @{ @"mask": @(0x00000200), @"desc": AYLocalizedString(@"数据异常") },
            @{ @"mask": @(0x00000400), @"desc": AYLocalizedString(@"机电错误") },
            @{ @"mask": @(0x00000800), @"desc": AYLocalizedString(@"纸道有纸") },
            @{ @"mask": @(0x00001000), @"desc": AYLocalizedString(@"无墨盒") }
        ];
    });
    return masks;
}

/**
 * 解析打印机状态（直接接收 4 字节数据）/ Parse printer status from a raw 4-byte payload.
 * @param data 4 字节 NSData / Raw 4-byte NSData.
 * @return 状态字符串数组（正常时仅包含“正常”）/ Status string array. Returns only "正常" when idle.
 */
- (NSArray<NSString *> *)parsePrinterStatus:(NSData *)data {
    NSMutableArray<NSString *> *statuses = [NSMutableArray array];

    // 校验长度 / Validate payload length
    if (!data || data.length != 4) {
        [statuses addObject:AYLocalizedString(@"错误: 输入必须是四个字节")];
        return statuses;
    }

    const uint8_t *bytes = data.bytes;

    // 小端序 → 32 位整型 / Convert little-endian bytes to a 32-bit integer
    uint32_t value =
        (bytes[0] & 0xFF) |
        ((bytes[1] & 0xFF) << 8) |
        ((bytes[2] & 0xFF) << 16) |
        ((bytes[3] & 0xFF) << 24);

    // 正常状态 / Normal status
    if (value == 0) {
        [statuses addObject:AYLocalizedString(@"正常")];
        return statuses;
    }

    // 遍历状态掩码（保持顺序）/ Walk masks in a stable display order
    for (NSDictionary *item in PrinterStatusMasks()) {
        uint32_t mask = [item[@"mask"] unsignedIntValue];
        if ((value & mask) != 0) {
            [statuses addObject:item[@"desc"]];
        }
    }

    // 未匹配任何状态 / Fallback when no known state matches
    if (statuses.count == 0) {
        [statuses addObject:
            [NSString stringWithFormat:AYLocalizedString(@"未知状态 (0x%08X)"), value]];
    }

    return statuses;
}


#pragma mark - Parse Auto-Reported Status
- (NSString *)parseStatus:(NSData *)data {
    if (!data || data.length != 5) {
        return AYLocalizedString(@"无效数据: 数据长度错误");
    }

    const uint8_t *bytes = data.bytes;

    // 验证数据头 / Validate frame header
    if (bytes[0] != 0xFF) {
        return AYLocalizedString(@"无效数据: 数据头不匹配");
    }

    // 组合 4 字节状态码（大端）/ Rebuild 4-byte status code in big-endian order
    uint32_t statusType =
        ((uint32_t)bytes[1] << 24) |
        ((uint32_t)bytes[2] << 16) |
        ((uint32_t)bytes[3] << 8)  |
        (uint32_t)bytes[4];

    NSString *status = [self mapStatusToString:statusType];
    NSLog(AYLocalizedString(@"主动上报状态: %@"), status);
    return status;
}

#pragma mark - Status Mapping
- (NSString *)mapStatusToString:(uint32_t)statusType {
    if (statusType == 0x00000000) {
        return AYLocalizedString(@"正常");
    }

    NSMutableArray<NSString *> *statusList = [NSMutableArray array];

    if (statusType & 0x00000001) {
        [statusList addObject:AYLocalizedString(@"开盖")];
    }
    if (statusType & 0x00000002) {
        [statusList addObject:AYLocalizedString(@"卡纸")];
    }
    if (statusType & 0x00000004) {
        [statusList addObject:AYLocalizedString(@"缺纸")];
    }
    if (statusType & 0x00000008) {
        [statusList addObject:AYLocalizedString(@"缺墨")];
    }
    if (statusType & 0x00000040) {
        [statusList addObject:AYLocalizedString(@"低压")];
    }
    if (statusType & 0x00000100) {
        [statusList addObject:AYLocalizedString(@"正在取消")];
    }
    if (statusType & 0x00000200) {
        [statusList addObject:AYLocalizedString(@"数据异常")];
    }
    if (statusType & 0x00000400) {
        [statusList addObject:AYLocalizedString(@"机电错误")];
    }
    if (statusType & 0x00000800) {
        [statusList addObject:AYLocalizedString(@"纸道有纸")];
    }
    if (statusType & 0x00001000) {
        [statusList addObject:AYLocalizedString(@"无墨盒")];
    }

    if (statusType & 0x10000000) {
        [statusList addObject:AYLocalizedString(@"充电中")];
    }
    if (statusType & 0x20000000) {
        [statusList addObject:AYLocalizedString(@"充电完成")];
    }

    if (statusList.count > 0) {
        return [statusList componentsJoinedByString:@" + "];
    } else {
        return [NSString stringWithFormat:AYLocalizedString(@"未知状态: 0x%08X"), statusType];
    }
}



/**
 * 解析打印机配置响应 / Parse printer configuration response.
 * @param data 配置响应数据 / Configuration response payload.
 * @return Config 对象，解析失败返回 nil / Parsed config object, or nil on failure.
 */
- (RGBConfig *)parseConfigResponse:(NSData *)data {
    // 最小长度校验 / Validate minimum payload length
    if (!data || data.length < 18) {
        return nil;
    }

    const uint8_t *bytes = data.bytes;

    // 校验数据头 "CONFIG "（7 字节）/ Validate the "CONFIG " header (7 bytes)
    const uint8_t header[7] = { 'C','O','N','F','I','G',' ' };
    for (int i = 0; i < 7; i++) {
        if (bytes[i] != header[i]) {
            return nil;
        }
    }

  RGBConfig *config = [[RGBConfig alloc] init];

    @try {
        NSInteger offset = 7; // 跳过 "CONFIG " / Skip the "CONFIG " header

        // 1. 分辨率（2 字节，大端）/ Resolution, 2 bytes, big-endian
        config.resolution =
            ((bytes[offset] & 0xFF) << 8) |
             (bytes[offset + 1] & 0xFF);
        offset += 2;

        // 2. 硬件版本（3 字节）/ Hardware version, 3 bytes
        config.hardwareVersion =
            [NSString stringWithFormat:@"%d.%d.%d",
             bytes[offset] & 0xFF,
             bytes[offset + 1] & 0xFF,
             bytes[offset + 2] & 0xFF];
        offset += 3;

        // 3. 固件版本（3 字节）/ Firmware version, 3 bytes
        uint8_t fwByte1 = bytes[offset];
        NSInteger major = (fwByte1 >> 4) & 0x0F; // 高 4 位 / Upper 4 bits
        NSInteger minor = fwByte1 & 0x0F;        // 低 4 位 / Lower 4 bits
        NSInteger build =
            ((bytes[offset + 1] & 0xFF) << 8) |
             (bytes[offset + 2] & 0xFF);

        config.firmwareVersion =
            [NSString stringWithFormat:@"%ld.%ld.%ld",
             (long)major, (long)minor, (long)build];
        offset += 3;

        // 4. 自动关机（1 字节）/ Auto shutdown, 1 byte
        config.autoShutdown = bytes[offset] & 0xFF;
        offset++;

        // 5. 提示音（1 字节）/ Beep setting, 1 byte
        config.beepEnabled = bytes[offset] & 0xFF;
        offset++;

        NSLog(AYLocalizedString(@"打印机所有信息: %@"), config);
        self.displayLabel.text = [NSString stringWithFormat:AYLocalizedString(@"打印机所有信息: %@"), config.description];
      
        return config;

    }
    @catch (NSException *exception) {
        return nil;
    }
}


/**
 * 解析墨盒状态 / Parse ink cartridge status.
 * @param data 墨盒状态数据 / Ink status payload.
 * @return 墨水量（0 表示解析失败）/ Ink level, or 0 if parsing fails.
 */
- (NSInteger)parseInkStatus:(NSData *)data {
    // 校验数据长度 / Validate payload length
    if (!data || data.length < 11) {
        return 0;
    }

    const uint8_t *bytes = data.bytes;

    // 校验数据头 "INK "（4 字节）/ Validate the "INK " header (4 bytes)
    const uint8_t header[4] = { 'I', 'N', 'K', ' ' };
    for (int i = 0; i < 4; i++) {
        if (bytes[i] != header[i]) {
            return 0;
        }
    }

    @try {
        // 解析墨水量（第 5 个字节，下标 4）/ Decode ink level from byte 5 (index 4)
        NSInteger inkLevel = bytes[4];

        NSLog(AYLocalizedString(@"墨水量: %ld"), (long)inkLevel);

        // 解析四字节唯一标识（第 6–9 字节，下标 5–8）/ Decode the 4-byte cartridge identifier
        NSString *uniqueId = [NSString stringWithFormat:@"%02X%02X%02X%02X",
                              bytes[5],
                              bytes[6],
                              bytes[7],
                              bytes[8]];

        NSLog(AYLocalizedString(@"墨盒四位唯一标识: %@"), uniqueId);
      self.displayLabel.text = [NSString stringWithFormat:AYLocalizedString(@"墨水量: %ld\n墨盒四位唯一标识: %@"), (long)inkLevel, uniqueId];

        return inkLevel;
    }
    @catch (NSException *exception) {
        return 0;
    }
}

/// 打印进度解析（与 Android 逻辑完全一致）/ Parse print progress using the same logic as Android.
/// data: 必须是 5 字节，格式 FD xx xx xx xx / Data must be 5 bytes in the format `FD xx xx xx xx`.
/// 返回：0~100 的进度值，失败返回 -1 / Returns a progress value from 0 to 100, or -1 on failure.
- (int)onPrintProcess:(NSData *)data {

    // 验证数据长度 / Validate payload length
    if (!data || data.length != 5) {
        return -1;
    }

    const uint8_t *bytes = data.bytes;

    // 验证数据头 (0xFD) / Validate the 0xFD frame header
    if (bytes[0] != 0xFD) {
        return -1;
    }

    // 取最后 1 个字节作为进度（0~255）/ Read the last byte as progress (0~255)
    int progress = bytes[4] & 0xFF;

    // 验证进度范围 (0~100) / Ensure progress is in the expected range
    if (progress > 100) {
        return -1;
    }

    NSLog(AYLocalizedString(@"打印进度: %d"), progress);
    return progress;
}



@end
