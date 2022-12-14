//
//  TReverse.h
//  TSPL
//
//  Created by IPRT on 2022/10/12.
//

#import <tspl/BasicTSPLArg.h>
NS_ASSUME_NONNULL_BEGIN

@interface TReverse : BasicTSPLArg
@property (nonatomic , readonly) TReverse *(^x)(int startX);
@property (nonatomic , readonly) TReverse *(^y)(int startY);
@property (nonatomic , readonly) TReverse *(^height)(int h);
@property (nonatomic , readonly) TReverse *(^width)(int w);

@end

NS_ASSUME_NONNULL_END
