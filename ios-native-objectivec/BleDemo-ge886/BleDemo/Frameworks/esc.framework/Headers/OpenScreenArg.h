//
//  OpenScreenArg.h
//  ESC
//
//  Created by aiyin on 2022/4/22.
//

#import <father/OnlyBinaryHeaderArg.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * 开启／关闭屏幕
 */
@interface OpenScreenArg : OnlyBinaryHeaderArg

/// isOpen YES:开启屏幕 NO:关闭屏幕
@property (nonatomic, assign) BOOL isOpen;

@end

NS_ASSUME_NONNULL_END
