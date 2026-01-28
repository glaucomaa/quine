const std = @import("std");

pub fn main() !void {
    const self: []const u8 = @embedFile(@src().file);
    try std.fs.File.stdout().writeAll(self);
}