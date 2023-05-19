//
//  CodeType.h
//  TSPL
//
//  Created by IPRT on 2022/10/11.
//

#import <Foundation/Foundation.h>
typedef  NSString * TCodeType NS_STRING_ENUM ;
/**
  * 39
  */
extern TCodeType const _Nonnull CODE_39;
/**
   * 128
   */
extern TCodeType const _Nonnull CODE_128;
/**
  * 93
  */
extern TCodeType const _Nonnull CODE_93;
/**
   * ITF
   */
extern TCodeType const _Nonnull CODE_ITF;
/**
   * UPCA
   */
extern TCodeType const _Nonnull CODE_UPCA;
/**
   * UPCE
   */
extern TCodeType const _Nonnull CODE_UPCE;
/**
 * CODABAR
 */
extern TCodeType const _Nonnull CODE_CODABAR;
/**
   * EAN8
   */
extern TCodeType const _Nonnull CODE_EAN8;
/**
   * EAN13
   */
extern TCodeType const _Nonnull CODE_EAN13;
NS_ASSUME_NONNULL_BEGIN

@interface TSPLCodeType : NSObject
@property (nonatomic , readonly) TSPLCodeType *(^codeType)(TCodeType type);
-(NSString *)getCodeType;
@end

NS_ASSUME_NONNULL_END
