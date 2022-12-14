//
//  LineArg.h
//  ESC
//
//  Created by aiyin on 2022/4/14.
//

#import "BasicESCArg.h"
#import "BasicLineArg.h"

NS_ASSUME_NONNULL_BEGIN

@interface ELine : BasicESCArg<BasicLineArg>
@property (nonatomic , readonly) ELine *(^x)(int lx);
@property (nonatomic , readonly) ELine *(^y)(int ly);
@end

NS_ASSUME_NONNULL_END
