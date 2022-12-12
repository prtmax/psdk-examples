//
//  LineM.h
//  TSPL
//
//  Created by IPRT on 2022/10/11.
//

#import <Foundation/Foundation.h>
typedef  NSString * TLineMode NS_STRING_ENUM ;
/**
   * 实线
   */
extern TLineMode const _Nonnull TLineModeSOLID_LINE;
/**
   * 虚线
   */
extern TLineMode const _Nonnull TLineModeDOTTED_LINE_M1;
/**
   * 虚线
   */
extern TLineMode const _Nonnull TLineModeDOTTED_LINE_M2;
/**
   * 虚线
   */
extern TLineMode const _Nonnull TLineModeDOTTED_LINE_M3;
/**
   * 虚线
   */
extern TLineMode const _Nonnull TLineModeDOTTED_LINE_M4;
NS_ASSUME_NONNULL_BEGIN

@interface TSPLLineMode : NSObject
@property (nonatomic , readonly) TSPLLineMode *(^line)(TLineMode linem);
-(NSString *)getLine;
@end

NS_ASSUME_NONNULL_END
