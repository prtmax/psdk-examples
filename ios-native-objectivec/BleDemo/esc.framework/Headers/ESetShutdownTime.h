//
//  ShutTimeArg.h
//  ESC
//
//  Created by aiyin on 2022/4/22.
//

#import "BasicESCArg.h"

NS_ASSUME_NONNULL_BEGIN

@interface ESetShutdownTime : BasicESCArg
@property (nonatomic , readonly) ESetShutdownTime *(^time)(int shuttime);

@end

NS_ASSUME_NONNULL_END
