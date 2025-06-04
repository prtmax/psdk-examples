//
//  AYNetHelper.h
//  AYSDK
//
//  Created by aiyin on 5/30/25.
//

#import <Foundation/Foundation.h>
@class Command;

typedef NS_ENUM(NSInteger, NetState) {
    NetStateDisconnected,
    NetStateConnected,
    NetStateFailToConnect
};

@protocol AYNetHelperDelegate <NSObject>

- (void)netConnectStateDidChange:(NetState)state;
- (void)netOnReceive:(NSData *_Nullable)data;

@end

NS_ASSUME_NONNULL_BEGIN

@interface AYNetHelper : NSObject

@property(weak, nonatomic) id<AYNetHelperDelegate> delegate;

//+ (instancetype)shareInstance;
- (void)connectIP:(NSString *)ip port:(int)port;
- (void)disconnect;
- (void)write:(Command *)command;

@end

NS_ASSUME_NONNULL_END
