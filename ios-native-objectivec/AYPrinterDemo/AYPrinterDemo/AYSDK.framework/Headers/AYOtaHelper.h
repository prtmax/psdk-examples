//
//  AYOTA.h
//  AYSDK
//
//  Created by aiyin on 2023/9/22.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, OtaState) {
    OtaStateStart,
    OtaStateFail,
    OtaStateSuccess,
};

typedef void(^OnOtaProgressChange)(int progress);
typedef void(^OnOtaStateChange)(OtaState state);

NS_ASSUME_NONNULL_BEGIN

@interface AYOtaHelper : NSObject

@property (nonatomic, copy) OnOtaProgressChange progressChange;
@property (nonatomic, copy) OnOtaStateChange otaStateChange;

- (void)otaWithFileData:(NSData *)data startAddress:(long)address;

@end

NS_ASSUME_NONNULL_END
