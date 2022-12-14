//
//  CQRCode.h
//  CPCL
//
//  Created by IPRT on 2022/10/10.
//

#import "BasicCPCLArg.h"
#import "CPCLCodeRotation.h"
#import "CPCLCorrectLevel.h"
NS_ASSUME_NONNULL_BEGIN

@interface CQRCode : BasicCPCLArg
@property (nonatomic , readonly) CQRCode *(^x)(int cx);
@property (nonatomic , readonly) CQRCode *(^y)(int cy);
@property (nonatomic , readonly) CQRCode *(^content)(id ccontent);
@property (nonatomic , readonly) CQRCode *(^codeRotation)(CCodeRotation ccodeRotation);
@property (nonatomic , readonly) CQRCode *(^width)(int cWidth);
@property (nonatomic , readonly) CQRCode *(^level)(CCorrectLevel cLevel);
@end

NS_ASSUME_NONNULL_END
