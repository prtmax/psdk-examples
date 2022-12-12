//
//  CodeRotation.h
//  CPCL
//
//  Created by IPRT on 2022/10/7.
//

#import <Foundation/Foundation.h>
typedef  NSString * CCodeRotation NS_STRING_ENUM ;
extern CCodeRotation const _Nonnull CCODEROTATION_0;
extern CCodeRotation const _Nonnull CCODEROTATION_90;
NS_ASSUME_NONNULL_BEGIN

@interface CPCLCodeRotation : NSObject
@property (nonatomic , assign)CCodeRotation rotation;
-(NSString *)getRotation;
@end

NS_ASSUME_NONNULL_END
