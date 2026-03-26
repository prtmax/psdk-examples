//
//  AYPrinter.h
//  AYSDK
//
//  Created by aiyin on 2024/1/13.
//

#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>

NS_ASSUME_NONNULL_BEGIN

@interface AYPrinter : NSObject

@property(strong, nonatomic) NSString *name;
@property(strong, nonatomic) NSString *mac;
@property(strong, nonatomic) NSString *uuid;
@property(strong, nonatomic) NSNumber *rssi;
@property(strong, nonatomic) CBPeripheral *peripheral;

@end

NS_ASSUME_NONNULL_END
