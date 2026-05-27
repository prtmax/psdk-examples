#import "EMAPIDemoLogEntry.h"

@implementation EMAPIDemoLogEntry

+ (instancetype)entryWithTitle:(NSString *)title message:(NSString *)message bytes:(NSData *)bytes
{
    EMAPIDemoLogEntry *entry = [[EMAPIDemoLogEntry alloc] init];
    entry.title = title;
    entry.message = message;
    entry.bytes = bytes;
    entry.createdAt = [NSDate date];
    return entry;
}

@end
