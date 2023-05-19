//
//  Rotation.h
//  CPCL
//
//  Created by IPRT on 2022/10/7.
//

#import <Foundation/Foundation.h>
typedef NS_ENUM (NSInteger, TRotation)
{
    /**
       * 旋转0度
       */
    ROTATION_0         = 0,
    /**
       * 旋转90度
       */
    ROTATION_90        = 90,
    /**
       * 旋转180度
       */
    ROTATION_180       = 180,
    /**
      * 旋转270度
      */
    ROTATION_270       = 270
};

NS_ASSUME_NONNULL_BEGIN

@interface TSPLRotation : NSObject
@property(nonatomic , readonly) TSPLRotation *(^rotation)(TRotation rot);
-(int)getRotation;
@end

NS_ASSUME_NONNULL_END
