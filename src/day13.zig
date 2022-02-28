const std = @import("std");
const assert = std.debug.assert;

const data = @embedFile("../data/day13_input");

fn part1(positions: []Pos, folds: []Pos) void {
    // Should be large enough
    var grid = [_][655]Value{[_]Value{Value.empty} ** 655} ** 895;
    for (positions) |_, i| {
        var pos = positions[i];
        const fold = folds[0];
        if (fold.x == 0) {
            if (pos.y > fold.y) {
                pos.y = fold.y - (pos.y - fold.y);
            }
        } else {
            if (pos.x > fold.x) {
                pos.x = fold.x - (pos.x - fold.x);
            }
        }
        //std.debug.print("{}\n", .{pos});
        grid[pos.y][pos.x] = Value.hash;
    }

    // Debug output
    //for (grid) |row| {
    //    for (row) |val| {
    //        switch (val) {
    //            Value.empty => std.debug.print(".", .{}),
    //            Value.hash => std.debug.print("#", .{}),
    //        }
    //    }
    //    std.debug.print("\n", .{});
    //}

    var count_hashes: usize = 0;
    for (grid) |row| {
        for (row) |val| {
            if (val == Value.hash) {
                count_hashes += 1;
            }
        }
    }

    std.debug.print("Day 13, part 1: num dots = {}\n", .{count_hashes});
}

fn part2(positions: []Pos, folds: []Pos) void {
    // Should be large enough
    var grid = [_][40]Value{[_]Value{Value.empty} ** 40} ** 6;
    for (positions) |_, i| {
        var pos = positions[i];
        for (folds) |fold| {
            if (fold.x == 0) {
                if (pos.y > fold.y) {
                    pos.y = fold.y - (pos.y - fold.y);
                }
            } else {
                if (pos.x > fold.x) {
                    pos.x = fold.x - (pos.x - fold.x);
                }
            }
        }
        grid[pos.y][pos.x] = Value.hash;
    }

    std.debug.print("Day 13, part 2: code =\n", .{});
    for (grid) |row| {
        for (row) |val| {
            switch (val) {
                Value.empty => std.debug.print(".", .{}),
                Value.hash => std.debug.print("#", .{}),
            }
        }
        std.debug.print("\n", .{});
    }
}

const Value = enum(u1) {
    empty,
    hash,
};

const Pos = struct {
    x: u32,
    y: u32,
};

var general_purpose_allocator = std.heap.GeneralPurposeAllocator(.{}){};
const gpa = general_purpose_allocator.allocator();

pub fn main() anyerror!void {
    var line_it = std.mem.tokenize(u8, data, "\r\n");

    var positions = std.ArrayList(Pos).init(gpa);
    var folds = std.ArrayList(Pos).init(gpa);
    defer {
        positions.deinit();
        folds.deinit();
    }

    while (line_it.next()) |line| {
        if (std.mem.startsWith(u8, line, "fold along")) {
            var fold_it = std.mem.tokenize(u8, line, " =");
            _ = fold_it.next().?;
            _ = fold_it.next().?;
            const dir = fold_it.next().?;
            const pos = try std.fmt.parseInt(u32, fold_it.next().?, 10);
            try folds.append(.{
                .x = if (dir[0] == 'x') pos else 0,
                .y = if (dir[0] == 'y') pos else 0,
            });
        } else {
            var coord_it = std.mem.tokenize(u8, line, ",");
            if (coord_it.next()) |x_str| {
                const y_str = coord_it.next().?;
                try positions.append(.{
                    .x = try std.fmt.parseInt(u32, x_str, 10),
                    .y = try std.fmt.parseInt(u32, y_str, 10),
                });
            }
        }
    }

    // Debug output to make sure we parsed correctly
    //for (positions.items) |pos| {
    //    std.debug.print("{d},{d}\n", .{ pos.x, pos.y });
    //}
    //for (folds.items) |fold| {
    //    if (fold.x == 0) {
    //        std.debug.print("fold along y={}\n", .{fold.y});
    //    } else {
    //        std.debug.print("fold along x={}\n", .{fold.x});
    //    }
    //    // Compiler error.
    //    //std.debug.print("fold along {}={}\n", .{
    //    //    if (fold.x == 0) "y" else "x",
    //    //    if (fold.x == 0) fold.y else fold.x,
    //    //});
    //}

    part1(positions.items, folds.items);
    part2(positions.items, folds.items);
}
