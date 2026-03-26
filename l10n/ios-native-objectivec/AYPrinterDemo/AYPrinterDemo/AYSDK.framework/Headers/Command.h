//
//  Command.h
//  AYSDK
//
//  Created by aiyin on 2024/1/5.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface Command : NSObject

/**
 * 清空指令
 */
- (void)clean;

/**
 * 添加自定义指令
 */
- (void)addCustomCommand:(NSData *)cmd;

/**
 * 获取指令
 */
- (NSMutableArray<NSData *> *)commands;

#pragma mark - debug
- (NSArray<NSString *> *)hexCommands;

- (NSArray<NSString *> *)rawCommands;

@end

NS_ASSUME_NONNULL_END
