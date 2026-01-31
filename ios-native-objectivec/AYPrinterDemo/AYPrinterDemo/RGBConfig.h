//
//  RGBConfig.h
//  AYPrinterDemo
//
//  Created by aiyin on 1/31/26.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface RGBConfig : NSObject

@property (nonatomic, assign) NSInteger resolution;          // 分辨率
@property (nonatomic, copy)   NSString *hardwareVersion;     // 硬件版本
@property (nonatomic, copy)   NSString *firmwareVersion;     // 固件版本
@property (nonatomic, assign) NSInteger autoShutdown;        // 自动关机时间
@property (nonatomic, assign) NSInteger beepEnabled;         // 提示音

@end

NS_ASSUME_NONNULL_END
