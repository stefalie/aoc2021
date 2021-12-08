const std = @import("std");

const data = @embedFile("../data/day08_input");

fn part1() void {
    var sum: usize = 0;
    var line_it = std.mem.tokenize(u8, data, "\r\n");
    while (line_it.next()) |line_str| {
        var line_split = std.mem.tokenize(u8, line_str, "|");
        _ = line_split.next().?;

        var item_it = std.mem.tokenize(u8, line_split.next().?, " ");
        while (item_it.next()) |item| {
            const count = switch (item.len) {
                2, 4, 3, 7 => 1,
                else => @as(usize, 0),
            };
            sum += count;
        }
    }
    std.debug.print("Day 08, part 1: num with len \\in {{2, 3, 4, 7}}  = {}\n", .{sum});
}

fn bitset(str: []const u8) std.StaticBitSet(7) {
    var set = std.StaticBitSet(7).initEmpty();

    for (str) |c| {
        set.set(c - 'a');
    }

    return set;
}

// Does this really not exist in std?
fn bitsetEq(lhs: std.StaticBitSet(7), rhs: std.StaticBitSet(7)) bool {
    var tmp = lhs;
    tmp.toggleSet(rhs);
    return tmp.count() == 0;
}

fn part2() void {
    var sum: usize = 0;
    var line_it = std.mem.tokenize(u8, data, "\r\n");
    while (line_it.next()) |line_str| {
        var line_split = std.mem.tokenize(u8, line_str, "|");

        var signals: [10]std.StaticBitSet(7) = undefined;

        var signal_it = std.mem.tokenize(u8, line_split.next().?, " ");
        var i: usize = 0;
        while (signal_it.next()) |sig| : (i += 1) {
            signals[i] = bitset(sig);
        }

        var digits: [10]std.StaticBitSet(7) = undefined;

        // 1, 4, 7, 8 have a unit number of set bits
        for (signals) |sig| {
            switch (sig.count()) {
                2 => digits[1] = sig,
                4 => digits[4] = sig,
                3 => digits[7] = sig,
                7 => digits[8] = sig,
                else => {},
            }
        }

        // 3 is the only digit with a bit count of 5 that contains all bits of digit 1
        digits[3] = blk: {
            for (signals) |sig| {
                if (sig.count() == 5) {
                    var tmp = digits[1];
                    tmp.setIntersection(sig);
                    if (bitsetEq(tmp, digits[1])) {
                        break :blk sig;
                    }
                }
            }
            unreachable;
        };

        // 9 is the union of the bits of 3 and 4
        var tmp9 = digits[3];
        tmp9.setUnion(digits[4]);
        digits[9] = tmp9;

        // 0 and 6 both have a bit count of 6, 0 contains the bits of 1, 6 doesn't.
        // Both need to filter out the 9 as it also has a bit count of 6.
        for (signals) |sig| {
            if (sig.count() == 6 and !bitsetEq(sig, digits[9])) {
                var tmp = digits[1];
                tmp.setIntersection(sig);
                if (bitsetEq(tmp, digits[1])) {
                    digits[0] = sig;
                } else {
                    digits[6] = sig;
                }
            }
        }

        // 5 is the intersection of the bits of 6 and 9
        var tmp5 = digits[6];
        tmp5.setIntersection(digits[9]);
        digits[5] = tmp5;

        // 2 has a bit count of 5 but is not the same as 5 or 3.
        digits[2] = blk: {
            for (signals) |sig| {
                if (sig.count() == 5) {
                    if (!bitsetEq(sig, digits[3]) and !bitsetEq(sig, digits[5])) {
                        break :blk sig;
                    }
                }
            }
            unreachable;
        };

        //for (signals) |d| {
        //    std.debug.print("Sig: {} {}\n", .{ d, d.count() });
        //}
        //for (digits) |d| {
        //    std.debug.print("Dig: {} {}\n", .{ d, d.count() });
        //}
        //std.debug.print("\n", .{});

        // Compute the displayed value.
        var display_num: usize = 0;
        var display_it = std.mem.tokenize(u8, line_split.next().?, " ");
        while (display_it.next()) |item| {
            display_num *= 10;
            const display_digit = blk: {
                for (digits) |d, idx| {
                    if (bitsetEq(bitset(item), d)) {
                        break :blk idx;
                    }
                }
                unreachable;
            };
            display_num += display_digit;
        }

        sum += display_num;
    }
    std.debug.print("Day 08, part 2: sum = {}\n", .{sum});
}

pub fn main() anyerror!void {
    part1();
    part2();
}
