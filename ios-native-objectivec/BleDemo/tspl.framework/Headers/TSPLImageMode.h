//
//  ImageMode.h
//  TSPL
//
//  Created by IPRT on 2022/10/11.
//

#import <Foundation/Foundation.h>
typedef NS_ENUM (int, TImageMode)
{
    /**
       * 覆盖前面的
       */
      OVERWRITE = 0,
      /**
       * 取交集
       */
      OR        = 1,
      /**
       * 取差集
       */
      XOR       = 2
};
NS_ASSUME_NONNULL_BEGIN

@interface TSPLImageMode : NSObject
@property (nonatomic , readonly) TSPLImageMode *(^mode)(TImageMode imagemode);
-(int)getMode;
@end

NS_ASSUME_NONNULL_END
