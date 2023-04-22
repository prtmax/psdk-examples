//
//  CPage.h
//  CPCL
//
//  Created by IPRT on 2022/10/10.
//

#import "BasicCPCLArg.h"

NS_ASSUME_NONNULL_BEGIN
/**
 * 设置打印纸张大小（打印区域）的大小
 */
@interface CPage : BasicCPCLArg

/// 打印区域高度(单位dot)
@property(nonatomic, readonly) CPage *(^height)(int cHeight);
/// 打印区域宽度(单位dot)
@property(nonatomic, readonly) CPage *(^width)(int cWidth);
/// 打印份数(默认一份)
@property(nonatomic, readonly) CPage *(^num)(int cNum);

@end

NS_ASSUME_NONNULL_END
