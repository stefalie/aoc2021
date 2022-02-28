const std = @import("std");
const assert = std.debug.assert;

const data = @embedFile("../data/day14_input");

const Rule = struct {
    from: [2]u8,
    to: u8,
};

var general_purpose_allocator = std.heap.GeneralPurposeAllocator(.{}){};
const gpa = general_purpose_allocator.allocator();

// The straigh forward way of doing it is unfortunately not fast enough for part
// 2 and its 40 iterations.
fn part1() anyerror!void {
    var ping = std.ArrayList(u8).init(gpa);
    var pong = std.ArrayList(u8).init(gpa);
    var rules = std.ArrayList(Rule).init(gpa);
    defer {
        ping.deinit();
        pong.deinit();
        rules.deinit();
    }

    var line_it = std.mem.tokenize(u8, data, "\r\n");

    // Input string
    for (line_it.next().?) |c| {
        try ping.append(c);
    }

    // Rules
    while (line_it.next()) |line| {
        try rules.append(.{
            .from = line[0..2].*,
            .to = line[6],
        });
    }

    // Debug output
    //std.debug.print("{s}\n\n", .{ping.items});
    //for (rules.items) |r| {
    //    std.debug.print("{s} -> {}\n", .{ r.from, r.to });
    //}

    const num_iterations: usize = 10;
    var i: usize = 0;
    while (i < num_iterations) : (i += 1) {
        if (i > 0) {
            std.mem.swap(std.ArrayList(u8), &ping, &pong);
            pong.clearRetainingCapacity();
        }

        var idx: usize = 0;
        while (idx < ping.items.len - 1) : (idx += 1) {
            const c_curr = ping.items[idx];
            const c_next = ping.items[idx + 1];
            try pong.append(c_curr);

            for (rules.items) |rule| {
                if (c_curr == rule.from[0] and c_next == rule.from[1]) {
                    try pong.append(rule.to);
                }
            }
        }
        try pong.append(ping.items[idx]);

        //std.debug.print("{}: {s}\n", .{ i, pong.items });
    }

    var counts = [_]usize{0} ** 26;
    for (pong.items) |c| {
        counts[c - 'A'] += 1;
    }

    var min_count: usize = std.math.maxInt(usize);
    var max_count: usize = 0;
    for (counts) |c| {
        if (c > 0) {
            if (c < min_count) {
                min_count = c;
            }
            if (c > max_count) {
                max_count = c;
            }
        }
    }

    std.debug.print("Day 14, part 1: max count - min count = {}\n", .{max_count - min_count});
}

const Rule2 = struct {
    pair_name: [2]u8,
    generate: u8,
    predecessor_idx: usize, // TODO: Is this even needed? I Don't think so.
    sucessor_idx1: usize,
    sucessor_idx2: usize,
};

// TODO: You could use a std.StringHashMap instead.
fn getRuleIdx(rules: []Rule2, search_name: [2]u8) usize {
    for (rules) |r, idx| {
        if (r.pair_name[0] == search_name[0] and r.pair_name[1] == search_name[1]) {
            return idx;
        }
    }
    unreachable;
}

fn part2() anyerror!void {
    var rules = std.ArrayList(Rule2).init(gpa);
    defer rules.deinit();

    var line_it = std.mem.tokenize(u8, data, "\r\n");

    // Input string
    const input_str = line_it.next().?;

    // Rules
    while (line_it.next()) |line| {
        const predecessor = line[0..2].*;
        try rules.append(.{
            .pair_name = predecessor,
            .generate = line[6],
            .predecessor_idx = rules.items.len,
            .sucessor_idx1 = undefined,
            .sucessor_idx2 = undefined,
        });
    }

    // Fill in the sucessor pair indices.
    for (rules.items) |_, idx| {
        var rule = &rules.items[idx];
        const sucessor1 = [2]u8{ rule.pair_name[0], rule.generate };
        const sucessor2 = [2]u8{ rule.generate, rule.pair_name[1] };
        rule.sucessor_idx1 = getRuleIdx(rules.items, sucessor1);
        rule.sucessor_idx2 = getRuleIdx(rules.items, sucessor2);
    }

    // Input string
    var pair_counts_ping = std.ArrayList(usize).init(gpa);
    var pair_counts_pong = std.ArrayList(usize).init(gpa);
    defer {
        pair_counts_ping.deinit();
        pair_counts_pong.deinit();
    }

    try pair_counts_ping.appendNTimes(0, rules.items.len);
    var i: usize = 0;
    while (i < input_str.len - 1) : (i += 1) {
        // TODO: Why does this not work?
        //const pair = input_str[i..(i + 2)].*;
        const pair = [_]u8{ input_str[i], input_str[i + 1] };
        const rule_idx = getRuleIdx(rules.items, pair);
        pair_counts_ping.items[rule_idx] += 1;
    }

    // Debug output
    //std.debug.print("{s}\n", .{input_str});
    //for (rules.items) |r| {
    //    std.debug.print("{s} -> {c} == {c}\n", .{
    //        r.pair_name,
    //        rules.items[r.sucessor_idx1].pair_name[1],
    //        rules.items[r.sucessor_idx2].pair_name[0],
    //    });
    //}
    //for (pair_counts_ping.items) |_, idx| {
    //    std.debug.print("{s} count: {}\n", .{
    //        rules.items[idx].pair_name,
    //        pair_counts_ping.items[idx],
    //    });
    //}

    const num_iterations: usize = 40;
    var it: usize = 0;
    while (it < num_iterations) : (it += 1) {
        if (it > 0) {
            std.mem.swap(std.ArrayList(usize), &pair_counts_ping, &pair_counts_pong);
            pair_counts_pong.clearRetainingCapacity();
        }
        try pair_counts_pong.appendNTimes(0, rules.items.len);

        for (rules.items) |rule, idx| {
            const num_pairs = pair_counts_ping.items[idx];
            pair_counts_pong.items[rule.sucessor_idx1] += num_pairs;
            pair_counts_pong.items[rule.sucessor_idx2] += num_pairs;
        }
    }

    //std.debug.print("{s}\n", .{input_str});
    //for (pair_counts_pong.items) |_, idx| {
    //    std.debug.print("{s} count: {}\n", .{
    //        rules.items[idx].pair_name,
    //        pair_counts_pong.items[idx],
    //    });
    //}

    var counts = [_]usize{0} ** 26;
    for (pair_counts_pong.items) |count, idx| {
        const first_char = rules.items[idx].pair_name[0];
        counts[first_char - 'A'] += count;
    }
    // Count last char as it's not in any pair.
    counts[input_str[input_str.len - 1] - 'A'] += 1;

    var min_count: usize = std.math.maxInt(usize);
    var max_count: usize = 0;
    for (counts) |c| {
        if (c > 0) {
            if (c < min_count) {
                min_count = c;
            }
            if (c > max_count) {
                max_count = c;
            }
        }
    }

    std.debug.print("Day 14, part 2: max count - min count after 40 iterations = {}\n", .{max_count - min_count});
}

pub fn main() anyerror!void {
    try part1();
    try part2();
}
