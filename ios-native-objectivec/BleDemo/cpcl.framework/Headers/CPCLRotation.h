//
//  Rotation.h
//  CPCL
//
//  Created by IPRT on 2022/10/7.
//

#import <Foundation/Foundation.h>
typedef NS_ENUM (NSInteger, CRotation)
{
    /**
       * 旋转0度
       */
    CRotation_0         = 0,
    /**
       * 旋转90度
       */
    CRotation_90        = 90,
    /**
       * 旋转180度
       */
    CRotation_180       = 180,
    /**
      * 旋转270度
      */
    CRotation_270       = 270
};

NS_ASSUME_NONNULL_BEGIN

@interface CPCLRotation : NSObject
@property(nonatomic , readonly) CPCLRotation *(^rotation)(CRotation rot);
-(NSString *)getRotation;
@end

NS_ASSUME_NONNULL_END
