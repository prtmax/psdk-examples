#import "EMAPIDemoESCBuilder.h"

#if __has_include(<esc/ESC_.h>)
#import <esc/ESC_.h>
#import <esc/EImage.h>
#import <esc/EPaperType.h>
#import <father/Command.h>
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

    GenericESC *command = [[GenericESC alloc] init];
    Lifecycle *lifecycle = [[Lifecycle alloc] init];
    command.BasicESC(lifecycle, ESCPrinter_GENERIC)
        .wakeup()
        .enable()
        .paperType([self sdkPaperTypeForPaperType:paperType])
        .thickness((int)MAX(0, MIN(15, thickness)))
        .image(imageArg);
    if (paperType != EMAPIDemoEscPaperTypeContinuous) {
        command.position();
    }
    command.stopJob();
    return [command.command binary];
#else
    NSMutableData *data = [NSMutableData data];
    const uint8_t wakeup[1024] = {};
    const uint8_t enable[] = {0x10, 0xFF, 0xFE, 0x01};
    const uint8_t paper[] = {0x10, 0xFF, 0x10, 0x03, (uint8_t)[self fallbackPaperTypeForPaperType:paperType]};
    const uint8_t mode[] = {0x1D, 0x76, 0x30, (uint8_t)printMode};
    const uint8_t density[] = {0x10, 0xFF, 0x10, 0x00, (uint8_t)MAX(0, MIN(15, thickness))};
    [data appendBytes:wakeup length:sizeof(wakeup)];
    [data appendBytes:enable length:sizeof(enable)];
    [data appendBytes:paper length:sizeof(paper)];
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
    const uint8_t stop[] = {0x10, 0xFF, 0xFE, 0x45};
    [data appendBytes:stop length:sizeof(stop)];
    return data;
#endif
}

#if __has_include(<esc/ESC_.h>)
+ (PaperType)sdkPaperTypeForPaperType:(EMAPIDemoEscPaperType)paperType
{
    switch (paperType) {
        case EMAPIDemoEscPaperTypeContinuous:
            return paperTypeTwo;
        case EMAPIDemoEscPaperTypeGap:
            return paperTypeThree;
        case EMAPIDemoEscPaperTypeBlackMark:
            return paperTypeOne;
    }
}
#endif

+ (NSInteger)fallbackPaperTypeForPaperType:(EMAPIDemoEscPaperType)paperType
{
    switch (paperType) {
        case EMAPIDemoEscPaperTypeContinuous:
            return 1;
        case EMAPIDemoEscPaperTypeGap:
            return 2;
        case EMAPIDemoEscPaperTypeBlackMark:
            return 0;
    }
}

@end
