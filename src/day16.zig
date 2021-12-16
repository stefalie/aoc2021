const std = @import("std");
const assert = std.debug.assert;

const data = @embedFile("../data/day16_input");

fn part2() void {
    std.debug.print("Day 16, part 2:\n", .{});
}

var general_purpose_allocator = std.heap.GeneralPurposeAllocator(.{}){};
const gpa = &general_purpose_allocator.allocator;

const Result = struct {
    version: u32,
    compute: ?usize,
};

fn combine(lhs: usize, rhs: usize, type_id: u3) usize {
    switch (type_id) {
        0 => return lhs + rhs,
        1 => return lhs * rhs,
        2 => return std.math.min(lhs, rhs),
        3 => return std.math.max(lhs, rhs),
        5 => return if (lhs > rhs) 1 else 0,
        6 => return if (lhs < rhs) 1 else 0,
        7 => return if (lhs == rhs) 1 else 0,
        else => unreachable,
    }
}

const Stream = struct {
    stream: []const u1,
    offset: usize,

    pub fn init(bin_stream: []const u1) Stream {
        return .{
            .stream = bin_stream,
            .offset = 0,
        };
    }

    // Idea stolen from
    // https://github.com/sheredom/AOC2021/blob/main/src/day16.zig
    pub fn extract(self: *Stream, comptime T: type) T {
        const num_bits: usize = @bitSizeOf(T);
        const slice = self.stream[self.offset..(self.offset + num_bits)];
        self.offset += num_bits;

        if (T == u1) { // Can't get the loop below to compile with u1
            return slice[0];
        } else {
            var result: T = 0;
            for (slice) |bit| {
                result <<= 1;
                result += bit;
            }
            return result;
        }
    }

    pub fn parsePacket(self: *Stream) Result {
        const version = self.extract(u3);
        const type_id = self.extract(u3);
        //std.debug.print("Packet (ver: {}, type: {})\n", .{ version, type_id });

        var res = Result{
            .version = version,
            .compute = null,
        };

        if (type_id == 4) {
            const value = self.parseValue();
            //std.debug.print("Value: {}\n", .{value});
            res.compute = value;
        } else {
            const length_type_id = self.extract(u1);
            if (length_type_id == 0) {
                const total_num_subpacket_bits = self.extract(u15);
                const end_offset = self.offset + total_num_subpacket_bits;
                while (self.offset < end_offset) {
                    const tmp = self.parsePacket();
                    res.version += tmp.version;

                    const rhs = tmp.compute.?;
                    res.compute = if (res.compute) |lhs| combine(lhs, rhs, type_id) else rhs;
                }
            } else {
                const num_subpackets = self.extract(u11);
                var i: usize = 0;
                while (i < num_subpackets) : (i += 1) {
                    const tmp = self.parsePacket();
                    res.version += tmp.version;

                    const rhs = tmp.compute.?;
                    res.compute = if (res.compute) |lhs| combine(lhs, rhs, type_id) else rhs;
                }
            }
        }
        return res;
    }

    pub fn parseValue(self: *Stream) usize {
        var value: usize = 0;
        while (true) {
            const quit = self.extract(u1) == 0;
            value = (value << 4) + self.extract(u4);
            if (quit) {
                return value;
            }
        }
        unreachable;
    }
};

pub fn main() anyerror!void {
    // This is a bit wasteful as @sizeOf(u1) and @alignOf(u1) are both 1 (same is true for u4). 7/8 (or 1/2) of the bits are wasted.
    var hex_data = std.ArrayList(u4).init(gpa);
    var bin_data = std.ArrayList(u1).init(gpa);
    defer hex_data.deinit();
    defer bin_data.deinit();

    var line_it = std.mem.tokenize(u8, data, "\r\n");
    while (line_it.next()) |line| {
        for (line) |c| {
            const hex: u4 = @intCast(u4, if (c >= 'A') c - 'A' + 10 else c - '0');
            try hex_data.append(hex);

            try bin_data.append(@intCast(u1, (hex >> 3) & 0x1));
            try bin_data.append(@intCast(u1, (hex >> 2) & 0x1));
            try bin_data.append(@intCast(u1, (hex >> 1) & 0x1));
            try bin_data.append(@intCast(u1, (hex >> 0) & 0x1));
        }
    }

    // Debug output
    //for (hex_data.items) |h| {
    //    std.debug.print("{b} ", .{@intCast(u32, h)});
    //}
    //std.debug.print("\n", .{});
    //for (bin_data.items) |b| {
    //    std.debug.print("{}", .{b});
    //}
    //std.debug.print("\n", .{});

    var stream = Stream.init(bin_data.items);
    const result = stream.parsePacket();
    std.debug.print("Day 16, part 1: total version accumulation = {}\n", .{result.version});
    std.debug.print("Day 16, part 2: total version accumulation = {}\n", .{result.compute});
}
