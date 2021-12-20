const std = @import("std");
const assert = std.debug.assert;

const data = @embedFile("../data/day20_input");

fn printGrid(grid: *[106][106]u1) void {
    for (grid) |row| {
        for (row) |c| {
            if (c == 1) {
                std.debug.print("#", .{});
            } else {
                std.debug.print(".", .{});
            }
        }
        std.debug.print("\n", .{});
    }
}

fn enhance(algorithm: *std.StaticBitSet(512), grid: *[106][106]u1, x: usize, y: usize) u1 {
    const bits = [_]u1{
        grid[y + 1][x + 1],
        grid[y + 1][x + 0],
        grid[y + 1][x - 1],
        grid[y + 0][x + 1],
        grid[y + 0][x + 0],
        grid[y + 0][x - 1],
        grid[y - 1][x + 1],
        grid[y - 1][x + 0],
        grid[y - 1][x - 1],
    };

    var lookup: u9 = 0;
    for (bits) |b, i| {
        lookup += @as(u9, b) << @intCast(u4, i);
    }
    return if (algorithm.isSet(lookup)) 1 else 0;
}

pub fn main() anyerror!void {
    var line_it = std.mem.tokenize(u8, data, "\r\n");

    var algorithm = std.StaticBitSet(512).initEmpty();
    for (line_it.next().?) |c, idx| {
        if (c == '#') {
            algorithm.set(idx);
        }
    }

    var grid = [_][106][106]u1{[_][106]u1{[_]u1{0} ** 106} ** 106} ** 2;
    {
        var y: usize = 3;
        while (line_it.next()) |line| : (y += 1) {
            for (line) |c, i| {
                const x = i + 3;
                grid[0][y][x] = if (c == '#') 1 else 0;
            }
        }
    }

    if (false) { // Debug output
        var i: usize = 0;
        while (i < 512) : (i += 1) {
            if (algorithm.isSet(i)) {
                std.debug.print("#", .{});
            } else {
                std.debug.print(".", .{});
            }
        }
        std.debug.print("\n\n", .{});
        printGrid(grid[0]);
    }

    const num_iters: usize = 2;
    var it: usize = 0;
    var out_of_range_value = grid[0][0][0];
    while (it < num_iters) : (it += 1) {
        const offset = num_iters - it;
        const grid_from = &grid[it % 2];
        const grid_to = &grid[(it + 1) % 2];

        // Nasty, I didn't notice at first that after the 1st iteration
        // almost everything of the infinite image will be '#'.
        out_of_range_value = if (algorithm.isSet(if (out_of_range_value == 0) 0 else 511)) 1 else 0;

        for (grid_from) |row, y| {
            for (row) |_, x| {
                if (x < offset or x >= (106 - offset) or
                    y < offset or y >= (106 - offset))
                {
                    grid_to[y][x] = out_of_range_value;
                } else {
                    grid_to[y][x] = enhance(&algorithm, grid_from, x, y);
                }
            }
        }

        // printGrid(grid_to);
    }

    const num_lit = blk: {
        var res: usize = 0;
        const g = &grid[num_iters % 2];
        for (g) |row| {
            for (row) |val| {
                if (val == 1) {
                    res += 1;
                }
            }
        }
        break :blk res;
    };

    std.debug.print("Day 20, part 1: num lit pixels = {}\n", .{num_lit});
    std.debug.print("Day 20, part 2:\n", .{});
}
