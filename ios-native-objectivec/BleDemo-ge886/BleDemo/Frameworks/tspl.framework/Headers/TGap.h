//
//  TGap.h
//  TSPL
//
//  Created by IPRT on 2022/10/12.
//

#import <tspl/BasicTSPLArg.h>
NS_ASSUME_NONNULL_BEGIN

/**
 * 打印完毕定位到缝隙
 */
@interface TGap : BasicTSPLArg

/// 是否定位但缝隙, true：定位到缝隙；false：不定位
@property (nonatomic , readonly) TGap *(^enable)(BOOL isEnable);

@end

NS_ASSUME_NONNULL_END
