//
//  SingleCommand.h
//  Father
//
//  Created by IPRT on 2022/9/22.
//

#import <Foundation/Foundation.h>
#import <father/Appendat.h>
#import <father/CommandClause.h>
NS_ASSUME_NONNULL_BEGIN

@interface SingleCommand<T> : NSObject
@property (nonatomic , strong) NSString *symbolAfterHeader;
@property (nonatomic , strong) NSString *symbolBetweenArguments;

@property (nonatomic , strong) T header;
@property (nonatomic , readonly) SingleCommand *(^append)(id appender);
@property (nonatomic , readonly) SingleCommand *(^appendNumber)(int number);
@property (nonatomic , readonly) SingleCommand *(^appendText)(NSString *text);
-(instancetype)initWithHeader:(T)header andSymbolAfterHeader:(NSString *)symbolAfterHeader andSymbolBetweenArguments:(NSString *)symbolBetweenArguments;
-(void)append:(Appendat*)appendat;
@end
@interface BasicStringSingleCommand : SingleCommand<NSString *>
@property (nonatomic , copy) void (^callback)(id _Nullable object);

-(NSString *)getOutput;
-(CommandClause *)clause;


@end
NS_ASSUME_NONNULL_END
