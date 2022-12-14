//
//  CBar.h
//  CPCL
//
//  Created by IPRT on 2022/10/7.
//

#import "BasicCPCLArg.h"
#import "CPCLCodeType.h"
#import "CPCLCodeRotation.h"
NS_ASSUME_NONNULL_BEGIN

@interface CBar : BasicCPCLArg
@property (nonatomic , readonly) CBar *(^x)(int startX);
@property (nonatomic , readonly) CBar *(^y)(int startY);
@property (nonatomic , readonly) CBar *(^content)(NSString *cnt);
@property (nonatomic , readonly) CBar *(^lineWidth)(int width);
@property (nonatomic , readonly) CBar *(^height)(int lineHeight);
@property (nonatomic , readonly) CBar *(^codeType)(CCodeType ct);
@property (nonatomic , readonly) CBar *(^codeRotation)(CCodeRotation cr);
@end

NS_ASSUME_NONNULL_END
