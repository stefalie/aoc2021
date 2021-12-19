const std = @import("std");
const assert = std.debug.assert;

const data = @embedFile("../data/day18_input");

var general_purpose_allocator = std.heap.GeneralPurposeAllocator(.{}){};
const gpa = &general_purpose_allocator.allocator;

const NodeData = union(enum) {
    value: usize,
    parent: struct {
        left_idx: usize,
        right_idx: usize,
    },
};
const Node = struct {
    parent_idx: ?usize,
    data: NodeData,
};

const Tree = struct {
    nodes: std.ArrayList(Node),

    pub fn init(allocator: *std.mem.Allocator) Tree {
        return .{
            .nodes = std.ArrayList(Node).init(allocator),
        };
    }
    pub fn deinit(self: *Tree) void {
        self.nodes.deinit();
    }
    pub fn reset(self: *Tree) void {
        self.nodes.clearRetainingCapacity();
    }

    pub fn allocNode(self: *Tree, node: Node) !usize {
        const return_idx = self.nodes.items.len;
        try self.nodes.append(node);

        // Set the parent index of the children if applicable.
        switch (node.data) {
            NodeData.parent => |p| {
                self.nodes.items[p.left_idx].parent_idx = return_idx;
                self.nodes.items[p.right_idx].parent_idx = return_idx;
            },
            else => {},
        }
        return return_idx;
    }

    pub fn print(self: *Tree, idx: usize) void {
        switch (self.nodes.items[idx].data) {
            NodeData.value => |val| std.debug.print("{}", .{val}),
            NodeData.parent => |n| {
                std.debug.print("[", .{});
                self.print(n.left_idx);
                std.debug.print(",", .{});
                self.print(n.right_idx);
                std.debug.print("]", .{});
            },
        }
        // print parent index
        //std.debug.print("{{{}}}", .{self.nodes.items[idx].parent_idx});
    }

    fn findLeftNeighbor(self: *Tree, idx: usize) ?usize {
        const nodes = self.nodes.items;
        var tmp = idx;

        var branch = nodes[tmp].parent_idx;
        while (branch) |b| {
            if (nodes[b].data.parent.left_idx != tmp) {
                break;
            }
            tmp = b;
            branch = nodes[tmp].parent_idx;
        }

        return if (branch) |b| {
            var ret = nodes[b].data.parent.left_idx;
            while (nodes[ret].data == NodeData.parent) {
                ret = nodes[ret].data.parent.right_idx;
            }
            return ret;
        } else null;
    }

    fn findRightNeighbor(self: *Tree, idx: usize) ?usize {
        const nodes = self.nodes.items;
        var tmp = idx;

        var branch = nodes[tmp].parent_idx;
        while (branch) |b| {
            if (nodes[b].data.parent.right_idx != tmp) {
                break;
            }
            tmp = b;
            branch = nodes[tmp].parent_idx;
        }

        return if (branch) |b| {
            var ret = nodes[b].data.parent.right_idx;
            while (nodes[ret].data == NodeData.parent) {
                ret = nodes[ret].data.parent.left_idx;
            }
            return ret;
        } else null;
    }

    // Returns true if something changed and needs to be run again.
    pub fn reduce(self: *Tree, root_idx: usize) !bool {
        return reduceExplode(self, root_idx, 0) or (try reduceSplit(self, root_idx, 0));
    }

    pub fn reduceExplode(self: *Tree, idx: usize, lvl: usize) bool {
        switch (self.nodes.items[idx].data) {
            NodeData.parent => |n| {
                if (lvl == 4) {
                    // Explode
                    const add_to_left = self.nodes.items[n.left_idx].data.value;
                    const add_to_right = self.nodes.items[n.right_idx].data.value;
                    if (self.findLeftNeighbor(idx)) |add_idx| {
                        self.nodes.items[add_idx].data.value += add_to_left;
                    }
                    if (self.findRightNeighbor(idx)) |add_idx| {
                        self.nodes.items[add_idx].data.value += add_to_right;
                    }

                    // Replace the node with a 0 value node.
                    // TODO: The 2 slots for the children are wasted. Somebody smarter
                    // would add a free list to the tree so that the slots of unused
                    // nodes get filled up again instead of always appending.
                    // TODO: No, it would actually better to just remove the element
                    // and to shift everything down by 1. Also newly added elements
                    // in splits should be inserted (and everything afterwards moved up).
                    // The advantage of that is that the left/right neighbors to increase
                    // in an explode operation are simply on the left/right in the array
                    // (skipping parent nodes).
                    self.nodes.items[idx].data = NodeData{ .value = 0 };
                    return true;
                } else {
                    return self.reduceExplode(n.left_idx, lvl + 1) or self.reduceExplode(n.right_idx, lvl + 1);
                }
            },
            NodeData.value => return false,
        }
    }
    pub fn reduceSplit(self: *Tree, idx: usize, lvl: usize) anyerror!bool {
        switch (self.nodes.items[idx].data) {
            NodeData.parent => |n| {
                return (try self.reduceSplit(n.left_idx, lvl + 1)) or (try self.reduceSplit(n.right_idx, lvl + 1));
            },
            NodeData.value => |val| {
                if (val > 9) {
                    const lhs = try self.allocNode(.{
                        .parent_idx = idx,
                        .data = .{ .value = val / 2 },
                    });
                    const rhs = try self.allocNode(.{
                        .parent_idx = idx,
                        .data = .{ .value = (val + 1) / 2 },
                    });
                    self.nodes.items[idx].data = .{
                        .parent = .{
                            .left_idx = lhs,
                            .right_idx = rhs,
                        },
                    };
                    return true;
                } else {
                    return false;
                }
            },
        }
    }

    pub fn score(self: *Tree, idx: usize) usize {
        return switch (self.nodes.items[idx].data) {
            NodeData.parent => |n| return 3 * self.score(n.left_idx) + 2 * self.score(n.right_idx),
            NodeData.value => |val| val,
        };
    }
};

fn parseLine(line: []const u8, tree: *Tree) !void {
    var idx_parse_stack = std.ArrayList(usize).init(gpa);
    defer idx_parse_stack.deinit();

    for (line) |c| {
        switch (c) {
            '[', ',' => {},
            ']' => {
                const rhs = idx_parse_stack.pop();
                const lhs = idx_parse_stack.pop();
                const idx = try tree.allocNode(.{
                    .parent_idx = null,
                    .data = .{ .parent = .{
                        .left_idx = lhs,
                        .right_idx = rhs,
                    } },
                });
                try idx_parse_stack.append(idx);
            },
            '0'...'9' => {
                const idx = try tree.allocNode(.{
                    .parent_idx = null,
                    .data = .{ .value = c - '0' },
                });
                try idx_parse_stack.append(idx);
            },
            else => unreachable,
        }
    }
}

fn part1() !void {
    var tree = Tree.init(gpa);
    defer tree.deinit();

    var prev_root_idx: ?usize = null;
    var line_it = std.mem.tokenize(u8, data, "\r\n");
    while (line_it.next()) |line| {
        try parseLine(line, &tree);

        const new_tree_idx = tree.nodes.items.len - 1;
        if (prev_root_idx) |prev| {
            // Combine "number" of current line with the one from the previous line.
            const curr_root_idx = try tree.allocNode(.{
                .parent_idx = null,
                .data = .{ .parent = .{
                    .left_idx = prev,
                    .right_idx = new_tree_idx,
                } },
            });
            prev_root_idx = curr_root_idx;

            //std.debug.print("Reduce:\n", .{});
            //tree.print(curr_root_idx);
            //std.debug.print("\n", .{});
            while (try tree.reduce(curr_root_idx)) {
                //tree.print(curr_root_idx);
                //std.debug.print("\n", .{});
            }
        } else {
            prev_root_idx = new_tree_idx;
        }

        // Debug output
        //tree.print(tree.nodes.items.len - 1);
        //std.debug.print("\n", .{});
    }

    const magnitude = tree.score(prev_root_idx.?);

    std.debug.print("Day 18, part 1: magnitude = {}\n", .{magnitude});
}

fn part2() !void {
    var tree = Tree.init(gpa);
    defer tree.deinit();

    var max: usize = 0;

    var line_it1 = std.mem.tokenize(u8, data, "\r\n");
    while (line_it1.next()) |line1| {
        var line_it2 = std.mem.tokenize(u8, data, "\r\n");
        while (line_it2.next()) |line2| {
            if (std.mem.eql(u8, line1, line2)) {
                continue;
            }

            tree.reset();

            // TODO: Parsing these over and over again is a waste.
            try parseLine(line1, &tree);
            const tree1_idx = tree.nodes.items.len - 1;
            try parseLine(line2, &tree);
            const tree2_idx = tree.nodes.items.len - 1;

            const combined_root_idx = try tree.allocNode(.{
                .parent_idx = null,
                .data = .{ .parent = .{
                    .left_idx = tree1_idx,
                    .right_idx = tree2_idx,
                } },
            });

            while (try tree.reduce(combined_root_idx)) {}
            const score = tree.score(combined_root_idx);
            if (score > max) {
                max = score;
            }
        }
    }

    std.debug.print("Day 18, part 2: max pair sum magnitude = {}\n", .{max});
}
pub fn main() anyerror!void {
    try part1();
    try part2();
}
