//
//  Appendat.h
//  Father
//
//  Created by IPRT on 2022/9/22.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface Appendat<T> : NSObject
@property (nonatomic , strong) T argument_;
@property (nonatomic , assign) BOOL condition_;
@property (nonatomic , copy) T (^callback)(id _Nullable object);
@property (nonatomic , strong) T callBack;
@property (nonatomic , readonly) Appendat *(^callBackfunc)(id func);
-(id)argument;
-(BOOL)condition;
-(instancetype)initWithArgument:(T)argument andCondition:(BOOL)condition andCallback:(T(^)(id _Nullable object))callback;
@end

@interface TextAppendat : Appendat<NSString *>
-(NSString *)quote;
-(instancetype)createWithArgument:(NSString *)argument;
-(instancetype)createWithArgument:(NSString *)argument andCondition:(BOOL)condition;
@end
NS_ASSUME_NONNULL_END
