const std = @import("std");

const data = @embedFile("../data/day03_input");

fn part1(numbers: []u12) !void {
    // Debug output
    //for (numbers) |x| {
    //    var i: u4 = 0;
    //    while (i < 12) {
    //        // MSB first
    //        std.debug.print("{d}", .{(x >> (11 - i)) & 1});
    //        i += 1;
    //    }
    //    std.debug.print("\n", .{});
    //}
    //

    var acc = [12]i32{ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 };

    for (numbers) |x| {
        var i: u4 = 0;
        while (i < 12) {
            const bit = (x >> i) & 1;
            if (bit == 1) {
                acc[i] += 1;
            } else {
                acc[i] -= 1;
            }
            i += 1;
        }
    }

    var gamma_rate: u32 = 0;

    var i: u4 = 0;
    while (i < 12) {
        if (acc[i] > 0) {
            gamma_rate |= @as(u32, 1) << i;
        }
        i += 1;
    }

    const epsilon_rate = ~gamma_rate & 0x00000FFF;

    std.debug.print("Day 03, part 1: (gamma = {}, eps {}), power consumption = {}\n", .{
        gamma_rate,
        epsilon_rate,
        gamma_rate * epsilon_rate,
    });
}

fn part2(numbers: []u12) !void {
    var mask: u12 = 0;
    var o2_prefix: u12 = 0;
    var co2_prefix: u12 = 0;

    var bit: u12 = 0b1000_0000_0000;
    while (bit > 0) : (bit >>= 1) {
        var o2_count_1: i32 = 0;
        var o2_count_0: i32 = 0;
        var co2_count_1: i32 = 0;
        var co2_count_0: i32 = 0;

        for (numbers) |x| {
            if (x & mask == o2_prefix) {
                if (bit & x > 0) {
                    o2_count_1 += 1;
                } else {
                    o2_count_0 += 1;
                }
            }

            if (x & mask == co2_prefix) {
                if (bit & x > 0) {
                    co2_count_1 += 1;
                } else {
                    co2_count_0 += 1;
                }
            }
        }

        if (o2_count_1 >= o2_count_0) {
            o2_prefix |= bit;
        }
        if ((co2_count_1 < co2_count_0 and co2_count_1 > 0) or (co2_count_0 == 0)) {
            co2_prefix |= bit;
        }

        //std.debug.print("Mask: {b}\n", .{@intCast(u32, mask)});
        //std.debug.print("O_2  Counts: {} {}\n", .{ o2_count_1, o2_count_0 });
        //std.debug.print("CO_2 Counts: {} {}\n", .{ co2_count_1, co2_count_0 });
        //std.debug.print("Prefix O_2 CO_2: {b} {b}\n", .{ @intCast(u32, o2_prefix), @intCast(u32, co2_prefix) });

        mask |= bit;
    }

    const oxygen_genertor_rating: u32 = o2_prefix;
    const co2_scrubber_rating: u32 = co2_prefix;
    const life_support_rating: u32 = oxygen_genertor_rating * co2_scrubber_rating;

    std.debug.print("Day 03, part 2: (O_2 gen rating = {}, CO_2 scrubber rating {}), life support rating = {}\n", .{
        oxygen_genertor_rating,
        co2_scrubber_rating,
        life_support_rating,
    });
}

pub fn main() anyerror!void {
    var general_purpose_allocator = std.heap.GeneralPurposeAllocator(.{}){};
    const gpa = general_purpose_allocator.allocator();

    var numbers = std.ArrayList(u12).init(gpa);
    defer numbers.deinit();

    var it = std.mem.tokenize(u8, data, "\r\n");
    while (it.next()) |line| {
        const bitfield = try std.fmt.parseInt(u12, line, 2);
        try numbers.append(bitfield);
    }

    try part1(numbers.items);
    try part2(numbers.items);
}
