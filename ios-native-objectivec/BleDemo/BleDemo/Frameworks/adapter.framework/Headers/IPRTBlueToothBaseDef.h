//
//  IPRTBlueToothBaseDef.h
//  adapter
//
//  Created by IPRT on 2022/10/25.
//

#import <Foundation/Foundation.h>


typedef void (^ReceivedData)(NSData *revData, NSError *error);

/**
 * 连接状态
 */
typedef NS_ENUM (NSUInteger , ConnectionState){
    /// 已连接
    CONNECTED,
    /// 未连接
    DISCONNECT
};

