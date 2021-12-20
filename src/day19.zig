const std = @import("std");
const assert = std.debug.assert;

var general_purpose_allocator = std.heap.GeneralPurposeAllocator(.{}){};
const gpa = &general_purpose_allocator.allocator;

const data = @embedFile("../data/day19_input");

const Vec3 = struct {
    x: i16,
    y: i16,
    z: i16,

    pub fn init(x: i16, y: i16, z: i16) Vec3 {
        return .{
            .x = x,
            .y = y,
            .z = z,
        };
    }
    pub fn print(self: Vec3) void {
        std.debug.print("({}, {}, {})", .{ self.x, self.y, self.z });
    }

    pub fn add(self: Vec3, rhs: Vec3) Vec3 {
        return .{
            .x = self.x + rhs.x,
            .y = self.y + rhs.y,
            .z = self.z + rhs.z,
        };
    }
    pub fn sub(self: Vec3, rhs: Vec3) Vec3 {
        return .{
            .x = self.x - rhs.x,
            .y = self.y - rhs.y,
            .z = self.z - rhs.z,
        };
    }
    pub fn eq(self: Vec3, rhs: Vec3) bool {
        return self.x == rhs.x and self.y == rhs.y and self.z == rhs.z;
    }

    // TODO: Hmm, I feel there is a simpler way to do this.
    pub fn swizzle(self: Vec3, orientation_idx: usize) Vec3 {
        std.debug.assert(orientation_idx < 24);

        const quadrant_idx = orientation_idx / 3;
        const flip_x = (quadrant_idx >> 0) & 1;
        const flip_y = (quadrant_idx >> 1) & 1;
        const flip_z = (quadrant_idx >> 2) & 1;

        const num_flips = flip_x + flip_y + flip_z;
        const lhs = num_flips == 0 or num_flips == 2;

        const sizzle_x_idx = orientation_idx % 3;
        const sizzle_y_idx = (orientation_idx + @as(usize, if (lhs) 1 else 2)) % 3;
        const sizzle_z_idx = (orientation_idx + @as(usize, if (lhs) 2 else 1)) % 3;

        var xyz = [_]i16{
            if (flip_x > 0) -self.x else self.x,
            if (flip_y > 0) -self.y else self.y,
            if (flip_z > 0) -self.z else self.z,
        };

        return .{
            .x = xyz[sizzle_x_idx],
            .y = xyz[sizzle_y_idx],
            .z = xyz[sizzle_z_idx],
        };
    }

    pub fn uniqueHash(self: Vec3) u64 {
        const x = @as(u64, @bitCast(u16, self.x));
        const y = @as(u64, @bitCast(u16, self.y));
        const z = @as(u64, @bitCast(u16, self.z));
        return x + (y << 16) + (z << 32);
    }
};

const Trafo = struct {
    parent_idx: usize,
    orient_idx: usize,
    rel_pos: Vec3,
};

fn supportAtLeast12(positions1: []Vec3, positions2: []Vec3, orient_idx: usize, rel_pos: Vec3) bool {
    var support: usize = 0;
    for (positions2) |p2| {
        const p2_rot = p2.swizzle(orient_idx);
        for (positions1) |p1| {
            if (p2_rot.sub(p1).eq(rel_pos)) {
                support += 1;
                if (support == 12) {
                    return true;
                }
            }
        }
    }
    return false;
}

fn relativePos(positions1: []Vec3, positions2: []Vec3) ?Trafo {
    var orient_idx: usize = 0;
    while (orient_idx < 24) : (orient_idx += 1) {
        for (positions1) |p1| {
            for (positions2) |p2| {
                const p2_rot = p2.swizzle(orient_idx);

                const diff = p2_rot.sub(p1);
                if (supportAtLeast12(positions1, positions2, orient_idx, diff)) {
                    return Trafo{
                        .parent_idx = undefined,
                        .orient_idx = orient_idx,
                        .rel_pos = diff,
                    };
                }
            }
        }
    }
    return null;
}

fn transformToRoot(trafos_to_parent: []?Trafo, scanner_idx: usize, pos: Vec3) Vec3 {
    var p = pos;
    var maybe_parent = trafos_to_parent[scanner_idx];
    while (maybe_parent) |trafo| {
        p = p.swizzle(trafo.orient_idx).sub(trafo.rel_pos);
        maybe_parent = trafos_to_parent[trafo.parent_idx];
    }
    return p;
}

pub fn main() !void {
    var scanners = std.ArrayList(std.ArrayList(Vec3)).init(gpa);
    defer {
        for (scanners.items) |s| {
            s.deinit();
        }
        scanners.deinit();
    }

    var line_it = std.mem.tokenize(u8, data, "\r\n");
    while (line_it.next()) |line| {
        if (std.mem.startsWith(u8, line, "---")) {
            try scanners.append(std.ArrayList(Vec3).init(gpa));
        } else {
            var vec_it = std.mem.tokenize(u8, line, ",");
            const x = try std.fmt.parseInt(i16, vec_it.next().?, 10);
            const y = try std.fmt.parseInt(i16, vec_it.next().?, 10);
            const z = try std.fmt.parseInt(i16, vec_it.next().?, 10);
            try scanners.items[scanners.items.len - 1].append(Vec3.init(x, y, z));
        }
    }

    // Debug output
    //for (scanners.items) |s, i| {
    //    std.debug.print("--- scanner {} ---\n", .{i});
    //    for (s.items) |pos| {
    //        pos.print();
    //        std.debug.print("\n", .{});
    //    }
    //    std.debug.print("\n", .{});
    //}

    //const tmp = Vec3.init(1, 2, 3);
    //var i: usize = 0;
    //while (i < 24) : (i += 1) {
    //    tmp.swizzle(i).print();
    //    std.debug.print("\n", .{});
    //}

    var trafos_to_parent = std.ArrayList(?Trafo).init(gpa);
    defer {
        trafos_to_parent.deinit();
    }
    try trafos_to_parent.appendNTimes(null, scanners.items.len);

    var lookat_next = std.ArrayList(usize).init(gpa);
    defer lookat_next.deinit();
    try lookat_next.append(0);

    while (lookat_next.popOrNull()) |idx1| {
        const s1 = scanners.items[idx1];
        for (scanners.items) |s2, idx2| {
            if (idx2 == 0) {
                continue;
            }
            if (trafos_to_parent.items[idx2]) |_| {
                // We already know how to get from idx2 -> 0
                continue;
            }
            //std.debug.print("Looking for trafo of scanners {} and {}\n", .{ idx1, idx2 });

            if (relativePos(s1.items, s2.items)) |trafo| {
                //std.debug.print("Trafo of scanners {} and {}: orient swizzle {}, relative position {}\n", .{
                //    idx1,
                //    idx2,
                //    trafo.orient_idx,
                //    trafo.rel_pos,
                //});

                trafos_to_parent.items[idx2] = .{
                    .parent_idx = idx1,
                    .orient_idx = trafo.orient_idx,
                    .rel_pos = trafo.rel_pos,
                };
                try lookat_next.append(idx2);
            }
        }
    }

    var uniquePositions = std.AutoHashMap(u64, void).init(gpa);
    defer uniquePositions.deinit();
    for (scanners.items) |s, idx| {
        for (s.items) |pos| {
            const hash = transformToRoot(trafos_to_parent.items, idx, pos).uniqueHash();
            try uniquePositions.put(hash, {});
        }
    }

    std.debug.print("Day 19, part 1: num unique beacons = {}\n", .{uniquePositions.count()});

    var max_dist: i16 = 0;
    for (scanners.items) |_, idx1| {
        for (scanners.items) |_, idx2| {
            if (idx2 <= idx1) {
                continue;
            }

            const pos1 = transformToRoot(trafos_to_parent.items, idx1, Vec3.init(0, 0, 0));
            const pos2 = transformToRoot(trafos_to_parent.items, idx2, Vec3.init(0, 0, 0));
            const diff = pos1.sub(pos2);

            const manhatten_dist = (try std.math.absInt(diff.x)) + (try std.math.absInt(diff.y)) + (try std.math.absInt(diff.z));
            if (manhatten_dist > max_dist) {
                max_dist = manhatten_dist;
            }
        }
    }

    std.debug.print("Day 19, part 2: max manhatten dist = {}\n", .{max_dist});
}
