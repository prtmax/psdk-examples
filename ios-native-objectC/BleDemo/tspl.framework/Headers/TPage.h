//
//  TPage.h
//  TSPL
//
//  Created by IPRT on 2022/10/12.
//
#import <tspl/BasicTSPLArg.h>
NS_ASSUME_NONNULL_BEGIN

@interface TPage : BasicTSPLArg

@property (nonatomic , readonly) TPage *(^width)(int lineWidth);

@property (nonatomic , readonly) TPage *(^height)(int lineHeight);
@end

NS_ASSUME_NONNULL_END
