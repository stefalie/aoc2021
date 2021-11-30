const std = @import("std");

pub fn main() anyerror!void {
    std.log.info("All your codebase are belong to us 01.", .{});
}

test "basic test 2" {
    try std.testing.expectEqual(10, 3 + 7);
}
