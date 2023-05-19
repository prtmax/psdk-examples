//
//  HexOutput.h
//  Father
//
//  Created by aiyin on 2022/4/11.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface HexOutput : NSObject
- (NSString *)format:(NSData *)bytes;
@property(nonatomic , readonly)HexOutput *(^enableFormat)(BOOL isEnableFormat);
@property(nonatomic , readonly)HexOutput *(^enableSpacing)(BOOL isEnableSpacing);
@property(nonatomic , readonly)HexOutput *(^maxLengthOfLine)(int lengthOfLine);
@end

NS_ASSUME_NONNULL_END
