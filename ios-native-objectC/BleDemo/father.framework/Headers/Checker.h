//
//  Checker.h
//  father
//
//  Created by IPRT on 2022/11/16.
//

#import <father/father.h>

NS_ASSUME_NONNULL_BEGIN

@interface Checker : Lifecycle
-(BOOL)check:(Lifecycle *)lifecycle;
@end

NS_ASSUME_NONNULL_END
