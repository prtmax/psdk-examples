#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, EMAPIDemoEscPaperType) {
    EMAPIDemoEscPaperTypeContinuous = 0,
    EMAPIDemoEscPaperTypeGap = 1,
    EMAPIDemoEscPaperTypeBlackMark = 2,
};

@interface EMAPIDemoESCBuilder : NSObject

+ (NSData *)escDataForImage:(UIImage *)image
                  paperType:(EMAPIDemoEscPaperType)paperType
                  printMode:(NSInteger)printMode
                  thickness:(NSInteger)thickness
                   compress:(BOOL)compress
                      error:(NSError **)error;

@end
