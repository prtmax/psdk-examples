//
//  Line.h
//  TSPL
//
//  Created by IPRT on 2022/10/11.
//

#import <Foundation/Foundation.h>
typedef NS_ENUM (NSInteger, TLineType)
{
    TLineTypeSOLID_LINE     = 0,
    TLineTypeDOTTED_LINE    = 1,
};
NS_ASSUME_NONNULL_BEGIN

@interface TSPLLineType : NSObject
@property(nonatomic , readonly) TSPLLineType *(^lineType)(TLineType l);
-(int) getLine;
@end

NS_ASSUME_NONNULL_END
