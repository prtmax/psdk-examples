//
//  AppleBle.h
//  appleble
//
//  Created by aiyin on 2023/4/17.
//

#import <adapter/adapter.h>

@protocol AppleBleDelegate <NSObject>

@optional


@end

NS_ASSUME_NONNULL_BEGIN

@interface AppleBle : ConnectedDevice

//@property (nonatomic, weak, nullable) id <AppleBleDelegate> delegate;

@end

NS_ASSUME_NONNULL_END
