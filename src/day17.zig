const std = @import("std");
const assert = std.debug.assert;

const data = @embedFile("../data/day17_input");

pub fn main() anyerror!void {
    var it = std.mem.tokenize(u8, data, " \r\n");

    var x_target_pos_min: i16 = undefined;
    var x_target_pos_max: i16 = undefined;
    var y_target_pos_min: i16 = undefined;
    var y_target_pos_max: i16 = undefined;

    while (it.next()) |chunk| {
        if (std.mem.startsWith(u8, chunk, "x=")) {
            var jt = std.mem.tokenize(u8, chunk, "=.,");
            _ = jt.next().?; // "x"
            x_target_pos_min = try std.fmt.parseInt(i16, jt.next().?, 10);
            x_target_pos_max = try std.fmt.parseInt(i16, jt.next().?, 10);
        }
        if (std.mem.startsWith(u8, chunk, "y=")) {
            var jt = std.mem.tokenize(u8, chunk, "=.");
            _ = jt.next().?; // "y"
            y_target_pos_min = try std.fmt.parseInt(i16, jt.next().?, 10);
            y_target_pos_max = try std.fmt.parseInt(i16, jt.next().?, 10);
        }
    }

    // Debug output
    //std.debug.print("Target rect: {},{} to {},{}\n", .{
    //    x_target_pos_min,
    //    y_target_pos_min,
    //    x_target_pos_max,
    //    y_target_pos_max,
    //});

    // Almost went for brute force ...
    // But it turns out that velocity values come in pairs: once on the way up
    // and a second time on the way down. It starts at y=0 and will eventually
    // fall back to y=0 once more, and then take one final step of length
    // |y_target_pos_min|.
    // Hence the y start velocity is:
    const y_max_start_vel = -y_target_pos_min - 1;
    const y_max = @divExact(y_max_start_vel * (y_max_start_vel + 1), 2);
    std.debug.print("Day 17, part 1: max y = {}\n", .{y_max});

    // Let's do brue force anyway for part 2. Part 1 helped to find the search range though.

    const x_vel_search_start: i16 = blk: {
        var i: i16 = 0;
        var sum: i16 = 0;
        while (sum < x_target_pos_min) {
            i += 1;
            sum += i;
        }
        break :blk i;
    };
    const x_vel_search_end: i16 = x_target_pos_max + 1;
    const y_vel_search_start: i16 = y_target_pos_min;
    const y_vel_search_end: i16 = y_max_start_vel + 1;

    // Debug output
    //std.debug.print("Initial vel. search range: x \\in [{},{}], y \\in [{},{}]\n", .{
    //    x_vel_search_start,
    //    x_vel_search_end,
    //    y_vel_search_start,
    //    y_vel_search_end,
    //});

    // Brute force
    var num_successes: usize = 0;

    var x_vel_init = x_vel_search_start;
    while (x_vel_init < x_vel_search_end) : (x_vel_init += 1) {
        var y_vel_init = y_vel_search_start;
        while (y_vel_init < y_vel_search_end) : (y_vel_init += 1) {
            var x_vel = x_vel_init;
            var y_vel = y_vel_init;
            var x: i16 = 0;
            var y: i16 = 0;

            const success = blk: {
                while (true) {
                    if (x >= x_target_pos_min and x <= x_target_pos_max and y >= y_target_pos_min and y <= y_target_pos_max) {
                        //std.debug.print("Sucess {},{}\n", .{ x_vel_init, y_vel_init });
                        break :blk true;
                    }
                    if (x > x_target_pos_max or y < y_target_pos_min) {
                        break :blk false;
                    }

                    x += x_vel;
                    y += y_vel;
                    // Drag
                    if (x_vel > 0) {
                        x_vel -= 1;
                    } else if (x_vel < 0) {
                        x_vel += 1;
                    }
                    y_vel -= 1; // Gravity
                }
                unreachable;
            };
            if (success) {
                num_successes += 1;
            }
        }
    }

    std.debug.print("Day 17, part 2: num trajectories = {}\n", .{num_successes});
}
