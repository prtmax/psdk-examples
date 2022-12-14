//
//  TPrint.h
//  TSPL
//
//  Created by IPRT on 2022/10/12.
//
#import <tspl/BasicTSPLArg.h>
NS_ASSUME_NONNULL_BEGIN

@interface TPrint : BasicTSPLArg
@property (nonatomic , readonly) TPrint *(^copies)(int copyCount);
@end

NS_ASSUME_NONNULL_END
