//
//  NSString+AY.h
//  AYSDK
//
//  Created by aiyin on 2023/9/12.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSString (AY)

// 字符串转 Gbk data
- (NSData *)toGbkData;

// 16进制字符串转nadata
+ (NSData *)convertHexStrToData:(NSString *)string;

@end

NS_ASSUME_NONNULL_END
