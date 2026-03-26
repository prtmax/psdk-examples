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
            shutdownDesc = NSLocalizedString(@"永不关机", nil);
            break;
        case 1:
            shutdownDesc = NSLocalizedString(@"15分钟后关机", nil);
            break;
        case 2:
            shutdownDesc = NSLocalizedString(@"30分钟后关机", nil);
            break;
        case 3:
            shutdownDesc = NSLocalizedString(@"60分钟后关机", nil);
            break;
        default:
            shutdownDesc = [NSString stringWithFormat:NSLocalizedString(@"未知设置(%ld)", nil),
                            (long)self.autoShutdown];
            break;
    }

    return [NSString stringWithFormat:
            NSLocalizedString(@"打印机配置:\n  分辨率: %ld dpi\n  硬件版本: %@\n  固件版本: %@\n  定时关机: %@\n  提示音: %@", nil),
            (long)self.resolution,
            self.hardwareVersion ?: @"",
            self.firmwareVersion ?: @"",
            shutdownDesc,
            self.beepEnabled == 1 ? NSLocalizedString(@"开启", nil) : NSLocalizedString(@"关闭", nil)];
}

@end
