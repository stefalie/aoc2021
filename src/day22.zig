const std = @import("std");
const assert = std.debug.assert;

const data = @embedFile("../data/day22_input");

const Vec3 = struct {
    x: i32,
    y: i32,
    z: i32,

    pub fn init(x: i32, y: i32, z: i32) Vec3 {
        return .{
            .x = x,
            .y = y,
            .z = z,
        };
    }
    pub fn print(self: Vec3) void {
        std.debug.print("({}, {}, {})", .{ self.x, self.y, self.z });
    }
};

const Cube = struct {
    on: bool,
    from: Vec3,
    to: Vec3,

    pub fn contains(self: Cube, pos: Vec3) bool {
        if (pos.x >= self.from.x and pos.x <= self.to.x and
            pos.y >= self.from.y and pos.y <= self.to.y and
            pos.z >= self.from.z and pos.z <= self.to.z)
        {
            return true;
        } else {
            return false;
        }
    }
};

var general_purpose_allocator = std.heap.GeneralPurposeAllocator(.{}){};
const gpa = &general_purpose_allocator.allocator;

pub fn main() anyerror!void {
    var cubes = std.ArrayList(Cube).init(gpa);
    defer cubes.deinit();

    var line_it = std.mem.tokenize(u8, data, "\r\n");
    while (line_it.next()) |line| {
        var cube: Cube = undefined;

        var split_it = std.mem.tokenize(u8, line, " =.,");
        cube.on = std.mem.eql(u8, split_it.next().?, "on");
        _ = split_it.next().?; // x
        cube.from.x = try std.fmt.parseInt(i32, split_it.next().?, 10);
        cube.to.x = try std.fmt.parseInt(i32, split_it.next().?, 10);
        _ = split_it.next().?; // y
        cube.from.y = try std.fmt.parseInt(i32, split_it.next().?, 10);
        cube.to.y = try std.fmt.parseInt(i32, split_it.next().?, 10);
        _ = split_it.next().?; // z
        cube.from.z = try std.fmt.parseInt(i32, split_it.next().?, 10);
        cube.to.z = try std.fmt.parseInt(i32, split_it.next().?, 10);

        try cubes.append(cube);
    }

    // Debug output
    //for (cubes.items) |cube| {
    //    std.debug.print("Cube: on = {}\n", .{cube.on});
    //    std.debug.print("\tFrom: ", .{});
    //    cube.from.print();
    //    std.debug.print("\n\tTo: ", .{});
    //    cube.to.print();
    //    std.debug.print("\n", .{});
    //}

    var num_on: usize = 0;
    const limit: i32 = 50;
    var z = -limit;
    while (z <= limit) : (z += 1) {
        var y = -limit;
        while (y <= limit) : (y += 1) {
            var x = -limit;
            while (x <= limit) : (x += 1) {
                const pos = Vec3.init(x, y, z);

                var on = false;
                for (cubes.items) |cube| {
                    if (cube.contains(pos)) {
                        on = cube.on;
                    }
                }

                num_on += @as(usize, if (on) 1 else 0);
            }
        }
    }

    std.debug.print("Day 22, part 1: num active cubes = {}\n", .{num_on});
    std.debug.print("Day 22, part 2:\n", .{});
}
