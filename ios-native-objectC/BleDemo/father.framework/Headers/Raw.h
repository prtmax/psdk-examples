//
//  Raw.h
//  father
//
//  Created by IPRT on 2022/11/10.
//

#import "EasyArg.h"
#import "DataWriteOperation.h"
#import "PsdkConst.h"
NS_ASSUME_NONNULL_BEGIN
@class Builder;
@interface Raw : EasyArg
+(Raw *)createWithText:(NSString *)text;
+(Raw *)createWithBinary:(NSData *)binary;
+(Raw *)createWithText:(NSString *)text encoding:(CFStringEncodings)charset;
@property(nonatomic , strong) Raw *(^newline)(BOOL isNewline);
-(BOOL)getNewline;
+(Raw *)make;

@end
NS_ASSUME_NONNULL_END
