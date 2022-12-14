//
//  CPageHeight.h
//  CPCL
//
//  Created by IPRT on 2022/10/10.
//

#import "BasicCPCLArg.h"

NS_ASSUME_NONNULL_BEGIN

@interface CPageHeight : BasicCPCLArg
@property (nonatomic , readonly) CPageHeight *(^pageHeight)(int cPageHeight);
@property (nonatomic , readonly) CPageHeight *(^num)(int cNum);
@end

NS_ASSUME_NONNULL_END
