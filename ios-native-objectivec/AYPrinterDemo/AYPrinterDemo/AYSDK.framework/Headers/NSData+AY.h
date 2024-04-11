//
//  NSData+AY.h
//  AYSDK
//
//  Created by aiyin on 2023/9/14.
//

#import <Foundation/Foundation.h>

//NS_ASSUME_NONNULL_BEGIN

@interface NSData (AY)

- (NSString *)toRawString;

- (NSString *)toHexString;

@end

//NS_ASSUME_NONNULL_END
