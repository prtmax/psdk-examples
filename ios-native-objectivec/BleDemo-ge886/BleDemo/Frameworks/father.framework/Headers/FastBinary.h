//
//  FastBinary.h
//  Father
//
//  Created by IPRT on 2022/10/13.
//
#import "PsdkConst.h"
#import <Foundation/Foundation.h>
NS_ASSUME_NONNULL_BEGIN

@interface FastBinary : NSObject
+(instancetype)make;
@property(nonatomic, readonly) FastBinary *(^appendData)(NSData *data);
@property(nonatomic, readonly) FastBinary *(^appendString)(NSString *string);
@property(nonatomic, readonly) FastBinary *(^appendNumber)(int num);
@property(nonatomic, readonly) FastBinary *(^appendArgWithEncoding)(NSString *arg,NSStringEncoding encoding);
-(NSData *)output;
@end

NS_ASSUME_NONNULL_END
