#import <Foundation/Foundation.h>

@interface EMAPIDemoDevice : NSObject

@property(nonatomic, copy) NSString *name;
@property(nonatomic, copy) NSString *mac;
@property(nonatomic, copy) NSString *protocolLabel;
@property(nonatomic, assign, getter=isSimulated) BOOL simulated;
@property(nonatomic, strong, nullable) id connectedDevice;

+ (instancetype)simulatedPrinter;

@end
