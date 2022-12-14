//
//  CUnderLine.h
//  CPCL
//
//  Created by IPRT on 2022/10/10.
//

#import "BasicCPCLArg.h"

NS_ASSUME_NONNULL_BEGIN

@interface CUnderLine : BasicCPCLArg
@property(nonatomic , readonly) CUnderLine *(^underline)(BOOL isUnderline);
@end

NS_ASSUME_NONNULL_END
