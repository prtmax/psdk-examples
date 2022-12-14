//
//  WroteReporter.h
//  adapter
//
//  Created by IPRT on 2022/10/24.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface WroteReporter : NSObject
@property (nonatomic , readonly)WroteReporter *(^ok)(BOOL isOk);
@property (nonatomic , readonly)WroteReporter *(^binary)(NSData * br);
@property (nonatomic , readonly)WroteReporter *(^exception)(NSException *error);
@property (nonatomic , readonly)WroteReporter *(^controlExit)(BOOL controlExit);
-(BOOL)getIsOk;
-(NSData *)getBinary;
-(NSException *)getException;
-(BOOL)getIsControlExit;
@end

NS_ASSUME_NONNULL_END
