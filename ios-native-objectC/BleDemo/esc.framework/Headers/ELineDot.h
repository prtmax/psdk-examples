//
//  LineDotArg.h
//  ESC
//
//  Created by aiyin on 2022/4/14.
//

#import "BasicESCArg.h"

NS_ASSUME_NONNULL_BEGIN

@interface ELineDot : BasicESCArg
@property(nonatomic , readonly) ELineDot *(^dot)(int d);
@end

NS_ASSUME_NONNULL_END
