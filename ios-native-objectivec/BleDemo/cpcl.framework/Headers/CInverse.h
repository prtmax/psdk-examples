//
//  CInverse.h
//  CPCL
//
//  Created by IPRT on 2022/10/10.
//

#import "BasicCPCLArg.h"
#import "CPCLFont.h"
#import "CPCLRotation.h"
NS_ASSUME_NONNULL_BEGIN

@interface CInverse : BasicCPCLArg
@property (nonatomic, readonly) CInverse *(^x)(int X);
@property (nonatomic, readonly) CInverse *(^y)(int Y);
@property (nonatomic, readonly) CInverse *(^Fnt)(CFont font);
@property (nonatomic, readonly) CInverse *(^content)(id conten);
@property (nonatomic, readonly) CInverse *(^rotation)(CRotation InRotation);
@end

NS_ASSUME_NONNULL_END
