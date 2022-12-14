//
//  TLine.h
//  TSPL
//
//  Created by IPRT on 2022/10/12.
//

#import <tspl/BasicTSPLArg.h>
#import "TSPLLineMode.h"
NS_ASSUME_NONNULL_BEGIN

@interface TLine : BasicTSPLArg
@property (nonatomic , readonly) TLine *(^start_x)(int startx);
@property (nonatomic , readonly) TLine *(^start_y)(int starty);
@property (nonatomic , readonly) TLine *(^end_x)(int endx);
@property (nonatomic , readonly) TLine *(^end_y)(int endy);
@property (nonatomic , readonly) TLine *(^width)(int lineWidth);
@property (nonatomic , readonly) TLine *(^height)(int lineHeight);
@property (nonatomic , readonly) TLine *(^lineMode)(TLineMode l);
@end

NS_ASSUME_NONNULL_END
