//
//  CPageHeight.h
//  CPCL
//
//  Created by IPRT on 2022/10/10.
//

#import "BasicCPCLArg.h"

NS_ASSUME_NONNULL_BEGIN
/**
 * 设置打印纸张高度（打印区域）的高度
 */
@interface CPageHeight : BasicCPCLArg

/// 打印区域高度
@property (nonatomic , readonly) CPageHeight *(^pageHeight)(int cPageHeight);
/// 打印份数(默认一份)
@property (nonatomic , readonly) CPageHeight *(^num)(int cNum);

@end

NS_ASSUME_NONNULL_END
