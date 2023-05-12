//
//  TDirection.h
//  TSPL
//
//  Created by IPRT on 2022/10/12.
//

#import <tspl/BasicTSPLArg.h>
/**
 * 镜像
 */
typedef NS_ENUM (NSInteger, Mirror) {
    /// 不镜像
    NO_MIRROR = 0,
    /// 镜像
    MIRROR    = 1
};

/**
 * 方向
 */
typedef NS_ENUM (NSInteger, Direction) {
    /// 上端先出
    UP_OUT   = 0,
    /// 下端先出
    DOWN_OUT = 1
};

NS_ASSUME_NONNULL_BEGIN

/**
 * 设置打印方向
 */
@interface TDirection : BasicTSPLArg

/// 镜像
@property (nonatomic , readonly) TDirection *(^mirror)(Mirror mir);
/// 方向
@property (nonatomic , readonly) TDirection *(^direction)(Direction dir);
/**
 * 获取镜像
 */
-(NSInteger)getMirror;
/**
 * 获取方向
 */
-(NSInteger)getDirection;

@end

NS_ASSUME_NONNULL_END
