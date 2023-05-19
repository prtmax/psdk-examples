//
//  ReadOptions.h
//  adapter
//
//  Created by IPRT on 2022/10/24.
//

#import <Foundation/Foundation.h>
#import "IPRTBlueToothBaseDef.h"

NS_ASSUME_NONNULL_BEGIN

@interface ReadOptions : NSObject

@property(nonatomic, readonly) ReadOptions *(^timeout)(int time);
@property(nonatomic, copy) ReceivedData callBack;
- (ReadOptions *)def;
- (int)getTimeout;

@end

NS_ASSUME_NONNULL_END
