//
//  ThicknessArg.h
//  ESC
//
//  Created by aiyin on 2022/4/14.
//

#import "BasicESCArg.h"

typedef enum : NSUInteger {
    thickness_L = 0,    // 0:低浓度
    thickness_M,        // 1:中浓度
    thickness_H,        //2:高浓度
} Thickness;

NS_ASSUME_NONNULL_BEGIN

@interface EThickness : BasicESCArg
@property (nonatomic , readonly) EThickness *(^thickness)(Thickness thick);


@end

NS_ASSUME_NONNULL_END
