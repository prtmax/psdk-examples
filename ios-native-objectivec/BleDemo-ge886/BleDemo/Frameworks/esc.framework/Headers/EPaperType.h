//
//  PaperTypeArg.h
//  ESC
//
//  Created by aiyin on 2022/4/22.
//

#import "BasicESCArg.h"

/**
 * 纸张类型
 */
typedef enum : NSUInteger {
    paperTypeOne = 0,    // 折叠黑标纸
    paperTypeTwo,        // 连续卷筒纸
    paperTypeThree,      // 不干胶缝隙纸
} PaperType;

NS_ASSUME_NONNULL_BEGIN

/**
 * 设置纸张类型
 */
@interface EPaperType : BasicESCArg

/// 纸张类型
@property (nonatomic , readonly) EPaperType *(^type)(PaperType paperType);

@end

NS_ASSUME_NONNULL_END
