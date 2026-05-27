package com.printer.psdk.examples.emapi;

final class DeviceModel {
    final String name;
    final String address;
    final String protocol;
    final boolean simulated;

    DeviceModel(String name, String address, String protocol, boolean simulated) {
        this.name = name == null || name.length() == 0 ? "EMAPI Printer" : name;
        this.address = address == null ? "" : address;
        this.protocol = protocol == null ? "Bluetooth" : protocol;
        this.simulated = simulated;
    }
}
