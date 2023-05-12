//
//  PrinterTempHumArg.h
//  ESC
//
//  Created by aiyin on 2022/4/24.
//

#import <father/OnlyBinaryHeaderArg.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * 查询打印机温湿度 : 第1个字节表示温度(摄氏度)   第2个字节表示湿度(百分比)
 */
@interface PrinterTempHumArg : OnlyBinaryHeaderArg

@end

NS_ASSUME_NONNULL_END
