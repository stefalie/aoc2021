const std = @import("std");
const assert = std.debug.assert;

const data = @embedFile("../data/day15_input");

var general_purpose_allocator = std.heap.GeneralPurposeAllocator(.{}){};
const gpa = general_purpose_allocator.allocator();

const Node = struct {
    risk: u8 = undefined,
    visited: bool = false,
    g: u16 = std.math.maxInt(u16), // aka accumulated risk
    f: u16 = std.math.maxInt(u16), // full_path estimate
    x: i16 = undefined,
    y: i16 = undefined,
    from_x: i16 = undefined, // not needed
    from_y: i16 = undefined, // not needed
};

// Min heap
// std.PriorityQueue does likely exactly the same but it doesn't seem to allow updates the way we want it.
const Heap = struct {
    values: std.ArrayList(*Node),

    pub fn init() Heap {
        return .{
            .values = std.ArrayList(*Node).init(gpa),
        };
    }

    pub fn deinit(self: *Heap) void {
        self.values.deinit();
    }

    pub fn add(self: *Heap, node: *Node) !void {
        try self.values.append(node);

        // Sift up
        var i: usize = self.values.items.len - 1;
        while (i > 0) {
            const parent = (i - 1) / 2;
            // TODO
            if (self.values.items[i].x == 2 and self.values.items[i].y == 55) {
                std.debug.print("move up to parent {}? f{} < f_parent{}\n", .{ parent, self.values.items[i], self.values.items[parent] });
            }
            if (nodeLessThan(self.values.items[i], self.values.items[parent])) {
                // Swap
                const tmp: *Node = self.values.items[i];
                self.values.items[i] = self.values.items[parent];
                self.values.items[parent] = tmp;

                i = parent;
            } else {
                break;
            }
        }
    }

    pub fn addIfNotExistingOrSiftUp(self: *Heap, node: *Node) !void {
        for (self.values.items) |n, idx| {
            if (n == node) {
                self.siftUp(idx);
                return;
            }
        }

        try self.values.append(node);
        self.siftUp(self.values.items.len - 1);
    }

    pub fn siftUp(self: *Heap, idx: usize) void {
        var i = idx;
        while (i > 0) {
            const parent = (i - 1) / 2;
            if (nodeLessThan(self.values.items[i], self.values.items[parent])) {
                // Swap
                const tmp: *Node = self.values.items[i];
                self.values.items[i] = self.values.items[parent];
                self.values.items[parent] = tmp;

                i = parent;
            } else {
                break;
            }
        }
    }

    pub fn popFrontOrNull(self: *Heap) ?*Node {
        if (self.values.items.len == 0) {
            return null;
        }
        if (self.values.items.len == 1) {
            return self.values.pop();
        }

        const res = self.values.items[0];
        const pop_val = self.values.pop();
        self.values.items[0] = pop_val;

        self.siftDown(0);
        return res;
    }

    pub fn siftDown(self: *Heap, idx: usize) void {
        var i = idx;
        while (true) {
            var smallest = i;
            const left = 2 * i + 1;
            const right = 2 * i + 2;

            if (left < self.values.items.len and nodeLessThan(self.values.items[left], self.values.items[smallest])) {
                smallest = left;
            }

            if (right < self.values.items.len and nodeLessThan(self.values.items[right], self.values.items[smallest])) {
                smallest = right;
            }

            if (smallest == i) {
                break;
            } else {
                // Swap
                const tmp = self.values.items[i];
                self.values.items[i] = self.values.items[smallest];
                self.values.items[smallest] = tmp;
                // Prepare next iteration.
                i = smallest;
            }
        }
    }

    // Untested
    pub fn removeIfExisting(self: *Heap, node: *Node) void {
        for (self.values.items) |n, idx| {
            if (n == node) {
                const pop_val = self.values.pop();
                self.values.items[idx] = pop_val;
                self.siftDown(idx);
            }
        }
    }
};

fn nodeLessThan(lhs: *Node, rhs: *Node) bool {
    // Moved visited ondes to front of queue so that they're removed soon.
    if (lhs.visited and !rhs.visited) {
        return true;
    } else if (!lhs.visited and rhs.visited) {
        return false;
    }
    return lhs.f < rhs.f;
}

// A* heuristic
fn h(x: i16, y: i16, dim_x: usize, dim_y: usize) u16 {
    return @intCast(u16, (dim_x - 1) + (dim_y - 1)) - (@intCast(u16, x) + @intCast(u16, y));
}

// TODO: pass start/end positions as params.
fn aStar(grid: *std.ArrayList(Node), dim_x: usize, dim_y: usize) !usize {
    var q = Heap.init();
    defer q.deinit();

    // Dijkstra, no actually A*
    grid.items[0].g = 0;
    grid.items[0].f = 0 + h(0, 0, dim_x, dim_y);
    try q.add(&grid.items[0]);

    while (q.popFrontOrNull()) |node| {
        if (!node.visited) {
            node.visited = true;

            // Check if done.
            if (node.x == dim_x - 1 and node.y == dim_y - 1) {
                // Debug output final state
                //for (grid.items) |n, idx| {
                //    if (n.visited) {
                //        std.debug.print("{}", .{n.risk});
                //    } else {
                //        std.debug.print(".", .{});
                //    }
                //    if ((idx + 1) % dim_x == 0) {
                //        std.debug.print("\n", .{});
                //    }
                //}

                break;
            }

            // Add neighbors to queue.
            const offsets = [_][2]i16{ .{ -1, 0 }, .{ 1, 0 }, .{ 0, -1 }, .{ 0, 1 } };
            for (offsets) |off| {
                const new_x = off[0] + node.x;
                const new_y = off[1] + node.y;

                if (new_x >= 0 and new_x < dim_x and new_y >= 0 and new_y < dim_y) {
                    const neighbor_node: *Node = &grid.items[@intCast(usize, new_y) * dim_x + @intCast(usize, new_x)];

                    if (!neighbor_node.visited) {
                        // Estimate and add to queue
                        const g = node.g + neighbor_node.risk;
                        if (g < neighbor_node.g) {
                            neighbor_node.g = g;
                            neighbor_node.f = g + h(new_x, new_y, dim_x, dim_y);
                            neighbor_node.from_x = node.x;
                            neighbor_node.from_y = node.y;
                            try q.addIfNotExistingOrSiftUp(neighbor_node);
                        }
                    } else {
                        const g = node.g + neighbor_node.risk;
                        std.debug.assert(g >= neighbor_node.g);
                    }
                }
            }
        }
    }

    const path_cost = grid.items[grid.items.len - 1].g;
    return path_cost;
}

pub fn main() anyerror!void {
    var grid = std.ArrayList(Node).init(gpa);
    defer grid.deinit();

    var line_it = std.mem.tokenize(u8, data, "\r\n");

    var dim_x: usize = 0;
    var dim_y: usize = 0;
    while (line_it.next()) |line| {
        for (line) |c, x| {
            try grid.append(Node{
                .risk = c - '0',
                .x = @intCast(i16, x),
                .y = @intCast(i16, dim_y),
            });
        }

        dim_x = line.len;
        dim_y += 1;
    }

    // Debug output
    //for (grid.items) |node, idx| {
    //    std.debug.print("{}", .{node.risk});
    //    if ((idx + 1) % dim_x == 0) {
    //        std.debug.print("\n", .{});
    //    }
    //}

    var grid_x5 = std.ArrayList(Node).init(gpa);
    defer grid_x5.deinit();
    try grid_x5.resize(grid.items.len * 25);

    var tile_y: usize = 0;
    while (tile_y < 5) : (tile_y += 1) {
        var tile_x: usize = 0;
        while (tile_x < 5) : (tile_x += 1) {
            var y: usize = 0;
            while (y < dim_y) : (y += 1) {
                var x: usize = 0;
                while (x < dim_x) : (x += 1) {
                    const val = grid.items[y * dim_x + x].risk;
                    const new_val = @intCast(u8, ((val + tile_y + tile_x) - 1) % 9 + 1);
                    const new_x = tile_x * dim_x + x;
                    const new_y = tile_y * dim_y + y;
                    const new_idx = new_y * (dim_x * 5) + new_x;
                    grid_x5.items[new_idx] = Node{
                        .risk = new_val,
                        .x = @intCast(i16, new_x),
                        .y = @intCast(i16, new_y),
                    };
                }
            }
        }
    }

    // Debug output
    //for (grid_x5.items) |node, idx| {
    //    std.debug.print("{}", .{node.risk});
    //    if ((idx + 1) % (dim_x * 5) == 0) {
    //        std.debug.print("\n", .{});
    //    }
    //}

    const path_cost = aStar(&grid, dim_x, dim_y);
    std.debug.print("Day 15, part 1: min risk path = {}\n", .{path_cost});

    const path_cost_x5 = aStar(&grid_x5, dim_x * 5, dim_y * 5);
    std.debug.print("Day 15, part 2: min risk path grid * 5 = {}\n", .{path_cost_x5});
}
