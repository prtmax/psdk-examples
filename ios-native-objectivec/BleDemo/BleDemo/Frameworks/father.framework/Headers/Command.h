//
//  Command.h
//  Father
//
//  Created by IPRT on 2022/9/23.
//

#import <Foundation/Foundation.h>
#import <father/HexOutput.h>
#import <father/CommandClause.h>
#import <father/PVariableKit.h>
#import <father/PsdkConst.h>
NS_ASSUME_NONNULL_BEGIN

@interface Command : NSObject
-(NSData *)binary;
-(NSString *)string;
-(NSString *)base64;
-(NSString *)getStringWithCharset:(CFStringEncodings)charset;
-(NSString *)hex;
-(NSString *)getHexWihtOutput:(HexOutput *)output;

@end

NS_ASSUME_NONNULL_END
