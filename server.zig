const std = @import("std");
const crypto = std.crypto;
const dh = crypto.dh;
const net = std.net;
const protocal = @import("proto.zig");



pub fn main() !void {
    const address = try net.Address.parseIp4("127.0.0.1", 3000);

    var server = try address.listen(.{.reuse_address = true, .reuse_port = true});

    while (true) {
        const connection = try server.accept();

        var proto = try protocal.Proto.init(connection.stream);

        try proto.write("zenge");

        try proto.write(
        \\hello ghasia tena 
        \\hhhhhhhhhhhhhhhhhhhhhhhhhhh
        \\hhhhhhhhhhhhhhhhhg
        );
        try proto.write("hello ghasia tena");
        try proto.write("hello ghasia tena");
        try proto.write("hello ghasia tena");
        try proto.write("hello ghasia tena");
        try proto.write("hello ghasia tena");
        try proto.write("hello ghasia tena");
        try proto.write("hello ghasia tena");
        try proto.write("hello ghasia tena");
        try proto.write("hello ghasia tena");
        try proto.write("hello ghasia tena");
        try proto.write("hello ghasia tena");
        try proto.write("hello ghasia tena");
        try proto.write("hello ghasia tena");
        try proto.write("z");
        try proto.close();

        var buf: [100]u8 = undefined;
        const res = try proto.read(buf[0..]);

        std.debug.print("new connection: {s}\n", .{buf[0..res]});

    }
}
