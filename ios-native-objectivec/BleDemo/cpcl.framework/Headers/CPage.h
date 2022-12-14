//
//  CPage.h
//  CPCL
//
//  Created by IPRT on 2022/10/10.
//

#import "BasicCPCLArg.h"

NS_ASSUME_NONNULL_BEGIN

@interface CPage : BasicCPCLArg
@property(nonatomic, readonly) CPage *(^height)(int cHeight);
@property(nonatomic, readonly) CPage *(^width)(int cWidth);
@property(nonatomic, readonly) CPage *(^num)(int cNum);

@end

NS_ASSUME_NONNULL_END
