package com.printer.demo.task;

import com.printer.sdk.Printer;

/**
 * Network printer whose spinner text includes the UDP device name.
 * {@link Printer.NetworkPrinter#getDescription()} is only {@code tcp:ip:port}.
 */
final class NamedNetworkPrinter extends Printer.NetworkPrinter {
    private final String displayName;

    NamedNetworkPrinter(String displayName, String ip, String port) {
        super(ip, port);
        this.displayName = displayName;
    }

    @Override
    protected String getDescription() {
        if (displayName == null || displayName.trim().isEmpty()) {
            return super.getDescription();
        }
        return displayName;
    }
}
