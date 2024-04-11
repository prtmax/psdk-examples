//
//  ESC.h
//  AYSDK
//
//  Created by aiyin on 2023/9/14.
//

#import <Foundation/Foundation.h>
#import <AYSDK/Command.h>
#import <UIKit/UIKit.h>
#import <AYSDK/ETypes.h>

NS_ASSUME_NONNULL_BEGIN

@interface EscCommand : Command

#pragma mark - 打印指令/print command
- (void)enable;

- (void)wake;

- (void)position;

- (void)stopPrintJob;

- (void)linedots:(Byte)linedots;

- (void)contentPosition:(EPosition)position;

- (void)image:(UIImage *)image compress:(BOOL)compress mode:(EImageMode)mode;

#pragma mark - 查询指令/query command
- (void)state;

- (void)btName;

- (void)btVersion;

- (void)sn;

- (void)mac;

- (void)batteryVol;

- (void)temperatureAndHumidity;

- (void)printerVersion;

- (void)printerModel;

- (void)printerInfo;

- (void)shutTime;

- (void)paperType;

/**
 * 获取标签纸张信息
 */
- (void)nfcPaper;

/**
 * 获取标签UID
 */
- (void)nfcUID;

/**
 * 获取标签使用长度
 */
- (void)nfcUsedLength;

/**
 *  获取标签剩余长度
 */
- (void)nfcRestLength;


#pragma mark - 设置指令/setting command

- (void)shutTime:(int)time;

-(void)thickness:(EThickness)thickness;

- (void)paperType:(EPaperType)type;

@end

NS_ASSUME_NONNULL_END
