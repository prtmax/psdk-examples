//
//  TDensity.h
//  TSPL
//
//  Created by IPRT on 2022/10/12.
//

#import <tspl/BasicTSPLArg.h>
NS_ASSUME_NONNULL_BEGIN

@interface TDensity : BasicTSPLArg
@property (nonatomic , readonly) TDensity *(^density)(int dens);//浓度

@end

NS_ASSUME_NONNULL_END
