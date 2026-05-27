package com.printer.psdk.examples.emapi;

final class Hex {
    private static final char[] TABLE = "0123456789ABCDEF".toCharArray();

    private Hex() {
    }

    static String bytes(byte[] data) {
        if (data == null || data.length == 0) {
            return "";
        }
        StringBuilder builder = new StringBuilder(data.length * 3);
        for (int i = 0; i < data.length; i++) {
            if (i > 0) {
                builder.append(' ');
            }
            int value = data[i] & 0xff;
            builder.append(TABLE[value >>> 4]).append(TABLE[value & 0x0f]);
        }
        return builder.toString();
    }

    static String command(byte[] data) {
        String hex = bytes(data);
        return hex.length() == 0 ? "无字节数据" : hex;
    }
}
