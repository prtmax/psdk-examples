//
//  DataTool.m
//  BleDemo
//
//  Created by aiyin on 2023/4/28.
//

#import "DataTool.h"

@implementation DataTool

+ (NSString *)dataToString:(NSData *)data {
    return [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
}

+ (NSString *)dataToHex:(NSData *)data {
    if (!data.length || !data) return @"";
    
    const unsigned char *dataBuffer = (const unsigned char *)[data bytes];
    if (!dataBuffer) {
        return [NSString string];
    }
    
    NSUInteger          dataLength  = [data length];
    NSMutableString     *hexString  = [NSMutableString stringWithCapacity:(dataLength * 2)];
    
    for (int i = 0; i < dataLength; ++i) {
        [hexString appendFormat:@"%02x", (unsigned char)dataBuffer[i]];
    }
    return [NSString stringWithString:hexString];
}

@end
