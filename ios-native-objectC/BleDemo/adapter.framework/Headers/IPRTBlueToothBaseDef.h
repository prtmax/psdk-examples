//
//  IPRTBlueToothBaseDef.h
//  adapter
//
//  Created by IPRT on 2022/10/25.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN
typedef void (^ReceivedData)(NSData *revData, NSError * _Nullable error);
typedef NS_ENUM (NSUInteger , ConnectionState){
    CONNECTED,
    DISCONNECT
};
@interface IPRTBlueToothBaseDef : NSObject

@end

NS_ASSUME_NONNULL_END
