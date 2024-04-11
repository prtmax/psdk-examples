//
//  TTypes.m
//  AYSDK
//
//  Created by aiyin on 2023/9/14.
//


typedef NS_ENUM(NSInteger, CFont) {
    TSS16 = 1,          // 16点阵
    TSS20,          // 20点阵
    TSS20_MAX1,     // 20点阵放大一倍
    TSS24,          // 24点阵
    TSS28,          // 28点阵
    TSS32,         // 32点阵
    TSS24_MAX1,     // 24点阵放大一倍
    TSS28_MAX1,     // 28点阵放大一倍
    TSS32_MAX1,     // 32点阵放大一倍
    TSS24_MAX2,     // 24点阵放大两倍
    TSS28_MAX2,     // 28点阵放大两倍
    TSS32_MAX2,     // 32点阵放大两倍
};

typedef NS_ENUM(NSInteger, CRotation) {
    CRotation_0,
    CRotation_90,
    CRotation_180,
    CRotation_270
};

typedef NS_ENUM(NSInteger, CBarcodeDirection) {
    CBarcodeDirection_H,  // horizontal
    CBarcodeDirection_V,  // vertical
};


typedef NS_ENUM(NSInteger, CCodeType) {
    CCodeType_39,
    CCodeType_128,
    CCodeType_93,
    CCodeType_CODABAR,
    CCodeType_EAN8,
    CCodeType_EAN13,
    CCodeType_UPCA,
    CCodeType_UPCE,
    CCodeType_I2OF5,
};
