const std = @import("std");
const crypto = std.crypto;
const dh = crypto.dh;
const net = std.net;

const magic: u32 = 0xdeadbaba;

pub const Header = extern struct {
    magic: u32 = magic,
    public_key: [32]u8,
};

pub const FrameType = enum(u8) { data, close };

pub const Frame = extern struct {
    frame_type: FrameType,
    len: u64,
    padlen: u64,

    fn emit(stream: anytype, self: Frame) !void {
        try stream.writeStruct(self);
    }
};

pub const Proto = struct {
    key: [32]u8,
    kp: dh.X25519.KeyPair,
    nonce: [12]u8 = [_]u8{0} ** 12,
    stream: net.Stream,
    remaining: usize,
    padlen: usize,
    closing: bool,
    peer_closing: bool,
    stream_offset: usize,
    peer_counter: u32,
    counter: u32,

    pub fn init(conn: net.Stream) !Proto {
        var proto: Proto = undefined;
        proto.remaining = 0;
        proto.padlen = 0;
        proto.closing = false;
        proto.peer_closing = false;
        proto.stream_offset = 0;
        proto.peer_counter = 0;
        proto.counter = 0;

        proto.kp = try dh.X25519.KeyPair.create(null);
        try conn.writer().writeStruct(Header{ .public_key = proto.kp.public_key });
        const peer_header = try conn.reader().readStruct(Header);
        std.debug.assert(peer_header.magic == magic);
        crypto.hash.Blake3.hash(&try dh.X25519.scalarmult(proto.kp.secret_key, peer_header.public_key), proto.key[0..], .{});
        proto.stream = conn;
        return proto;
    }

    pub fn write(self: *Proto, buf: []const u8) !void {
        const padlen = if (buf.len > 0)
            64 - buf.len % 64
        else
            0;
        try Frame.emit(self.stream.writer(), .{ .frame_type = .data, .len = buf.len, .padlen = padlen });
        var written: usize = 0;

        const buf_size_aligned = std.mem.alignBackward(usize, buf.len, 64);
        const rem = buf.len - buf_size_aligned;

        const blocks = buf_size_aligned / 64;

        for (0..blocks) |b| {
            var outstream: [64]u8 = undefined;
            var stream: [64]u8 = undefined;
            crypto.stream.chacha.ChaCha20IETF.stream(stream[0..], self.counter, self.key, self.nonce);
            for (buf[b * 64 .. (b * 64) + 64], 0..) |c, i| {
                outstream[i] = c ^ stream[self.stream_offset];
                self.stream_offset += 1;
            }
            self.stream_offset = 0;
            try self.stream.writer().writeAll(outstream[0..]);
            written += 64;
            self.counter += 1;
        }

        var outstream: [64]u8 = undefined;
        var stream: [64]u8 = undefined;
        crypto.stream.chacha.ChaCha20IETF.stream(stream[0..], self.counter, self.key, self.nonce);

        for (buf[buf.len - rem ..], 0..) |c, i| {
            outstream[i] = c ^ stream[self.stream_offset];
            self.stream_offset += 1;
        }
        written += rem;
        try self.stream.writer().writeAll(outstream[0..@min(rem, 64)]);
        self.counter += 1;
        self.stream_offset = 0;
        try self.stream.writer().writeByteNTimes(0, padlen);
        //self.counter += 1;
    }

    fn readRaw(self: *Proto, buf: []u8) !usize {
        if (self.remaining <= 0) {
            try self.stream.reader().skipBytes(self.padlen, .{});
            self.stream_offset = 0;
            if(self.padlen > 0) self.peer_counter += 1;
            const frame = try self.stream.reader().readStruct(Frame);
            self.remaining = frame.len;
            self.padlen = frame.padlen;
            if (frame.frame_type == .close) {
                self.peer_closing = true;
                //closing = true;
                std.debug.assert(frame.padlen == 0);
                std.debug.assert(frame.len == 0);
                return 0;
            }
        }
        var stream: [64]u8 = undefined;
        crypto.stream.chacha.ChaCha20IETF.stream(stream[0..], self.peer_counter, self.key, self.nonce);
        const n = try self.stream.reader().readAll(buf[0..@min(buf.len, self.remaining)]);
        for (buf[0..n]) |*c| {
            c.* ^= stream[self.stream_offset];
            self.stream_offset += 1;
            if (self.stream_offset == 64) {
                self.stream_offset = 0;
                self.peer_counter += 1;
            }
        }
        self.remaining -= n;
        return n;
    }

    pub fn read(self: *Proto, buf: []u8) !usize {
        var b: []u8 = buf;
        var t: usize = 0;
        while (!self.peer_closing and b.len > 0) {
            const n = try self.readRaw(b);
            b = b[n..];
            t += n;
        }
        return t;
    }

    pub fn close(self: *Proto) !void {
        try Frame.emit(self.stream.writer(), .{ .frame_type = .close, .len = 0, .padlen = 0 });
        self.closing = true;
    }
};
