const std = @import("std");

const data = @embedFile("../data/day05_input");

const Vec2 = struct {
    x: i32,
    y: i32,

    pub fn init(x: i32, y: i32) Vec2 {
        return .{
            .x = x,
            .y = y,
        };
    }
    pub fn add(self: Vec2, rhs: Vec2) Vec2 {
        return .{
            .x = self.x + rhs.x,
            .y = self.y + rhs.y,
        };
    }
    pub fn sub(self: Vec2, rhs: Vec2) Vec2 {
        return .{
            .x = self.x - rhs.x,
            .y = self.y - rhs.y,
        };
    }
    pub fn eq(self: Vec2, rhs: Vec2) bool {
        return self.x == rhs.x and self.y == rhs.y;
    }
};

const Segment = struct {
    from: Vec2,
    to: Vec2,
};

fn part1(segments: []Segment) !void {
    var grid = [_]u8{0} ** (1000 * 1000);

    for (segments) |seg| {
        //std.debug.print("Segment = {}\n", .{seg});

        const diff = seg.to.sub(seg.from);
        if (diff.x == 0 or diff.y == 0) {
            const step = Vec2.init(std.math.clamp(diff.x, -1, 1), std.math.clamp(diff.y, -1, 1));
            const num_steps = std.math.absCast(if (diff.x == 0) diff.y else diff.x) + 1;
            //std.debug.print("Step = {}\n", .{step});
            //std.debug.print("Num steps = {}\n", .{num_steps});

            var p = seg.from;
            var i: usize = 0;
            while (i < num_steps) : (i += 1) {
                //std.debug.print("Set {}\n", .{p});
                grid[@intCast(usize, p.y * 1000 + p.x)] += 1;
                p = p.add(step);
            }
        }
    }

    var count_gt_one: u32 = 0;
    for (grid) |c| {
        if (c > 1) {
            count_gt_one += 1;
        }
    }

    std.debug.print("Day 05, part 1: count > 1 = {}\n", .{count_gt_one});
}

fn part2(segments: []Segment) !void {
    var grid = [_]u8{0} ** (1000 * 1000);

    for (segments) |seg| {
        const diff = seg.to.sub(seg.from);

        std.debug.assert((diff.x == 0 or diff.y == 0) or (std.math.absCast(diff.x) == std.math.absCast(diff.y)));

        const step = Vec2.init(std.math.clamp(diff.x, -1, 1), std.math.clamp(diff.y, -1, 1));
        const num_steps = std.math.absCast(if (diff.x == 0) diff.y else diff.x) + 1;

        var p = seg.from;
        var i: usize = 0;
        while (i < num_steps) : (i += 1) {
            grid[@intCast(usize, p.y * 1000 + p.x)] += 1;
            p = p.add(step);
        }
    }

    var count_gt_one: u32 = 0;
    for (grid) |c| {
        if (c > 1) {
            count_gt_one += 1;
        }
    }

    std.debug.print("Day 05, part 2: count > 1 w diags = {}\n", .{count_gt_one});
}

var general_purpose_allocator = std.heap.GeneralPurposeAllocator(.{}){};
const gpa = general_purpose_allocator.allocator();

pub fn main() anyerror!void {
    var segments = std.ArrayList(Segment).init(gpa);
    defer {
        segments.deinit();
    }

    var line_it = std.mem.tokenize(u8, data, "\r\n");

    while (line_it.next()) |line| {
        var seg: Segment = undefined;

        var seg_it = std.mem.tokenize(u8, line, ",-> ");
        seg.from.x = try std.fmt.parseInt(i32, seg_it.next().?, 10);
        seg.from.y = try std.fmt.parseInt(i32, seg_it.next().?, 10);
        seg.to.x = try std.fmt.parseInt(i32, seg_it.next().?, 10);
        seg.to.y = try std.fmt.parseInt(i32, seg_it.next().?, 10);

        try segments.append(seg);
    }

    // Debug output
    //for (segments.items) |seg| {
    //    std.debug.print("{},{} -> {},{}\n", .{
    //        seg.from.x,
    //        seg.from.y,
    //        seg.to.x,
    //        seg.to.y,
    //    });
    //}

    try part1(segments.items);
    try part2(segments.items);
}
