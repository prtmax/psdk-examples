//
//  ShowType.h
//  TSPL
//
//  Created by IPRT on 2022/10/11.
//

#import <Foundation/Foundation.h>
typedef NS_ENUM (NSInteger, TShowType)
{
    /**
      * 不显示
      */
    NO_SHOW         = 0,
    /**
       * 居左显示
       */
    SHOW_LEFT       = 1,
    /**
     * 居中显示
     */
    SHOW_CENTER     = 2,
    /**
     * 居右显示
     */
    SHOW_RIGHT      = 3
};

NS_ASSUME_NONNULL_BEGIN

@interface TSPLShowType : NSObject
@property(nonatomic , readonly) TSPLShowType *(^showType)(TShowType stypevoid);;
-(int)getShowType;
@end

NS_ASSUME_NONNULL_END
