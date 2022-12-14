//
//  TCleanBmpFlash.h
//  TSPL
//
//  Created by IPRT on 2022/10/12.
//

#import <tspl/BasicTSPLArg.h>
NS_ASSUME_NONNULL_BEGIN

@interface TCleanBmpFlash : BasicTSPLArg
@property (nonatomic , readonly) TCleanBmpFlash *(^index)(int ind);
@end

NS_ASSUME_NONNULL_END
