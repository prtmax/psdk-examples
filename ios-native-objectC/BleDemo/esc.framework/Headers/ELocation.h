//
//  PrintLocationArg.h
//  ESC
//
//  Created by aiyin on 2022/4/22.
//

//#import <father/OnlyBinaryHeaderArg.h>
#import "BasicESCArg.h"

typedef enum : NSUInteger {
    printLocation_L = 0,    // 居左
    printLocation_M,        // 居中
    printLocation_R,        // 居右
} PrintLocation;

NS_ASSUME_NONNULL_BEGIN

@interface ELocation : BasicESCArg

@property(nonatomic , readonly) ELocation *(^location)(int loc);

@end

NS_ASSUME_NONNULL_END
