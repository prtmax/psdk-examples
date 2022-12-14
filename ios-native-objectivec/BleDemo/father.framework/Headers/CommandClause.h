//
//  CommandClause.h
//  Father
//
//  Created by aiyin on 2022/3/18.
//

#import <Foundation/Foundation.h>
 
typedef enum {
    TEXT,
    BINARY,
    NEWLINE,
    NONE
} Type;

@interface CommandClause : NSObject

@property (nonatomic, assign) Type type;
@property (nonatomic, assign) NSData *binary;
@property (nonatomic, strong) NSString *text;
@property (nonatomic, assign) CFStringEncodings charset;
//public
+ (instancetype)commandClauseWithText:(NSString *)command;
+ (instancetype)commandClauseWithText:(NSString *)command andCharset:(CFStringEncodings)charset;
+ (instancetype)commandClauseWithBinary:(NSData *)binary;
+ (instancetype)commandClauseWithNewline;

- (Type)type;

@end


