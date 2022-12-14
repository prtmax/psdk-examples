//
//  TQRCode.h
//  TSPL
//
//  Created by IPRT on 2022/10/12.
//

#import <tspl/BasicTSPLArg.h>
#import "TSPLCorrectLevel.h"
#import "TSPLRotation.h"
NS_ASSUME_NONNULL_BEGIN

@interface TQRCode : BasicTSPLArg
@property (nonatomic , readonly) TQRCode *(^x)(int startX);
@property (nonatomic , readonly) TQRCode *(^y)(int startY);
@property (nonatomic , readonly) TQRCode *(^cellWidth)(int cWidth);
@property (nonatomic , readonly) TQRCode *(^correctLevel)(TCorrectLevel clevel);
@property (nonatomic , readonly) TQRCode *(^rotation)(TRotation rot);
@property (nonatomic , readonly) TQRCode *(^content)(NSString * cnt);
@property (nonatomic , readonly) TQRCode *(^version)(NSString * vsion);
@end

NS_ASSUME_NONNULL_END
