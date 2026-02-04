//
//  RGBConfig.m
//  AYPrinterDemo
//
//  Created by aiyin on 1/31/26.
//

#import "RGBConfig.h"

@implementation RGBConfig

- (NSString *)description {
    NSString *shutdownDesc;

    switch (self.autoShutdown) {
        case 0:
            shutdownDesc = @"永不关机";
            break;
        case 1:
            shutdownDesc = @"15分钟后关机";
            break;
        case 2:
            shutdownDesc = @"30分钟后关机";
            break;
        case 3:
            shutdownDesc = @"60分钟后关机";
            break;
        default:
            shutdownDesc = [NSString stringWithFormat:@"未知设置(%ld)",
                            (long)self.autoShutdown];
            break;
    }

    return [NSString stringWithFormat:
            @"打印机配置:\n"
             "  分辨率: %ld dpi\n"
             "  硬件版本: %@\n"
             "  固件版本: %@\n"
             "  定时关机: %@\n"
             "  提示音: %@",
            (long)self.resolution,
            self.hardwareVersion ?: @"",
            self.firmwareVersion ?: @"",
            shutdownDesc,
            self.beepEnabled == 1 ? @"开启" : @"关闭"];
}

@end
