const std = @import("std");

const data = @embedFile("../data/day02_input");

const Dir = enum {
    forward,
    up,
    down,
};

const Instruction = struct {
    dir: Dir,
    x: u8,
};

fn part1(instructions: []Instruction) !void {
    var depth: u32 = 0;
    var pos: u32 = 0;

    for (instructions) |inst| {
        switch (inst.dir) {
            Dir.forward => pos += inst.x,
            Dir.up => depth -= inst.x,
            Dir.down => depth += inst.x,
        }
    }

    std.debug.print("Day 02, part 1: (pos = {d}, depth = {d}), pos * depth = {d}\n", .{
        pos,
        depth,
        pos * depth,
    });
}

fn part2(instructions: []Instruction) !void {
    var depth: u32 = 0;
    var pos: u32 = 0;
    var aim: u32 = 0;

    for (instructions) |inst| {
        switch (inst.dir) {
            Dir.forward => {
                pos += inst.x;
                depth += aim * inst.x;
            },
            Dir.up => aim -= inst.x,
            Dir.down => aim += inst.x,
        }
    }

    std.debug.print("Day 02, part 2: (pos = {d}, depth = {d}, aim = {d}), pos * depth = {d}\n", .{
        pos,
        depth,
        aim,
        pos * depth,
    });
}

pub fn main() anyerror!void {
    var general_purpose_allocator = std.heap.GeneralPurposeAllocator(.{}){};
    const gpa = general_purpose_allocator.allocator();

    var instructions = std.ArrayList(Instruction).init(gpa);
    defer instructions.deinit();

    var it = std.mem.tokenize(u8, data, "\r\n");
    while (it.next()) |line| {
        var inst: Instruction = undefined;

        var jt = std.mem.tokenize(u8, line, " ");

        const dir_str = jt.next() orelse return error.ParseError;
        if (std.mem.eql(u8, dir_str, "forward")) {
            inst.dir = Dir.forward;
        } else if (std.mem.eql(u8, dir_str, "up")) {
            inst.dir = Dir.up;
        } else if (std.mem.eql(u8, dir_str, "down")) {
            inst.dir = Dir.down;
        } else {
            return error.ParseError;
        }

        const x_str = jt.next() orelse return error.ParseError;
        inst.x = try std.fmt.parseInt(u8, x_str, 10);

        try instructions.append(inst);

        // Debug print
        //switch (inst.dir) {
        //    Dir.forward => std.debug.print("forward {d}\n", .{inst.x}),
        //    Dir.up => std.debug.print("up {d}\n", .{inst.x}),
        //    Dir.down => std.debug.print("down {d}\n", .{inst.x}),
        //}
    }

    try part1(instructions.items);
    try part2(instructions.items);
}
