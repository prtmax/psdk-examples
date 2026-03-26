//
//  RGBConfig.h
//  AYPrinterDemo
//
//  Created by aiyin on 1/31/26.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface RGBConfig : NSObject

@property (nonatomic, assign) NSInteger resolution;          // 分辨率 / Resolution.
@property (nonatomic, copy)   NSString *hardwareVersion;     // 硬件版本 / Hardware version.
@property (nonatomic, copy)   NSString *firmwareVersion;     // 固件版本 / Firmware version.
@property (nonatomic, assign) NSInteger autoShutdown;        // 自动关机时间 / Auto shutdown time.
@property (nonatomic, assign) NSInteger beepEnabled;         // 提示音 / Beep setting.

@end

NS_ASSUME_NONNULL_END
