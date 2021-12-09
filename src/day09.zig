const std = @import("std");
const assert = std.debug.assert;

const data = @embedFile("../data/day09_input");

fn part1(grid: [100][100]u4, dim_x: usize, dim_y: usize) void {
    var sum: usize = 0;
    // TODO: This signed/unsigned casting and clamping to grid dimension is a pain,
    // I should just have padded the grid with a margin of 9s.

    var y: isize = 0;
    while (y < dim_y) : (y += 1) {
        var x: isize = 0;
        while (x < dim_x) : (x += 1) {
            const val = grid[@intCast(usize, y)][@intCast(usize, x)];

            const offsets_x = [_]isize{ -1, 1, 0, 0 };
            const offsets_y = [_]isize{ 0, 0, -1, 1 };

            const is_low = blk: {
                for (offsets_x) |_, i| {
                    const x_nghbr = x + offsets_x[i];
                    const y_nghbr = y + offsets_y[i];
                    if (x_nghbr >= 0 and x_nghbr <= dim_x - 1 and
                        y_nghbr >= 0 and y_nghbr <= dim_y - 1)
                    {
                        const val_nghbr = grid[@intCast(usize, y_nghbr)][@intCast(usize, x_nghbr)];

                        if (val_nghbr <= val) {
                            break :blk false;
                        }
                    }
                }
                break :blk true;
            };

            if (is_low) {
                sum += val + 1;
            }
        }
    }

    std.debug.print("Day 09, part 1: risk level = {}\n", .{sum});
}

fn countBasin(grid: *[100][100]u4, x: isize, y: isize, dim_x: usize, dim_y: usize) usize {
    if (x < 0 or y < 0 or x >= dim_x or y >= dim_y) {
        return 0;
    }
    if (grid[@intCast(usize, y)][@intCast(usize, x)] == 9) {
        return 0;
    }

    grid[@intCast(usize, y)][@intCast(usize, x)] = 9; // Mark cell as counted

    const offsets_x = [_]isize{ -1, 1, 0, 0 };
    const offsets_y = [_]isize{ 0, 0, -1, 1 };

    var sum: usize = 0;
    for (offsets_x) |_, i| {
        const x_nghbr = x + offsets_x[i];
        const y_nghbr = y + offsets_y[i];
        sum += countBasin(grid, x_nghbr, y_nghbr, dim_x, dim_y);
    }

    return sum + 1;
}

fn part2(grid: *[100][100]u4, dim_x: usize, dim_y: usize) void {
    var basins = [_]usize{ 0, 0, 0 };

    var y: isize = 0;
    while (y < dim_y) : (y += 1) {
        var x: isize = 0;
        while (x < dim_x) : (x += 1) {
            const basin_size = countBasin(grid, x, y, dim_x, dim_y);

            if (basin_size > basins[2]) {
                basins[0] = basins[1];
                basins[1] = basins[2];
                basins[2] = basin_size;
            } else if (basin_size > basins[1]) {
                basins[0] = basins[1];
                basins[1] = basin_size;
            } else if (basin_size > basins[0]) {
                basins[0] = basin_size;
            }
        }
    }

    std.debug.print("Day 09, part 2: (largest basins = {} {} {}), prod = {} \n", .{
        basins[0],
        basins[1],
        basins[2],
        basins[0] * basins[1] * basins[2],
    });
}

pub fn main() anyerror!void {
    var grid: [100][100]u4 = [_][100]u4{[_]u4{0} ** 100} ** 100;

    var grid_dim_x: usize = 0;
    var grid_dim_y: usize = 0;

    var line_it = std.mem.tokenize(u8, data, "\r\n");

    while (line_it.next()) |line| : (grid_dim_y += 1) {
        assert(grid_dim_x == 0 or grid_dim_x == line.len);
        grid_dim_x = line.len;

        for (line) |c, x| {
            const height = c - '0';
            grid[grid_dim_y][x] = @intCast(u4, height);
        }
    }

    // Debug output
    //for (grid[0..grid_dim_y]) |grid_line| {
    //    for (grid_line[0..grid_dim_x]) |val| {
    //        std.debug.print("{d}", .{val});
    //    }
    //    std.debug.print("\n", .{});
    //}
    part1(grid, grid_dim_x, grid_dim_y);
    part2(&grid, grid_dim_x, grid_dim_y);
}
