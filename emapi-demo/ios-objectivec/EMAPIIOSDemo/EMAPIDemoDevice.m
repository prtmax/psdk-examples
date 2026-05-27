#import "EMAPIDemoDevice.h"

@implementation EMAPIDemoDevice

+ (instancetype)simulatedPrinter
{
    EMAPIDemoDevice *device = [[EMAPIDemoDevice alloc] init];
    device.name = @"EMAPI 模拟打印机";
    device.mac = @"SIM-00-00-EMAPI";
    device.protocolLabel = @"Bluetooth Classic";
    device.simulated = YES;
    return device;
}

@end
