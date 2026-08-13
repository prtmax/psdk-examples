//
//  AYOtaHelperCPCL.h
//  AYSDK
//
//  Created by aiyin on 8/16/25.
//

#import <Foundation/Foundation.h>
#import <AYSDK/ETypes.h>

typedef void (^OnOtaProgressChange)(int progress);
typedef void (^OnOtaStateChange)(OtaState state);

@interface AYOtaHelperCPCL : NSObject

@property(nonatomic, copy) OnOtaProgressChange progressChange;
@property(nonatomic, copy) OnOtaStateChange otaStateChange;

- (void)otaWithFileData:(NSData *)data;

@end

