//
//  WifiCommand.h
//  AYSDK
//
//  Created by aiyin on 2024/2/4.
//

#import <Foundation/Foundation.h>
#import <AYSDK/Command.h>

NS_ASSUME_NONNULL_BEGIN

@interface WifiCommand : Command

- (void)state;

/// 获取 wifi 密码
- (void)getPassword;

/// 获取 wifi 名称
- (void)getSSID;

/// 获取 wifi DHCP
- (void)getDHCP;

/// 设置 wifi 名称 密码
- (void)setSSID:(NSString *)name pwd:(NSString *)password;

/// 设置 wifi ip 子网掩码 网关
- (void)setIP:(NSString *)ip mask:(NSString *)mask gateway:(NSString *)gateway;

/// 设置动态ip
- (void)setDHCP;

/// 获取 wifi ip
- (void)getIP;

/// 获取 wifi 子网掩码
- (void)getMask;

/// 获取 wifi 网关
- (void)getGateway;

@end

NS_ASSUME_NONNULL_END
