//
//  DataWriteOperation.h
//  father
//
//  Created by IPRT on 2022/11/8.
//

#import <Foundation/Foundation.h>
#import "WriteControl.h"
#import <adapter/ConnectedDevice.h>
#import "WriteOptions.h"
NS_ASSUME_NONNULL_BEGIN
typedef NS_ENUM (NSUInteger , ESCPrinter){
    ESCPrinter_GENERIC,
    ESCPrinter_BY426BT,
    ESCPrinter_QR285A,
    ESCPrinter_L12
};
typedef NS_ENUM (NSUInteger , CPCLPrinter){
    CPCLPrinter_GENERIC,
    CPCLPrinter_QR365_COMPRESS
};
typedef NS_ENUM (NSUInteger , TSPLPrinter){
    TSPLPrinter_GENERIC
};
typedef enum {
    Raw_TEXT,
    Raw_BINARY
} RawMode;
@interface DataWriteOperation : NSObject
-(instancetype)initWithOptions:(WriteOptions *)options binary:(NSData *)binary connectedDevice:(ConnectedDevice *)connectedDevice;
-(WroteReporter *)write;
@end

NS_ASSUME_NONNULL_END
