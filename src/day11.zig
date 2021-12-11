const std = @import("std");
const assert = std.debug.assert;

const data = @embedFile("../data/day11_input");

fn part1(grid: *[10][10]u4) void {
    var num_flashes: usize = 0;

    const num_iterations: usize = 100;
    var it: usize = 0;
    while (it < num_iterations) : (it += 1) {
        var y: isize = 0;
        while (y < 10) : (y += 1) {
            var x: isize = 0;
            while (x < 10) : (x += 1) {
                incAndCountFlashes(grid, x, y);
            }
        }

        // Reset after flash.
        y = 0;
        while (y < 10) : (y += 1) {
            var x: isize = 0;
            while (x < 10) : (x += 1) {
                const val = grid[@intCast(usize, y)][@intCast(usize, x)];
                if (val == 10) {
                    num_flashes += 1;
                    //std.debug.print("{}. {} {}\n", .{ num_flashes, y, x });
                    grid[@intCast(usize, y)][@intCast(usize, x)] = 0;
                }
            }
        }

        // Debug output
        //std.debug.print("Iteration {}\n", .{it});
        //for (grid) |grid_line| {
        //    for (grid_line) |val| {
        //        std.debug.print("{d}", .{val});
        //    }
        //    std.debug.print("\n", .{});
        //}
        //std.debug.print("\n", .{});
    }

    std.debug.print("Day 11, part 1: num flashes = {}\n", .{num_flashes});
}

fn part2(grid: *[10][10]u4) void {
    var num_iterations: usize = 100; // First 100 iterations done in part1

    while (true) : (num_iterations += 1) {
        var y: isize = 0;
        while (y < 10) : (y += 1) {
            var x: isize = 0;
            while (x < 10) : (x += 1) {
                incAndCountFlashes(grid, x, y);
            }
        }

        // Reset after flash.
        var num_flashes: usize = 0;
        y = 0;
        while (y < 10) : (y += 1) {
            var x: isize = 0;
            while (x < 10) : (x += 1) {
                const val = grid[@intCast(usize, y)][@intCast(usize, x)];
                if (val == 10) {
                    num_flashes += 1;
                    grid[@intCast(usize, y)][@intCast(usize, x)] = 0;
                }
            }
        }

        if (num_flashes == 100) {
            break;
        }
    }
    std.debug.print("Day 11, part 2: first all flash step = {}\n", .{num_iterations + 1});
}

fn incAndCountFlashes(grid: *[10][10]u4, x: isize, y: isize) void {
    if (x < 0 or y < 0 or x >= 10 or y >= 10) {
        return;
    }

    const val = grid[@intCast(usize, y)][@intCast(usize, x)];
    if (val == 10) {
        return;
    }

    grid[@intCast(usize, y)][@intCast(usize, x)] = val + 1;

    if (val == 9) {
        const offsets = [_]isize{ -1, 0, 1 };
        for (offsets) |y_off| {
            for (offsets) |x_off| {
                incAndCountFlashes(grid, x + x_off, y + y_off);
            }
        }
    }
}

pub fn main() anyerror!void {
    var grid: [10][10]u4 = undefined;

    var line_it = std.mem.tokenize(u8, data, "\r\n");

    var y: usize = 0;
    while (line_it.next()) |line| : (y += 1) {
        for (line) |c, x| {
            grid[y][x] = @intCast(u4, c - '0');
        }
    }

    part1(&grid);
    part2(&grid);
}
