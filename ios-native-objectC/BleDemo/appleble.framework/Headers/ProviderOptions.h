//
//  ProviderOptions.h
//  appleble
//
//  Created by IPRT on 2022/11/30.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ProviderOptions : NSObject
@property(nonatomic , strong) NSArray <NSString *> * allowServices;
@property(nonatomic , strong) NSString * allowCharacteristic;
@property(nonatomic , assign) BOOL allowNoName;
@property(nonatomic , assign) BOOL allowDetectDifferentCharacteristic;
@end

NS_ASSUME_NONNULL_END
