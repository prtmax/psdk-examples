//
//  PaperTypeArg.h
//  ESC
//
//  Created by aiyin on 2022/4/22.
//

#import "BasicESCArg.h"

typedef enum : NSUInteger {
    paperTypeOne = 0,    // 折叠黑标纸
    paperTypeTwo,        // 连续卷筒纸
    paperTypeThree,      // 不干胶缝隙纸
} PaperType;

NS_ASSUME_NONNULL_BEGIN

@interface EPaperType : BasicESCArg
@property (nonatomic , readonly) EPaperType *(^type)(PaperType paperType);

@end

NS_ASSUME_NONNULL_END
