package com.printer.psdk.examples.emapi;

import com.printer.psdk.emapi.EmapiConnection;

import java.io.IOException;
import java.util.ArrayList;
import java.util.List;

final class TracingEmapiConnection implements EmapiConnection {
    static final int OUTBOUND = 1;
    static final int INBOUND = 2;

    static final class Frame {
        final int direction;
        final byte[] data;

        Frame(int direction, byte[] data) {
            this.direction = direction;
            this.data = data == null ? new byte[0] : data.clone();
        }
    }

    private final EmapiConnection inner;
    private final List<Frame> frames = new ArrayList<Frame>();

    TracingEmapiConnection(EmapiConnection inner) {
        this.inner = inner;
    }

    int mark() {
        return frames.size();
    }

    byte[] bytesSince(int mark, int direction) {
        if (mark >= frames.size()) {
            return null;
        }
        int total = 0;
        for (int i = mark; i < frames.size(); i++) {
            Frame frame = frames.get(i);
            if (frame.direction == direction) {
                total += frame.data.length + (total == 0 ? 0 : 2);
            }
        }
        if (total == 0) {
            return null;
        }
        byte[] result = new byte[total];
        int offset = 0;
        for (int i = mark; i < frames.size(); i++) {
            Frame frame = frames.get(i);
            if (frame.direction != direction) {
                continue;
            }
            if (offset > 0) {
                result[offset++] = 0x0d;
                result[offset++] = 0x0a;
            }
            System.arraycopy(frame.data, 0, result, offset, frame.data.length);
            offset += frame.data.length;
        }
        return result;
    }

    @Override
    public void write(byte[] data) throws IOException {
        frames.add(new Frame(OUTBOUND, data));
        inner.write(data);
    }

    @Override
    public byte[] read(int timeoutMs) throws IOException {
        byte[] data = inner.read(timeoutMs);
        frames.add(new Frame(INBOUND, data));
        return data;
    }

    @Override
    public void close() throws IOException {
        inner.close();
    }
}
