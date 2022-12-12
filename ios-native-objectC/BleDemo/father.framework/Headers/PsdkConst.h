//
//  PsdkConst.h
//  Father
//
//  Created by aiyin on 2022/4/11.
//
#import <Foundation/Foundation.h>

@interface PsdkConst : NSObject

+ (NSString *)CR;
+ (NSString *)LF;
+ (NSString *)CRLF;

+ (NSStringEncoding)DEF_CHARSET;
+ (NSData *)DEF_NEWLINE_BINARY;
+ (NSArray<NSString *> *)DEF_AUTHORS;
+ (BOOL)DEF_ENABLED_NEWLINE;
+ (int)DEF_WRITE_CHUNK_SIZE;
+ (NSData *)EMPTY_BYTES;

@end


//FOUNDATION_EXPORT NSStringEncoding gbkEncoding;


//FOUNDATION_EXPORT BOOL DEF_ENABLED_NEWLINE;


//FOUNDATION_EXPORT NSData * const EMPTY_BYTES;


