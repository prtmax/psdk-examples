//
//  Commander.h
//  father
//
//  Created by IPRT on 2022/12/7.
//

#import <Foundation/Foundation.h>
#import <father/Arg.h>
#import <father/Command.h>
NS_ASSUME_NONNULL_BEGIN

@interface Commander : NSObject
+(Commander *)make;
@property(nonatomic , readonly) Commander *(^pushString)(NSString *command);
@property(nonatomic , readonly) Commander *(^pushStringAndCharset)(NSString *command,CFStringEncodings charset);
@property(nonatomic , readonly) Commander *(^pushStringAndNewline)(NSString *command,BOOL isNewline);
@property(nonatomic , readonly) Commander *(^pushStringAndCharsetAndNewline)(NSString *command , CFStringEncodings charset, BOOL isNewline);
@property(nonatomic , readonly) Commander *(^pushBinary)(NSData *binary);
@property(nonatomic , readonly) Commander *(^pushBinaryAndNewline)(NSData *binary, BOOL isNewline);
@property(nonatomic , readonly) Commander *(^pushArg)(Arg *arg);
@property(nonatomic , readonly) Commander *(^pushClause)(CommandClause *clause);
@property(nonatomic , readonly) Commander *(^pushClauseAndNewline)(CommandClause *clause ,BOOL isNewline);
@property(nonatomic , readonly) Commander *(^newline)(void);
@property(nonatomic , readonly) Commander *(^varibleKeyValue)(NSString *name, id value);
@property(nonatomic , readonly) Commander *(^clear)(void);
-(void)pushArg:(Arg *)arg;
-(Command *)command;
@end

NS_ASSUME_NONNULL_END
