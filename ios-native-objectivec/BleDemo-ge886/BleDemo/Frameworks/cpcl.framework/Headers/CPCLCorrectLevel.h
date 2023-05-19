//
//  CorrectLevel.h
//  CPCL
//
//  Created by IPRT on 2022/10/7.
//

#import <Foundation/Foundation.h>
typedef  NSString * CCorrectLevel NS_STRING_ENUM ;
extern CCorrectLevel const _Nonnull L;
extern CCorrectLevel const _Nonnull M;
extern CCorrectLevel const _Nonnull Q;
extern CCorrectLevel const _Nonnull H;
NS_ASSUME_NONNULL_BEGIN

@interface CPCLCorrectLevel : NSObject
@property(nonatomic , assign)CCorrectLevel level;
-(NSString *)getLevel;
@end

NS_ASSUME_NONNULL_END
