//
//  WakePrinterArg.h
//  ESC
//
//  Created by aiyin on 2022/4/22.
//

#import <father/OnlyBinaryHeaderArg.h>
#import <father/BinaryCommand.h>
NS_ASSUME_NONNULL_BEGIN

/**
 * 唤醒打印机 每次打印之前都要调用该函数，防止由于打印机进入低功耗模式而丢失数据
 */
@interface WakePrinterArg : OnlyBinaryHeaderArg

@end

NS_ASSUME_NONNULL_END
