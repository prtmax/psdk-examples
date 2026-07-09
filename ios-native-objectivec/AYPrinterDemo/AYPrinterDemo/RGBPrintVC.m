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
    ReadMarkOperateOTA,            // OTA 升级
    ReadMarkOperatePrinterClean,   // 清洁打印头
    ReadMarkOperateEjectPaper       // 退纸 / 回纸
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
          NSLog(@"清洁完成");
          weakSelf.displayLabel.text = @"清洁完成";
        }
      }
        break;
      case ReadMarkOperatePrint: {
        if (bytes[0] == 0xaa) {
          weakSelf.readMark = ReadMarkNone;
          weakSelf.displayLabel.text = @"打印进度: 100%\n打印完成";
          break;
        }
        int progress = [weakSelf onPrintProcess:data];
        weakSelf.displayLabel.text = [NSString stringWithFormat:@"打印进度: %d", progress];
      }
        break;
      case ReadMarkOperateOTA: {
          weakSelf.readMark = ReadMarkNone;
          NSString *str = data.toRawString;
          weakSelf.displayLabel.text = [str containsString:@"Error"] ? @"升级失败" :@"升级成功";
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
  NSLog(@"设备已断开");
  [self.navigationController popViewControllerAnimated:YES];
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

/// 退纸
- (IBAction)ejectPaper {
  self.readMark = ReadMarkOperateEjectPaper;
  [self.rgbCommand clean];
  [self.rgbCommand ejectPaper];
  [self.bleHelper writeCommands:self.rgbCommand.commands];
}

/// 清洁打印头
- (IBAction)printerClean {
  self.readMark = ReadMarkOperatePrinterClean;
  [self.rgbCommand clean];
  [self.rgbCommand printerClean];
  [self.bleHelper writeCommands:self.rgbCommand.commands];
}

/// 打印自测页
- (IBAction)selfTest {
  self.readMark = ReadMarkNone;
  [self.rgbCommand clean];
  [self.rgbCommand selfTest];
  [self.bleHelper writeCommands:self.rgbCommand.commands];
}

/// 打印图片
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
//  * @param quality  图片质量（0:快速 1:精细 2:照片）
//  * @param mode  0:覆盖 1:或 2:异或 3:自定义 4:JPG 5:PNG 6:BMP
  [self.rgbCommand image:image x:0 y:0 quality:0 mode:4];
  [self.rgbCommand print:1];
  
  [self.bleHelper writeCommands:self.rgbCommand.commands];
}

/// 打印图片
- (IBAction)printEnhance:(id)sender {
  UIImage *image = [UIImage imageNamed:@"caomei.jpg"];
  image = [self compressImageForSN:image];
  self.readMark = ReadMarkOperatePrint;
  [self.rgbCommand clean];
  [self.rgbCommand imageSN:image x:0 y:0 quality:0 mode:4];
  
  [self.bleHelper writeImageSN:self.rgbCommand];
}

/// ota 升级
- (IBAction)ota:(id)sender{
  NSString *filepath = [[NSBundle mainBundle] pathForResource:@"v138868.RM" ofType:nil];
  NSData* filedata = [NSData dataWithContentsOfFile:filepath];
  NSLog(@"filepath: %@\nfiledata: %@", filepath, filedata);
  
  self.readMark = ReadMarkOperateOTA;
  [self.rgbCommand clean];
  [self.rgbCommand ota:filedata];
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

/// 状态掩码项
static NSArray<NSDictionary<NSString *, id> *> *PrinterStatusMasks(void) {
    static NSArray *masks;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        masks = @[
            @{ @"mask": @(0x00000001), @"desc": @"开盖" },
            @{ @"mask": @(0x00000002), @"desc": @"卡纸" },
            @{ @"mask": @(0x00000004), @"desc": @"缺纸" },
            @{ @"mask": @(0x00000008), @"desc": @"缺墨" },
            @{ @"mask": @(0x00000020), @"desc": @"繁忙" },
            @{ @"mask": @(0x00000040), @"desc": @"低压" },
            @{ @"mask": @(0x00000100), @"desc": @"正在取消" },
            @{ @"mask": @(0x00000200), @"desc": @"数据异常" },
            @{ @"mask": @(0x00000400), @"desc": @"机电错误" },
            @{ @"mask": @(0x00000800), @"desc": @"纸道有纸" },
            @{ @"mask": @(0x00001000), @"desc": @"无墨盒" }
        ];
    });
    return masks;
}

/**
 * 解析打印机状态（直接接收 4 字节数据）
 * @param data 4 字节 NSData
 * @return 状态字符串数组（正常时仅包含“正常”）
 */
- (NSArray<NSString *> *)parsePrinterStatus:(NSData *)data {
    NSMutableArray<NSString *> *statuses = [NSMutableArray array];

    // 校验长度
    if (!data || data.length != 4) {
        [statuses addObject:@"错误: 输入必须是四个字节"];
        return statuses;
    }

    const uint8_t *bytes = data.bytes;

    // 小端序 → 32 位整型
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

    // 遍历状态掩码（保持顺序）
    for (NSDictionary *item in PrinterStatusMasks()) {
        uint32_t mask = [item[@"mask"] unsignedIntValue];
        if ((value & mask) != 0) {
            [statuses addObject:item[@"desc"]];
        }
    }

    // 未匹配任何状态
    if (statuses.count == 0) {
        [statuses addObject:
            [NSString stringWithFormat:@"未知状态 (0x%08X)", value]];
    }

    return statuses;
}


#pragma mark - 解析打印机状态数据
- (NSString *)parseStatus:(NSData *)data {
    if (!data || data.length != 5) {
        return @"无效数据: 数据长度错误";
    }

    const uint8_t *bytes = data.bytes;

    // 验证数据头
    if (bytes[0] != 0xFF) {
        return @"无效数据: 数据头不匹配";
    }

    // 组合 4 字节状态码（大端）
    uint32_t statusType =
        ((uint32_t)bytes[1] << 24) |
        ((uint32_t)bytes[2] << 16) |
        ((uint32_t)bytes[3] << 8)  |
        (uint32_t)bytes[4];

    NSString *status = [self mapStatusToString:statusType];
    NSLog(@"主动上报状态: %@", status);
    return status;
}

#pragma mark - 状态码映射
- (NSString *)mapStatusToString:(uint32_t)statusType {
    if (statusType == 0x00000000) {
        return @"正常";
    }

    NSMutableArray<NSString *> *statusList = [NSMutableArray array];

    if (statusType & 0x00000001) {
        [statusList addObject:@"开盖"];
    }
    if (statusType & 0x00000002) {
        [statusList addObject:@"卡纸"];
    }
    if (statusType & 0x00000004) {
        [statusList addObject:@"缺纸"];
    }
    if (statusType & 0x00000008) {
        [statusList addObject:@"缺墨"];
    }
    if (statusType & 0x00000040) {
        [statusList addObject:@"低压"];
    }
    if (statusType & 0x00000100) {
        [statusList addObject:@"正在取消"];
    }
    if (statusType & 0x00000200) {
        [statusList addObject:@"数据异常"];
    }
    if (statusType & 0x00000400) {
        [statusList addObject:@"机电错误"];
    }
    if (statusType & 0x00000800) {
        [statusList addObject:@"纸道有纸"];
    }
    if (statusType & 0x00001000) {
        [statusList addObject:@"无墨盒"];
    }

    if (statusType & 0x10000000) {
        [statusList addObject:@"充电中"];
    }
    if (statusType & 0x20000000) {
        [statusList addObject:@"充电完成"];
    }

    if (statusList.count > 0) {
        return [statusList componentsJoinedByString:@" + "];
    } else {
        return [NSString stringWithFormat:@"未知状态: 0x%08X", statusType];
    }
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

/// 打印进度解析（与 Android 逻辑完全一致）
/// data: 必须是 5 字节，格式 FD xx xx xx xx
/// 返回：0~100 的进度值，失败返回 -1
- (int)onPrintProcess:(NSData *)data {

    // 验证数据长度
    if (!data || data.length != 5) {
        return -1;
    }

    const uint8_t *bytes = data.bytes;

    // 验证数据头 (0xFD)
    if (bytes[0] != 0xFD) {
        return -1;
    }

    // 取最后 1 个字节作为进度（0~255）
    int progress = bytes[4] & 0xFF;

    // 验证进度范围 (0~100)
    if (progress > 100) {
        return -1;
    }

    NSLog(@"打印进度: %d", progress);
    return progress;
}


#pragma mark - payload
/**
 * 确保图片数据在 400KB 以内。
 * 超过限制时逐步降低 JPEG 质量直至满足要求（最低 quality=25）。
 *
 * @param image 原始 UIImage
 * @return 压缩后的 JPEG 数据
 */
- (UIImage *)compressImageForSN:(UIImage *)image {
    if (!image) {
        return nil;
    }

    const NSUInteger kMaxSize = 400 * 1024;
    NSInteger quality = 90;
    NSData *compressedData = nil;

    do {
        compressedData = UIImageJPEGRepresentation(image, quality / 100.0);

        NSLog(@"quality=%ld size=%lu",
              (long)quality,
              (unsigned long)compressedData.length);

        if (compressedData.length <= kMaxSize || quality <= 25) {
            break;
        }

        quality -= 5;
    } while (YES);

    // 转回 UIImage 返回
    return [UIImage imageWithData:compressedData];
}

@end
