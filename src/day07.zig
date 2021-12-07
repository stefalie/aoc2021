const std = @import("std");

const data = @embedFile("../data/day07_input");

fn part1(positions: []u16) !void {
    var max: u16 = 0;
    for (positions) |p| {
        max = if (p > max) p else max;
    }

    // Setting the derivative of a sum of square roots doesn't seem easy, try brute force.
    var best_case: usize = std.math.maxInt(usize);

    var i: u16 = 0;
    while (i < max) : (i += 1) {
        var sum: usize = 0;
        for (positions) |p| {
            var d = if (p > i) p - i else i - p;
            sum += d;

            if (sum >= best_case) {
                break;
            }
        }

        if (sum < best_case) {
            best_case = sum;
        }
    }

    std.debug.print("Day 07, part 1: best case fuel = {}\n", .{best_case});
}

fn part2(positions: []u16) void {
    var max: u16 = 0;
    for (positions) |p| {
        max = if (p > max) p else max;
    }

    var best_case: usize = std.math.maxInt(usize);

    var i: u16 = 0;
    while (i < max) : (i += 1) {
        var sum: usize = 0;
        for (positions) |p| {
            var d: usize = if (p > i) p - i else i - p;
            sum += d * (d + 1) / 2;

            if (sum >= best_case) {
                break;
            }
        }

        if (sum < best_case) {
            best_case = sum;
        }
    }

    std.debug.print("Day 07, part 2: best case non-const fuel = {}\n", .{best_case});
}

var general_purpose_allocator = std.heap.GeneralPurposeAllocator(.{}){};
const gpa = &general_purpose_allocator.allocator;

pub fn main() anyerror!void {
    var positions = std.ArrayList(u16).init(gpa);
    defer positions.deinit();

    var pos_it = std.mem.tokenize(u8, data, ",\r\n");

    while (pos_it.next()) |pos_str| {
        try positions.append(try std.fmt.parseInt(u16, pos_str, 10));
    }

    // Debug output
    //for (positions.items) |pos, i| {
    //    if (i > 0) {
    //        std.debug.print(",{}", .{pos});
    //    } else {
    //        std.debug.print("{}", .{pos});
    //    }
    //}
    //std.debug.print("\n", .{});

    try part1(positions.items);
    part2(positions.items);
}
