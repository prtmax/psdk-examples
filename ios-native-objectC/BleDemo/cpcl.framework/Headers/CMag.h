//
//  CMag.h
//  CPCL
//
//  Created by IPRT on 2022/10/10.
//

#import "BasicCPCLArg.h"
#import "CPCLFont.h"
NS_ASSUME_NONNULL_BEGIN

@interface CMag : BasicCPCLArg
@property (nonatomic , readonly) CMag *(^font)(CFont fnt);
@end

NS_ASSUME_NONNULL_END
