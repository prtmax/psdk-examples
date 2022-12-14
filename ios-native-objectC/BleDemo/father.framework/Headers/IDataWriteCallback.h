//
//  IDataWriteCallback.h
//  Father
//
//  Created by IPRT on 2022/10/25.
//

#import <Foundation/Foundation.h>
#import<father/WriteControl.h>
#import <father/CallbackData.h>
NS_ASSUME_NONNULL_BEGIN
typedef void (^successHandler)(DataWrite *datawrite);
typedef void (^failedHandler)(DataWrite *datawrite,NSException *error);
@interface IDataWriteCallback : NSObject
@property(nonatomic , readonly)WriteControl (^success)(CallbackData * data);
@property(nonatomic , readonly)void (^failed)(CallbackData *data,NSException *exception);
-(void)failed:(failedHandler)failed;
@end

NS_ASSUME_NONNULL_END
