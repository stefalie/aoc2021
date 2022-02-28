const std = @import("std");
const assert = std.debug.assert;

const data = @embedFile("../data/day22_input");

fn GenericVec3(comptime T: type) type {
    return struct {
        x: T,
        y: T,
        z: T,

        pub fn init(x: T, y: T, z: T) @This() {
            return .{ .x = x, .y = y, .z = z };
        }
        pub fn ones() @This() {
            return .{ .x = 1, .y = 1, .z = 1 };
        }
        pub fn add(self: @This(), rhs: @This()) @This() {
            return .{
                .x = self.x + rhs.x,
                .y = self.y + rhs.y,
                .z = self.z + rhs.z,
            };
        }
        pub fn sub(self: @This(), rhs: @This()) @This() {
            return .{
                .x = self.x - rhs.x,
                .y = self.y - rhs.y,
                .z = self.z - rhs.z,
            };
        }
        pub fn cwiseMax(self: @This(), rhs: @This()) @This() {
            return .{
                .x = std.math.max(self.x, rhs.x),
                .y = std.math.max(self.y, rhs.y),
                .z = std.math.max(self.z, rhs.z),
            };
        }
        pub fn cwiseMin(self: @This(), rhs: @This()) @This() {
            return .{
                .x = std.math.min(self.x, rhs.x),
                .y = std.math.min(self.y, rhs.y),
                .z = std.math.min(self.z, rhs.z),
            };
        }
        pub fn prod(self: Vec3) isize {
            return self.x * self.y * self.z;
        }
        pub fn print(self: @This()) void {
            std.debug.print("({}, {}, {})", .{ self.x, self.y, self.z });
        }
    };
}
const Vec3 = GenericVec3(i64);

const State = enum {
    on,
    off,
};

const Box = struct {
    state: State,
    from: Vec3,
    to: Vec3,

    pub fn contains(self: Box, pos: Vec3) bool {
        if (pos.x >= self.from.x and pos.x <= self.to.x and
            pos.y >= self.from.y and pos.y <= self.to.y and
            pos.z >= self.from.z and pos.z <= self.to.z)
        {
            return true;
        } else {
            return false;
        }
    }
    pub fn intersect(self: Box, rhs: Box, state: State) ?Box {
        var res: ?Box = null;
        const new_from = self.from.cwiseMax(rhs.from);
        const new_to = self.to.cwiseMin(rhs.to);
        if (new_from.x <= new_to.x and
            new_from.y <= new_to.y and
            new_from.z <= new_to.z)
        {
            res = .{
                .state = state,
                .from = new_from,
                .to = new_to,
            };
        }
        return res;
    }
    pub fn volume(self: Box) usize {
        return @intCast(usize, self.to.sub(self.from).add(Vec3.ones()).prod());
    }
    pub fn print(self: Box) void {
        std.debug.print("Box: value = {}\n", .{self.state});
        std.debug.print("\tFrom: ", .{});
        self.from.print();
        std.debug.print("\n\tTo: ", .{});
        self.to.print();
        std.debug.print("\n", .{});
    }
};

var general_purpose_allocator = std.heap.GeneralPurposeAllocator(.{}){};
const gpa = general_purpose_allocator.allocator();

pub fn main() anyerror!void {
    var boxes = std.ArrayList(Box).init(gpa);
    defer boxes.deinit();

    var line_it = std.mem.tokenize(u8, data, "\r\n");
    while (line_it.next()) |line| {
        var box: Box = undefined;

        var split_it = std.mem.tokenize(u8, line, " =.,");
        box.state = if (std.mem.eql(u8, split_it.next().?, "on")) State.on else State.off;
        _ = split_it.next().?; // x
        box.from.x = try std.fmt.parseInt(i32, split_it.next().?, 10);
        box.to.x = try std.fmt.parseInt(i32, split_it.next().?, 10);
        _ = split_it.next().?; // y
        box.from.y = try std.fmt.parseInt(i32, split_it.next().?, 10);
        box.to.y = try std.fmt.parseInt(i32, split_it.next().?, 10);
        _ = split_it.next().?; // z
        box.from.z = try std.fmt.parseInt(i32, split_it.next().?, 10);
        box.to.z = try std.fmt.parseInt(i32, split_it.next().?, 10);

        try boxes.append(box);
    }

    // Debug output
    //for (boxes.items) |box| {
    //    box.print();
    //}

    { // Part 1
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
                    for (boxes.items) |box| {
                        if (box.contains(pos)) {
                            on = box.state == State.on;
                        }
                    }

                    if (on) {
                        num_on += 1;
                    }
                }
            }
        }

        std.debug.print("Day 22, part 1: num active cubes = {}\n", .{num_on});
    }

    { // Part 2
        // At first I was thinking of maintaining a list of "on" boxes.
        // That gets complicated because one might have to split a cube into 27 smaller
        // boxes, which is a lot (or then go the extra mile to stitch neighboring
        // "on" boxes back together). Instead I decided to go for:
        // https://www.reddit.com/r/adventofcode/comments/rlxhmg/comment/hpjv8ok/?utm_source=share&utm_medium=web2x&context=3
        // Also see: https://en.wikipedia.org/wiki/Inclusion%E2%80%93exclusion_principle
        var final_boxes = std.ArrayList(Box).init(gpa);
        defer final_boxes.deinit();
        std.debug.assert(boxes.items[0].state == State.on);
        try final_boxes.append(boxes.items[0]);

        for (boxes.items[1..]) |box_in| {
            // Don't use a for with slice as we keep adding new boxes as we go.
            const num_boxes_to_check = final_boxes.items.len;
            //std.debug.print("\nNum boxes to intersect with {}, next:\n", .{num_boxes_to_check});
            //box_in.print();
            var i: usize = 0;
            while (i < num_boxes_to_check) : (i += 1) {
                const box_out = final_boxes.items[i];

                const intersect_state = if (box_out.state == State.on) State.off else State.on;
                if (box_in.intersect(box_out, intersect_state)) |intersect_box| {
                    //std.debug.print("valid\n", .{});
                    //intersect_box.print();
                    try final_boxes.append(intersect_box);
                }
            }

            if (box_in.state == State.on) {
                try final_boxes.append(box_in);
            }
        }

        var num_on: usize = 0;
        for (final_boxes.items) |box_out| {
            switch (box_out.state) {
                State.on => num_on += box_out.volume(),
                State.off => num_on -= box_out.volume(),
            }
        }

        std.debug.print("Day 22, part 2: num active cubes = {}\n", .{num_on});
    }
}
