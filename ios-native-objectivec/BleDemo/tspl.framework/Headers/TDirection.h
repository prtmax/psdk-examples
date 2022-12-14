//
//  TDirection.h
//  TSPL
//
//  Created by IPRT on 2022/10/12.
//

#import <tspl/BasicTSPLArg.h>
typedef NS_ENUM (NSInteger, Mirror)
{
    /**
       * 不镜像
       */
    NO_MIRROR         = 0,
    /**
        * 镜像
        */
    MIRROR            = 1
};
typedef NS_ENUM (NSInteger, Direction)
{
    /**
         * 上端先出
         */
    UP_OUT         = 0,
    /**
         * 下端先出
         */
    DOWN_OUT       = 1
};
NS_ASSUME_NONNULL_BEGIN

@interface TDirection : BasicTSPLArg
@property (nonatomic , readonly) TDirection *(^mirror)(Mirror mir);
@property (nonatomic , readonly) TDirection *(^direction)(Direction dir);
-(NSInteger)getMirror;
-(NSInteger)getDirection;
@end

NS_ASSUME_NONNULL_END
