//
//  Arg.h
//  fatherArgs
//
//  Created by IPRT on 2022/10/6.
//

#import <Foundation/Foundation.h>
#import "CommandClause.h"
NS_ASSUME_NONNULL_BEGIN

@interface Arg<T> : NSObject
-(T)header;
-(BOOL)newline;
@property (nonatomic , readonly) Arg *(^prepend)(Arg <T> * arg);
@property (nonatomic , readonly) Arg *(^append)(Arg<T> *arg);
-(CommandClause *)clause;
-(NSArray <CommandClause *> *)clauses;
-(void)clear;
@end

NS_ASSUME_NONNULL_END
