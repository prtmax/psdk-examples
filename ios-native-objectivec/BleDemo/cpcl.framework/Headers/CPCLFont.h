//
//  Font.h
//  CPCL
//
//  Created by IPRT on 2022/10/7.
//

#import <Foundation/Foundation.h>
typedef  NSString * CFont NS_STRING_ENUM ;
/**
  * 16点阵
  */

extern CFont const _Nonnull TSS16;
/**
  * 20点阵
  */

extern CFont const _Nonnull TSS20;
/**
 *20点阵放大一倍
 */
extern CFont const _Nonnull TSS20_MAX1;
/**
  * 24点阵
  */

extern CFont const _Nonnull TSS24;
/**
  * 28点阵
  */

extern CFont const _Nonnull TSS28;
/**
  * 32点阵
  */

extern CFont const _Nonnull TSS32;
/**
  * 24点阵放大一倍
  */

extern CFont const _Nonnull TSS24_MAX1;
/**
  * 28点阵放大一倍
  */

extern CFont const _Nonnull TSS28_MAX1;
/**
  * 32点阵放大一倍
  */

extern CFont const _Nonnull TSS32_MAX1;

/**
  * 24点阵放大两倍
  */

extern CFont const _Nonnull TSS24_MAX2;
/**
  * 28点阵放大两倍
  */

extern CFont const _Nonnull TSS28_MAX2;
/**
  * 32点阵放大两倍
  */

extern CFont const _Nonnull TSS32_MAX2;


NS_ASSUME_NONNULL_BEGIN

@interface CPCLFont : NSObject
@property(nonatomic , readonly)CPCLFont *(^font)(CFont fnt);
- (int) getEx;
- (int) getEy;
- (int) getFamily;
- (int) getSize;
- (int) getHeight;
@end

NS_ASSUME_NONNULL_END
