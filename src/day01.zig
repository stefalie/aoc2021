const std = @import("std");

const data = @embedFile("../data/day01_input");

const ParseError = error{
    MissingLine,
};

fn part1() !void {
    // TODO: Do this in main() and store in array of []u16.
    var it = std.mem.tokenize(u8, data, "\r\n");
    const first = it.next() orelse return ParseError.MissingLine;
    var prev = try std.fmt.parseInt(u16, first, 10);

    var num_inc: u32 = 0;

    while (it.next()) |item| {
        //std.debug.print("{s}\n", .{@typeName(@TypeOf(item))});
        //std.debug.print("{s}\n", .{item});
        const curr = try std.fmt.parseInt(u16, item, 10);
        //std.debug.print("{d}\n", .{curr});

        if (curr > prev) {
            num_inc += 1;
        }

        prev = curr;
    }
    std.debug.print("Day 01, part 1: Number of increases: {d}\n", .{num_inc});
}

fn part2() !void {
    // TODO: Do this in main() and store in array of []u16.
    var it = std.mem.tokenize(u8, data, "\r\n");

    var window = [3]u32{ 0, 0, 0 };

    var idx: usize = 0;
    while (idx < 3) {
        const item = it.next() orelse return ParseError.MissingLine;
        window[idx] = try std.fmt.parseInt(u16, item, 10);
        idx += 1;
    }
    idx = 0;

    var num_inc: u32 = 0;

    var prev_win_sum = window[0] + window[1] + window[2];

    while (it.next()) |item| {
        window[idx] = try std.fmt.parseInt(u16, item, 10);
        idx = (idx + 1) % 3;

        var win_sum = window[0] + window[1] + window[2];
        if (win_sum > prev_win_sum) {
            num_inc += 1;
        }
        prev_win_sum = win_sum;
    }
    std.debug.print("Day 01, part 2: Number of windowed increases: {d}\n", .{num_inc});
}

pub fn main() anyerror!void {
    try part1();
    try part2();
}
