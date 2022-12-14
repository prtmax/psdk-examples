//
//  QueueConfig.h
//  adapter
//
//  Created by IPRT on 2022/11/11.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface QueueConfig : NSObject
-(QueueConfig *)def;
@property (nonatomic , assign) BOOL enable;
@property (nonatomic , assign) int interval;
@end

NS_ASSUME_NONNULL_END
