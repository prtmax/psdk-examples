//
//  TDownloadBmpFlash.h
//  TSPL
//
//  Created by IPRT on 2022/10/12.
//

#import <tspl/BasicTSPLArg.h>
NS_ASSUME_NONNULL_BEGIN

@interface TDownloadBmpFlash : BasicTSPLArg
@property (nonatomic , readonly) TDownloadBmpFlash *(^index)(int ind);
@property (nonatomic , readonly) TDownloadBmpFlash *(^data)(NSData *dat);
@end

NS_ASSUME_NONNULL_END
