const std = @import("std");
const assert = std.debug.assert;

const data = @embedFile("../data/day25_input");

const max_dim_x: usize = 139;
const max_dim_y: usize = 137;

fn printGrid(grid: [max_dim_y][max_dim_x]u8, dim_x: usize, dim_y: usize) void {
    var y: usize = 0;
    while (y < dim_y) : (y += 1) {
        var x: usize = 0;
        while (x < dim_x) : (x += 1) {
            std.debug.print("{c}", .{grid[y][x]});
        }
        std.debug.print("\n", .{});
    }
}

fn simulateStep(grid: *[2][max_dim_y][max_dim_x]u8, dim_x: usize, dim_y: usize) bool {
    var changed = false;

    { // Move right
        var y: usize = 0;
        while (y < dim_y) : (y += 1) {
            var x: usize = 0;
            while (x < dim_x) : (x += 1) {
                const left = grid[0][y][if (x == 0) dim_x - 1 else x - 1];
                const right = grid[0][y][if (x == dim_x - 1) 0 else x + 1];
                const curr = grid[0][y][x];
                if (curr == '.' and left == '>') {
                    grid[1][y][x] = '>';
                    changed = true;
                } else if (curr == '>' and right == '.') {
                    grid[1][y][x] = '.';
                } else {
                    grid[1][y][x] = curr;
                }
            }
        }
    }

    { // Move down
        var y: usize = 0;
        while (y < dim_y) : (y += 1) {
            var x: usize = 0;
            while (x < dim_x) : (x += 1) {
                const up = grid[1][if (y == 0) dim_y - 1 else y - 1][x];
                const down = grid[1][if (y == dim_y - 1) 0 else y + 1][x];
                const curr = grid[1][y][x];
                if (curr == '.' and up == 'v') {
                    grid[0][y][x] = 'v';
                    changed = true;
                } else if (curr == 'v' and down == '.') {
                    grid[0][y][x] = '.';
                } else {
                    grid[0][y][x] = curr;
                }
            }
        }
    }

    return changed;
}

pub fn main() anyerror!void {
    var grid: [2][max_dim_y][max_dim_x]u8 = undefined;

    var dim_x: usize = 0;
    var dim_y: usize = 0;

    var line_it = std.mem.tokenize(u8, data, "\r\n");
    while (line_it.next()) |line| {
        dim_x = line.len;
        for (line) |c, i| {
            grid[0][dim_y][i] = c;
        }
        dim_y += 1;
    }

    // Debug output
    //printGrid(grid[0], dim_x, dim_y);
    //std.debug.print("\n", .{});

    var i: usize = 0;
    while (simulateStep(&grid, dim_x, dim_y)) : (i += 1) {
        //printGrid(grid[0], dim_x, dim_y);
        //std.debug.print("\n", .{});
    }

    std.debug.print("Day 25, part 1: num steps to standstill = {}\n", .{i + 1});
    std.debug.print("Day 25, part 2: nothing to do here :-)\n", .{});
}
