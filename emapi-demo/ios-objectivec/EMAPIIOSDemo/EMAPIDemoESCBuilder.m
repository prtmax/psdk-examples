#import "EMAPIDemoESCBuilder.h"

#if __has_include(<esc/ESC_.h>)
#import <esc/ESC_.h>
#import <esc/EImage.h>
#import <esc/EPaperType.h>
#endif

@implementation EMAPIDemoESCBuilder

+ (NSData *)escDataForImage:(UIImage *)image
                  paperType:(EMAPIDemoEscPaperType)paperType
                  printMode:(NSInteger)printMode
                  thickness:(NSInteger)thickness
                   compress:(BOOL)compress
                      error:(NSError **)error
{
    if (image == nil) {
        if (error) {
            *error = [NSError errorWithDomain:@"EMAPIDemoESCBuilder" code:1 userInfo:@{NSLocalizedDescriptionKey: @"请选择 ESC 打印图片"}];
        }
        return nil;
    }

#if __has_include(<esc/ESC_.h>)
    EImage *imageArg = [[EImage alloc] init];
    imageArg.image(image).mode((Mode)printMode).compress(compress);

    NSMutableData *data = [NSMutableData data];
    const uint8_t wakeup[] = {0x1B, 0x40};
    const uint8_t enable[] = {0x1B, 0x64, 0x01};
    const uint8_t mode[] = {0x1B, 0x21, (uint8_t)printMode};
    const uint8_t density[] = {0x1D, 0x7C, (uint8_t)MAX(0, MIN(15, thickness))};
    [data appendBytes:wakeup length:sizeof(wakeup)];
    [data appendBytes:enable length:sizeof(enable)];
    [data appendBytes:mode length:sizeof(mode)];
    [data appendBytes:density length:sizeof(density)];

    NSData *png = UIImagePNGRepresentation(image);
    if (png.length > 0) {
        [data appendData:png];
    }
    if (paperType != EMAPIDemoEscPaperTypeContinuous) {
        const uint8_t position[] = {0x1D, 0x0C};
        [data appendBytes:position length:sizeof(position)];
    }
    const uint8_t stop[] = {0x1D, 0x56, 0x00};
    [data appendBytes:stop length:sizeof(stop)];
    return data;
#else
    NSMutableData *data = [NSMutableData data];
    const uint8_t wakeup[] = {0x1B, 0x40};
    const uint8_t mode[] = {0x1B, 0x21, (uint8_t)printMode};
    const uint8_t density[] = {0x1D, 0x7C, (uint8_t)MAX(0, MIN(15, thickness))};
    [data appendBytes:wakeup length:sizeof(wakeup)];
    [data appendBytes:mode length:sizeof(mode)];
    [data appendBytes:density length:sizeof(density)];
    NSData *png = UIImagePNGRepresentation(image);
    if (png.length > 0) {
        [data appendData:png];
    }
    if (paperType != EMAPIDemoEscPaperTypeContinuous) {
        const uint8_t position[] = {0x1D, 0x0C};
        [data appendBytes:position length:sizeof(position)];
    }
    const uint8_t stop[] = {0x1D, 0x56, 0x00};
    [data appendBytes:stop length:sizeof(stop)];
    return data;
#endif
}

@end
