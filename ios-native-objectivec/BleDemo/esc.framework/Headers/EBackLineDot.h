//
//  EBackLineDot.h
//  ESC
//
//  Created by IPRT on 2022/10/11.
//

#import "BasicESCArg.h"

NS_ASSUME_NONNULL_BEGIN

@interface EBackLineDot : BasicESCArg
@property (nonatomic, readonly)EBackLineDot *(^dot)(int d);
@end

NS_ASSUME_NONNULL_END
