package com.printer.demo.entity;

import com.printer.sdk.operate.SetOp;

public class InfoItem {
    public static class Title extends InfoItem {
        public final String title;
        public final SetOp setOp1;
        public final SetOp setOp2;

        public Title(String title) {
            this.title = title;
            this.setOp1 = null;
            this.setOp2 = null;
        }

        public Title(String title, SetOp setOp) {
            this.title = title;
            this.setOp1 = setOp;
            this.setOp2 = null;
        }

        public Title(String title, SetOp setOp1, SetOp setOp2) {
            this.title = title;
            this.setOp1 = setOp1;
            this.setOp2 = setOp2;
        }
    }

    public static class Property extends InfoItem {
        public final String name;
        public String value;
        public final String minValue;
        public final String maxValue;
        public final Class<?> propertyType;
        public final boolean writable;
        public final String suffix;
        public String[] items;
        public int index;

        public Property(String name, String value) {
            this(name, value, null);
        }

        public Property(String name, String value, String suffix) {
            this.name = name;
            this.value = value;
            this.minValue = null;
            this.maxValue = null;
            this.propertyType = null;
            this.writable = false;
            this.suffix = suffix;
        }

        public Property(String name, String value, String minValue, String maxValue, Class<?> propertyType, boolean writable) {
            this(name, value, null, minValue, maxValue, propertyType, writable);
        }

        public Property(String name, String value, String suffix, String minValue, String maxValue, Class<?> propertyType, boolean writable) {
            this.name = name;
            this.value = value;
            this.minValue = minValue;
            this.maxValue = maxValue;
            this.propertyType = propertyType;
            this.writable = writable;
            this.suffix = suffix;
        }

        public Property(String name, int index, String[] items) {
            this.name = name;
            this.value = null;
            this.minValue = null;
            this.maxValue = null;
            this.propertyType = null;
            this.writable = true;
            this.suffix = null;
            this.items = items;
            this.index = index;
        }
    }
}
