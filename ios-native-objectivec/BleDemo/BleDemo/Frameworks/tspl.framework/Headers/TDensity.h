//
//  TDensity.h
//  TSPL
//
//  Created by IPRT on 2022/10/12.
//

#import <tspl/BasicTSPLArg.h>
NS_ASSUME_NONNULL_BEGIN

/**
 * 设置浓度
 */
@interface TDensity : BasicTSPLArg

/// 浓度值 （0~15）
@property (nonatomic , readonly) TDensity *(^density)(int dens);

@end

NS_ASSUME_NONNULL_END
