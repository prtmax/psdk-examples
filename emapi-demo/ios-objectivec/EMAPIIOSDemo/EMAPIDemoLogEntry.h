#import <Foundation/Foundation.h>

@interface EMAPIDemoLogEntry : NSObject

@property(nonatomic, copy) NSString *title;
@property(nonatomic, copy) NSString *message;
@property(nonatomic, copy, nullable) NSData *bytes;
@property(nonatomic, strong) NSDate *createdAt;

+ (instancetype)entryWithTitle:(NSString *)title message:(NSString *)message bytes:(nullable NSData *)bytes;

@end
