//
//  ShutTimeArg.h
//  ESC
//
//  Created by aiyin on 2022/4/22.
//

#import "BasicESCArg.h"

NS_ASSUME_NONNULL_BEGIN

/**
 * 设置关机时间(单位：分钟，不接受小数)
 */
@interface ESetShutdownTime : BasicESCArg

/// 关机时间
@property (nonatomic , readonly) ESetShutdownTime *(^time)(int shuttime);

@end

NS_ASSUME_NONNULL_END
