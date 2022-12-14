//
//  CallbackData.h
//  Father
//
//  Created by IPRT on 2022/10/25.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN
@interface DataWrite : NSObject
@property(nonatomic , strong)NSData *binary;
@property(nonatomic , assign)int currentTimes;
@property(nonatomic , assign)int totalTimes;
@end
@interface CallbackData : NSObject
@property (nonatomic,strong)DataWrite *dataWrite;
@end

NS_ASSUME_NONNULL_END
