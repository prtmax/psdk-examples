//
//  CPrint.h
//  CPCL
//
//  Created by IPRT on 2022/10/10.
//

#import <father/OnlyTextHeaderArg.h>
typedef NS_ENUM (NSInteger, Mode)
{
    NORMAL     = 0,
    HORIZONTAL    = 1,
};
NS_ASSUME_NONNULL_BEGIN

@interface CPrint : OnlyTextHeaderArg
@property (nonatomic , readonly) CPrint *(^mode)(Mode m);
-(int)getMode;
@end

NS_ASSUME_NONNULL_END
