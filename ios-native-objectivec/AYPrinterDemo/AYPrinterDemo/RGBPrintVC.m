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
    ReadMarkOperatePrint,          // 打印操作
    ReadMarkOperateStatus,         // 打印机状态查询
    ReadMarkOperateBatVol,         // 电量查询
    ReadMarkOperateShutdownTime,   // 设置关机时间
    ReadMarkOperateInfo,           // 设备所有信息
    ReadMarkOperateInkBoxInfo,     // 墨盒信息
    ReadMarkOperateOTA             // OTA 升级
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
    switch (weakSelf.readMark) {
      case ReadMarkOperateBatVol:
        [weakSelf parseBatteryStatus:data];
        break;
      case ReadMarkOperateStatus:
        [weakSelf parsePrinterStatus:data];
        break;
      case ReadMarkOperateInfo:
        [weakSelf parseConfigResponse:data];
        break;
      case ReadMarkOperateInkBoxInfo:
        [weakSelf parseInkStatus:data];
        break;
        
      default:
        weakSelf.displayLabel.text = @"";
        break;
    }
    
    weakSelf.readMark = ReadMarkNone;
  };
}

#pragma mark - click event
/// 查询电池电量
- (IBAction)batteryVolume:(UIButton *)sender {
  self.readMark = ReadMarkOperateBatVol;
  [self.rgbCommand clean];
  [self.rgbCommand batteryVolume];
  [self.bleHelper writeCommands:self.rgbCommand.commands];
}

/// 查询打印机当前状态
- (IBAction)state:(UIButton *)sender {
  self.readMark = ReadMarkOperateStatus;
  [self.rgbCommand clean];
  [self.rgbCommand state];
  [self.bleHelper writeCommands:self.rgbCommand.commands];
}

/// 设置自动关机时间
- (IBAction)setShutdownTime:(UIButton *)sender {
  self.readMark = ReadMarkOperateShutdownTime;
  [self.rgbCommand clean];
  [self.rgbCommand setShutdownTime:1];
  [self.bleHelper writeCommands:self.rgbCommand.commands];
}

/// 查询打印机配置信息
- (IBAction)info:(UIButton *)sender {
  self.readMark = ReadMarkOperateInfo;
  [self.rgbCommand clean];
  [self.rgbCommand info];
  [self.bleHelper writeCommands:self.rgbCommand.commands];
}

/// 查询墨盒 / 碳带信息
- (IBAction)inkBoxInfo:(UIButton *)sender {
  self.readMark = ReadMarkOperateInkBoxInfo;
  [self.rgbCommand clean];
  [self.rgbCommand inkBoxInfo];
  [self.bleHelper writeCommands:self.rgbCommand.commands];
}

#pragma mark - 解析
/**
 * 解析电池状态
 * @param data 电池状态数据
 * @return 电量（0 表示解析失败）
 */
- (NSInteger)parseBatteryStatus:(NSData *)data {
    // 验证数据长度
    if (!data || data.length < 12) {
        return 0;
    }

    const unsigned char *bytes = data.bytes;

    // 验证数据头 "BATTERY "（8 字节）
    const unsigned char header[8] = { 'B','A','T','T','E','R','Y',' ' };
    for (int i = 0; i < 8; i++) {
        if (bytes[i] != header[i]) {
            return 0;
        }
    }

    @try {
        // 解析电量百分比（第 9 个字节，下标 8）
        uint8_t batteryByte = bytes[8];
        NSInteger high = (batteryByte >> 4) & 0x0F;
        NSInteger low  = batteryByte & 0x0F;
        NSInteger batteryLevel = high * 10 + low;

        NSLog(@"电量: %ld", (long)batteryLevel);

        // 解析充电状态（第 10 个字节，下标 9）
        BOOL isCharging = bytes[9] == 0x01;

        NSLog(@"充电状态: %@", isCharging ? @"充电中" : @"未充电");
        self.displayLabel.text = [NSString stringWithFormat:@"电量: %ld\n充电状态: %@", (long)batteryLevel, isCharging ? @"充电中" : @"未充电"];

        return batteryLevel;
    }
    @catch (NSException *exception) {
        return 0;
    }
}

/**
 * 解析打印机状态（直接接收 4 字节数据）
 * @param data 4 字节 NSData
 * @return 状态字符串数组（正常时仅包含“正常”）
 */
- (NSArray<NSString *> *)parsePrinterStatus:(NSData *)data {
    NSMutableArray<NSString *> *statuses = [NSMutableArray array];

    // 校验输入长度
    if (!data || data.length != 4) {
        [statuses addObject:@"错误: 输入必须是四个字节"];
        return statuses;
    }

    const uint8_t *bytes = data.bytes;

    // 小端序转 32 位整数
    uint32_t value =
        (bytes[0] & 0xFF) |
        ((bytes[1] & 0xFF) << 8) |
        ((bytes[2] & 0xFF) << 16) |
        ((bytes[3] & 0xFF) << 24);

    // 正常状态
    if (value == 0) {
        [statuses addObject:@"正常"];
        return statuses;
    }

    // 状态掩码表（等价于 Java 的 STATUS_MASKS）
    NSDictionary<NSNumber *, NSString *> *statusMasks = @{
        // 示例（你按协议补全）
        @(0x00000001): @"缺纸",
        @(0x00000002): @"开盖",
        @(0x00000004): @"过热",
        @(0x00000008): @"低电量"
    };

    // 遍历掩码
    [statusMasks enumerateKeysAndObjectsUsingBlock:^(NSNumber *key, NSString *obj, BOOL *stop) {
        uint32_t mask = key.unsignedIntValue;
        if ((value & mask) != 0) {
            [statuses addObject:obj];
        }
    }];

    // 没有匹配到任何状态
    if (statuses.count == 0) {
        [statuses addObject:
            [NSString stringWithFormat:@"未知状态 (0x%08X)", value]];
    }
    self.displayLabel.text = [statuses componentsJoinedByString:@"+"];

    return statuses;
}

/**
 * 解析打印机配置响应
 * @param data 配置响应数据
 * @return Config 对象，解析失败返回 nil
 */
- (RGBConfig *)parseConfigResponse:(NSData *)data {
    // 最小长度校验
    if (!data || data.length < 18) {
        return nil;
    }

    const uint8_t *bytes = data.bytes;

    // 校验数据头 "CONFIG "（7 字节）
    const uint8_t header[7] = { 'C','O','N','F','I','G',' ' };
    for (int i = 0; i < 7; i++) {
        if (bytes[i] != header[i]) {
            return nil;
        }
    }

  RGBConfig *config = [[RGBConfig alloc] init];

    @try {
        NSInteger offset = 7; // 跳过 "CONFIG "

        // 1. 分辨率（2 字节，大端）
        config.resolution =
            ((bytes[offset] & 0xFF) << 8) |
             (bytes[offset + 1] & 0xFF);
        offset += 2;

        // 2. 硬件版本（3 字节）
        config.hardwareVersion =
            [NSString stringWithFormat:@"%d.%d.%d",
             bytes[offset] & 0xFF,
             bytes[offset + 1] & 0xFF,
             bytes[offset + 2] & 0xFF];
        offset += 3;

        // 3. 固件版本（3 字节）
        uint8_t fwByte1 = bytes[offset];
        NSInteger major = (fwByte1 >> 4) & 0x0F; // 高 4 位
        NSInteger minor = fwByte1 & 0x0F;        // 低 4 位
        NSInteger build =
            ((bytes[offset + 1] & 0xFF) << 8) |
             (bytes[offset + 2] & 0xFF);

        config.firmwareVersion =
            [NSString stringWithFormat:@"%ld.%ld.%ld",
             (long)major, (long)minor, (long)build];
        offset += 3;

        // 4. 自动关机（1 字节）
        config.autoShutdown = bytes[offset] & 0xFF;
        offset++;

        // 5. 提示音（1 字节）
        config.beepEnabled = bytes[offset] & 0xFF;
        offset++;

        // 结束符 \r\n 可选校验（你 Java 里也是注释掉的）

        NSLog(@"打印机所有信息: %@", config);
        self.displayLabel.text = [NSString stringWithFormat:@"打印机所有信息: %@", config.description];
      
        return config;

    }
    @catch (NSException *exception) {
        return nil;
    }
}


/**
 * 解析墨盒状态
 * @param data 墨盒状态数据
 * @return 墨水量（0 表示解析失败）
 */
- (NSInteger)parseInkStatus:(NSData *)data {
    // 校验数据长度
    if (!data || data.length < 11) {
        return 0;
    }

    const uint8_t *bytes = data.bytes;

    // 校验数据头 "INK "（4 字节）
    const uint8_t header[4] = { 'I', 'N', 'K', ' ' };
    for (int i = 0; i < 4; i++) {
        if (bytes[i] != header[i]) {
            return 0;
        }
    }

    @try {
        // 解析墨水量（第 5 个字节，下标 4）
        NSInteger inkLevel = bytes[4];

        NSLog(@"墨水量: %ld", (long)inkLevel);

        // 解析四字节唯一标识（第 6–9 字节，下标 5–8）
        NSString *uniqueId = [NSString stringWithFormat:@"%02X%02X%02X%02X",
                              bytes[5],
                              bytes[6],
                              bytes[7],
                              bytes[8]];

        NSLog(@"墨盒四位唯一标识: %@", uniqueId);
      self.displayLabel.text = [NSString stringWithFormat:@"墨水量: %ld\n墨盒四位唯一标识: %@", (long)inkLevel, uniqueId];

        return inkLevel;
    }
    @catch (NSException *exception) {
        return 0;
    }
}


@end
