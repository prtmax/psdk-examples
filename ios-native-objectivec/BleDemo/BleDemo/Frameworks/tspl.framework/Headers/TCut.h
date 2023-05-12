//
//  TCut.h
//  TSPL
//
//  Created by IPRT on 2022/10/12.
//

#import <tspl/BasicTSPLArg.h>
NS_ASSUME_NONNULL_BEGIN

/**
 * 使能切刀
 */
@interface TCut : BasicTSPLArg

/// 是否使能切刀(默认否)
@property (nonatomic , readonly) TCut *(^enable)(BOOL isEnable);

@end

NS_ASSUME_NONNULL_END
