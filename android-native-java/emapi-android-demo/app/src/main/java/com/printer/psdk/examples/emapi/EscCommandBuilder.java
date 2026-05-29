package com.printer.psdk.examples.emapi;

import android.graphics.Bitmap;
import android.graphics.BitmapFactory;

import com.printer.psdk.device.adapter.ConnectedDevice;
import com.printer.psdk.esc.ESC;
import com.printer.psdk.esc.GenericESC;
import com.printer.psdk.esc.args.EImage;
import com.printer.psdk.esc.args.EPaperType;
import com.printer.psdk.imagep.android.AndroidSourceImage;

final class EscCommandBuilder {
    private EscCommandBuilder() {
    }

    static byte[] buildImagePrint(byte[] imageBytes, EscPrintOptions options) {
        EscPrintOptions actual = options == null ? new EscPrintOptions() : options;

        // 解码图片字节为 Bitmap
        Bitmap bitmap = null;
        if (imageBytes != null && imageBytes.length > 0) {
            bitmap = BitmapFactory.decodeByteArray(imageBytes, 0, imageBytes.length);
        }
        if (bitmap == null) {
            bitmap = Bitmap.createBitmap(1, 1, Bitmap.Config.ARGB_8888);
            bitmap.setPixel(0, 0, 0xff000000);
        }
        AndroidSourceImage sourceImage = AndroidSourceImage.of(bitmap);

        // 映射纸张类型
        EPaperType.Type paperTypeEnum;
        switch (actual.paperType) {
            case EscPrintOptions.PAPER_GAP:
                paperTypeEnum = EPaperType.Type.FOLDED_BLACK_LABEL_PAPER;
                break;
            case EscPrintOptions.PAPER_BLACK_MARK:
                paperTypeEnum = EPaperType.Type.TRANSPARENT_BLACK_LABEL_PAPER;
                break;
            case EscPrintOptions.PAPER_CONTINUOUS:
            default:
                paperTypeEnum = EPaperType.Type.CONTINUOUS_REEL_PAPER;
                break;
        }

        // 使用 GenericESC 构建命令链
        GenericESC esc = ESC.generic(ConnectedDevice.NONE)
            .wakeup()
            .enable()
            .paperType(EPaperType.builder().type(paperTypeEnum).build())
            .enableMode(actual.printMode)
            .thickness(actual.thickness)
            .image(EImage.builder()
                .image(sourceImage)
                .compress(actual.compress)
                .build());

        // 非连续纸时包含定位命令
        if (actual.includePosition && actual.paperType != EscPrintOptions.PAPER_CONTINUOUS) {
            esc.position();
        }

        esc.stopJob();

        return esc.command().binary();
    }
}
