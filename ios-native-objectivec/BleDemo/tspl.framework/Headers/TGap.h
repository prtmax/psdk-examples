//
//  TGap.h
//  TSPL
//
//  Created by IPRT on 2022/10/12.
//

#import <tspl/BasicTSPLArg.h>
NS_ASSUME_NONNULL_BEGIN

@interface TGap : BasicTSPLArg
@property (nonatomic , readonly) TGap *(^enable)(BOOL isEnable);
@end

NS_ASSUME_NONNULL_END
