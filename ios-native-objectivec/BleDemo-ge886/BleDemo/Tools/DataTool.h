//
//  DataTool.h
//  BleDemo
//
//  Created by aiyin on 2023/4/28.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface DataTool : NSObject

+ (NSString *)dataToString:(NSData *)data;

+ (NSString *)dataToHex:(NSData *)data;

@end

NS_ASSUME_NONNULL_END
