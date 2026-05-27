package com.printer.psdk.examples.emapi;

final class LogEntry {
    final String title;
    final String message;
    final byte[] bytes;

    LogEntry(String title, String message) {
        this(title, message, null);
    }

    LogEntry(String title, String message, byte[] bytes) {
        this.title = title;
        this.message = message;
        this.bytes = bytes == null ? null : bytes.clone();
    }
}
