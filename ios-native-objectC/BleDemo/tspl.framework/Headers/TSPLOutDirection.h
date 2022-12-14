//
//  TSPLOutDirection.h
//  tspl
//
//  Created by IPRT on 2022/11/1.
//

#import <Foundation/Foundation.h>
typedef NS_ENUM (NSInteger, TOutDirection)
{
    /**
      * 0-上端先出
      */
    UP_OUT         = 0,
    /**
       *1－下端先出
       */
    DOWN_OUT       = 1
};

NS_ASSUME_NONNULL_BEGIN

@interface TSPLOutDirection : NSObject

@end

NS_ASSUME_NONNULL_END
