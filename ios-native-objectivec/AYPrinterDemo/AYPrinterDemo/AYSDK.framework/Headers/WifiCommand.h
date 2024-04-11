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

- (void)getPassword;

- (void)getSSID;

- (void)setSSID:(NSString *)name pwd:(NSString *)password;

@end

NS_ASSUME_NONNULL_END
