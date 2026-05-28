package com.printer.psdk.examples.emapi;

final class EscPrintOptions {
    static final int PAPER_CONTINUOUS = 0;
    static final int PAPER_GAP = 1;
    static final int PAPER_BLACK_MARK = 2;
    static final int MODE_NORMAL = 0;
    static final int MODE_DOUBLE = 1;
    static final int MODE_GRAY = 2;

    int paperType = PAPER_CONTINUOUS;
    int printMode = MODE_NORMAL;
    int thickness = 8;
    boolean compress = true;
    boolean includePosition = false;
}
