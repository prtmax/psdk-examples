//
//  SimpleCheck.h
//  father
//
//  Created by IPRT on 2022/11/16.
//

#import "Checker.h"

NS_ASSUME_NONNULL_BEGIN

@interface SimpleCheck : Checker
@property(nonatomic , readonly)SimpleCheck *(^allowedNames)(NSArray< NSString *> *names);
@end

NS_ASSUME_NONNULL_END
