//
//  CBox.h
//  CPCL
//
//  Created by IPRT on 2022/10/10.
//

#import "BasicCPCLArg.h"

NS_ASSUME_NONNULL_BEGIN

@interface CBox : BasicCPCLArg
@property (nonatomic, readonly) CBox *(^width)(int lineWidth);
@property (nonatomic, readonly) CBox *(^topLeftX)(int lineTopLeftX);
@property (nonatomic, readonly) CBox *(^topLeftY)(int lineTopLeftY);
@property (nonatomic, readonly) CBox *(^bottomRightX)(int lineBottomRightX);
@property (nonatomic, readonly) CBox *(^bottomRightY)(int lineBottomRightY);
@end

NS_ASSUME_NONNULL_END
