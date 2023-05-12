//
//  NewDefaultCommand.h
//  father
//
//  Created by IPRT on 2022/12/7.
//

#import <father/Command.h>

NS_ASSUME_NONNULL_BEGIN

@interface DefaultCommand : Command
-(instancetype)initWithClauses:(NSArray <CommandClause *> *)clauses andVariable:(NSDictionary *)variable;
@end

NS_ASSUME_NONNULL_END
