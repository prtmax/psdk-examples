//
//  CPrint.h
//  CPCL
//
//  Created by IPRT on 2022/10/10.
//

#import <father/OnlyTextHeaderArg.h>
/**
 * 打印模式
 */
typedef NS_ENUM (NSInteger, Mode) {
    /// 正常打印，不旋转
    NORMAL     = 0,
    /// 整个页面顺时针旋转180°后，再打印
    HORIZONTAL = 1,
};
NS_ASSUME_NONNULL_BEGIN

/**
 * 打印
 */
@interface CPrint : OnlyTextHeaderArg

/// 打印模式
@property (nonatomic , readonly) CPrint *(^mode)(Mode m);
/**
 * 获取打印模式
 */
-(int)getMode;

@end

NS_ASSUME_NONNULL_END
