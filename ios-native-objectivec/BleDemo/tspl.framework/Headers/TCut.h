//
//  TCut.h
//  TSPL
//
//  Created by IPRT on 2022/10/12.
//

#import <tspl/BasicTSPLArg.h>
NS_ASSUME_NONNULL_BEGIN

@interface TCut : BasicTSPLArg
@property (nonatomic , readonly) TCut *(^enable)(BOOL isEnable);
@end

NS_ASSUME_NONNULL_END
