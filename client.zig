const std = @import("std");
const crypto = std.crypto;
const dh = crypto.dh;
const net = std.net;
const protocal = @import("proto.zig");

pub fn main() !void {
    const address = try net.Address.parseIp4("127.0.0.1", 3000);
    const conn = try net.tcpConnectToAddress(address);

    var pro = try protocal.Proto.init(conn);

    while (true) {
    var buf:[2]u8 = undefined;
    const n = try pro.read(buf[0..]);
    if(n == 0) break;
    std.debug.print("n: {}, {s}\n", .{n, buf[0..n]});
    }

    try pro.write("kwega sana");
    //try pro.write("kwega sana sana");
    try pro.close();
    //try pro.write("");


}