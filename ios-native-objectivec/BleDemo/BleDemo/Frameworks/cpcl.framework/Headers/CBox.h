//
//  CBox.h
//  CPCL
//
//  Created by IPRT on 2022/10/10.
//

#import "BasicCPCLArg.h"

NS_ASSUME_NONNULL_BEGIN

/**
 * 打印边框
 */
@interface CBox : BasicCPCLArg

/// 边框线条宽度
@property (nonatomic, readonly) CBox *(^width)(int lineWidth);
/// 矩形框左上角x坐标
@property (nonatomic, readonly) CBox *(^topLeftX)(int lineTopLeftX);
/// 矩形框左上角y坐标
@property (nonatomic, readonly) CBox *(^topLeftY)(int lineTopLeftY);
/// 矩形框右下角x坐标
@property (nonatomic, readonly) CBox *(^bottomRightX)(int lineBottomRightX);
/// 矩形框右下角y坐标
@property (nonatomic, readonly) CBox *(^bottomRightY)(int lineBottomRightY);

@end

NS_ASSUME_NONNULL_END
