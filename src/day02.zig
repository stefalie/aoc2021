const std = @import("std");

pub fn main() anyerror!void {
    std.log.info("All your codebase are belong to us 02.", .{});
}

test "basic test" {
    try std.testing.expectEqual(10, 3 + 7);
}
