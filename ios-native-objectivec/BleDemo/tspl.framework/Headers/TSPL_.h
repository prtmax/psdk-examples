//
//  TSPL_.h
//  tspl
//
//  Created by IPRT on 2022/11/24.
//

#import <Foundation/Foundation.h>
#import "GenericTSPL.h"
NS_ASSUME_NONNULL_BEGIN

@interface TSPL_ : NSObject

@property(nonatomic , readonly) GenericTSPL *(^genericWithConnectedDevice)(ConnectedDevice *connectedDevice);
@property(nonatomic , readonly) GenericTSPL *(^genericWithLifecycle)(Lifecycle *lifecycle);
@end

NS_ASSUME_NONNULL_END
