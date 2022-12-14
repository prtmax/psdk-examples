//
//  CodeType.h
//  CPCL
//
//  Created by IPRT on 2022/10/7.
//

#import <Foundation/Foundation.h>
typedef  NSString * CCodeType NS_STRING_ENUM ;
extern CCodeType const _Nonnull CODE39;
extern CCodeType const _Nonnull CODE128;
extern CCodeType const _Nonnull CODE93;
extern CCodeType const _Nonnull CODABAR;
extern CCodeType const _Nonnull EAN8;
extern CCodeType const _Nonnull EAN13;
extern CCodeType const _Nonnull UPCA;
extern CCodeType const _Nonnull UPCE;
extern CCodeType const _Nonnull I20F5;
NS_ASSUME_NONNULL_BEGIN

@interface CPCLCodeType : NSObject
@property (nonatomic , assign)CCodeType codetype;
-(NSString *)getType;
-(int)getWidth;
@end

NS_ASSUME_NONNULL_END
