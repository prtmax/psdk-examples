//
//  EWakeup.h
//  ESC
//
//  Created by IPRT on 2022/10/13.
//

#import <father/OnlyBinaryHeaderArg.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * 唤醒打印机 每次打印之前都要调用该函数，防止由于打印机进入低功耗模式而丢失数据
 */
@interface EWakeup : OnlyBinaryHeaderArg

@end

NS_ASSUME_NONNULL_END
