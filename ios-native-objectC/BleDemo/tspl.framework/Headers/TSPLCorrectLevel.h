//
//  CorrectLevel.h
//  CPCL
//
//  Created by IPRT on 2022/10/7.
//

#import <Foundation/Foundation.h>
typedef  NSString * TCorrectLevel NS_STRING_ENUM ;
extern TCorrectLevel const _Nonnull L;
extern TCorrectLevel const _Nonnull M;
extern TCorrectLevel const _Nonnull Q;
extern TCorrectLevel const _Nonnull H;
NS_ASSUME_NONNULL_BEGIN

@interface TSPLCorrectLevel : NSObject
@property(nonatomic , assign)TCorrectLevel level;
-(NSString *)getLevel;
@end

NS_ASSUME_NONNULL_END
