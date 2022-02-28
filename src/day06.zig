const std = @import("std");

const data = @embedFile("../data/day06_input");

fn simulateReplication(timers: []u8, num_days: usize) usize {
    var lanterns = [_]u64{0} ** 9;

    for (timers) |timer| {
        lanterns[timer] += 1;
    }

    var day: usize = 0;
    while (day < num_days) : (day += 1) {
        // respawn 7 days later
        lanterns[(day + 7) % 9] += lanterns[day % 9];

        // New lantern fish will replicate in 9 days.
        // Self assignment is nop.
        // lanterns[(day + 9) % 9] = lanterns[day % 9];
    }

    var num_lanters: usize = 0;
    for (lanterns) |l| {
        num_lanters += l;
    }
    return num_lanters;
}

var general_purpose_allocator = std.heap.GeneralPurposeAllocator(.{}){};
const gpa = general_purpose_allocator.allocator();

pub fn main() anyerror!void {
    var timers = std.ArrayList(u8).init(gpa);
    defer timers.deinit();

    var timer_it = std.mem.tokenize(u8, data, ",\r\n");

    while (timer_it.next()) |timer_str| {
        try timers.append(try std.fmt.parseInt(u8, timer_str, 10));
    }

    // Debug output
    //for (timers.items) |timer, i| {
    //    if (i > 0) {
    //        std.debug.print(",{}", .{timer});
    //    } else {
    //        std.debug.print("{}", .{timer});
    //    }
    //}
    //std.debug.print("\n", .{});

    std.debug.print("Day 06, part 1: num lanters after 80 days = {}\n", .{simulateReplication(timers.items, 80)});
    std.debug.print("Day 06, part 2: num lanters after 256 days = {}\n", .{simulateReplication(timers.items, 256)});
}
