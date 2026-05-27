package com.printer.psdk.examples.emapi;

import java.io.ByteArrayOutputStream;
import java.io.IOException;

final class EscCommandBuilder {
    private EscCommandBuilder() {
    }

    static byte[] buildImagePrint(byte[] imageBytes, EscPrintOptions options) {
        byte[] image = imageBytes == null || imageBytes.length == 0
            ? new byte[]{0x45, 0x4d, 0x41, 0x50, 0x49}
            : imageBytes;
        EscPrintOptions actual = options == null ? new EscPrintOptions() : options;
        ByteArrayOutputStream out = new ByteArrayOutputStream();
        try {
            out.write(new byte[]{0x1b, 0x40});
            out.write(new byte[]{0x1f, 0x11, (byte) actual.paperType});
            out.write(new byte[]{0x1f, 0x12, (byte) actual.printMode});
            out.write(new byte[]{0x1f, 0x13, (byte) actual.thickness});
            out.write(new byte[]{0x1f, 0x14, (byte) (actual.compress ? 1 : 0)});
            out.write(image);
            out.write(new byte[]{0x0c, 0x1b, 0x4a, 0x00});
            return out.toByteArray();
        } catch (IOException e) {
            throw new IllegalStateException("Failed to build ESC bytes", e);
        }
    }
}
