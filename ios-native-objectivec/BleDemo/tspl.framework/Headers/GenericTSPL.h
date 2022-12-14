//
//  GenericTSPL.h
//  tspl
//
//  Created by IPRT on 2022/11/24.
//

#import <tspl/tspl.h>

NS_ASSUME_NONNULL_BEGIN

@interface GenericTSPL : BasicTSPL
@property(nonatomic , readonly) GenericTSPL *(^GenericTSPL)(Lifecycle *lifecycle);
@end

NS_ASSUME_NONNULL_END
