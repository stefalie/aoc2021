const std = @import("std");
const assert = std.debug.assert;

const data = @embedFile("../data/day12_input");

fn part1RecursivePathFinding(nodes: []Node, edges: []Edge, curr_idx: usize, end_idx: usize) usize {
    if (curr_idx == end_idx) {
        return 1;
    }
    var node = &nodes[curr_idx];
    if (!node.is_big and node.visited) {
        return 0;
    }

    node.visited = true;
    var res: usize = 0;

    var i: usize = node.edge_start_idx;
    while (i < node.edge_end_idx) : (i += 1) {
        const new_pos = edges[i].dst;
        res += part1RecursivePathFinding(nodes, edges, new_pos, end_idx);
    }

    node.visited = false;
    return res;
}

fn part2RecursivePathFinding(nodes: []Node, edges: []Edge, start_idx: usize, curr_idx: usize, end_idx: usize, can_double_visit: bool, path_dbg: *std.ArrayList(usize)) anyerror!usize {
    try path_dbg.append(curr_idx);
    defer {
        _ = path_dbg.pop();
    }

    //std.debug.print("{s}, vis: {}, double: {}\n", .{ nodes[curr_idx].name, nodes[curr_idx].visited, can_double_visit });

    //for (path_dbg.items) |n_idx| {
    //    std.debug.print("{s},", .{nodes[n_idx].name});
    //}
    //std.debug.print("\n", .{});

    if (curr_idx == end_idx) {
        //std.debug.print("Sucess\n", .{});
        return 1;
    }
    var node = &nodes[curr_idx];

    const small_and_visited = !node.is_big and node.visited;
    var can_double_visit_next = can_double_visit;
    if (small_and_visited) {
        if (can_double_visit) {
            can_double_visit_next = false;
        } else {
            //std.debug.print("Can't visit again\n", .{});
            return 0;
        }
    }

    node.visited = true;
    var res: usize = 0;

    var i: usize = node.edge_start_idx;
    while (i < node.edge_end_idx) : (i += 1) {
        const new_pos = edges[i].dst;
        if (new_pos != start_idx) { // Don't move back to start.
            res += try part2RecursivePathFinding(nodes, edges, start_idx, new_pos, end_idx, can_double_visit_next, path_dbg);
        }
    }

    if (!small_and_visited) { // Nasty!
        node.visited = false;
    }
    return res;
}

var general_purpose_allocator = std.heap.GeneralPurposeAllocator(.{}){};
const gpa = &general_purpose_allocator.allocator;

const Node = struct {
    name: []const u8,
    is_big: bool = false,
    edge_start_idx: usize = 0,
    edge_end_idx: usize = 0,
    visited: bool = false,
};

const Edge = struct {
    src: usize = 0,
    dst: usize = 0,
};

pub fn main() anyerror!void {
    var node_name_to_idx = std.StringHashMap(usize).init(gpa);
    var nodes = std.ArrayList(Node).init(gpa);
    var edges = std.ArrayList(Edge).init(gpa);
    defer {
        node_name_to_idx.deinit();
        nodes.deinit();
        edges.deinit();
    }

    var line_it = std.mem.tokenize(u8, data, "\r\n");
    while (line_it.next()) |line| {
        var edge_it = std.mem.tokenize(u8, line, "-");
        const from_str = edge_it.next().?;
        const from_idx = node_name_to_idx.get(from_str) orelse blk: {
            const idx = nodes.items.len;
            try node_name_to_idx.put(from_str, idx);
            try nodes.append(.{
                .name = from_str,
                .is_big = from_str[0] >= 'A' and from_str[0] <= 'Z',
            });
            break :blk idx;
        };

        const to_str = edge_it.next().?;
        const to_idx = node_name_to_idx.get(to_str) orelse blk: {
            const idx = nodes.items.len;
            try node_name_to_idx.put(to_str, idx);
            try nodes.append(.{
                .name = to_str,
                .is_big = to_str[0] >= 'A' and to_str[0] <= 'Z',
            });
            break :blk idx;
        };

        const edge1 = Edge{ .src = from_idx, .dst = to_idx };
        const edge2 = Edge{ .src = to_idx, .dst = from_idx };
        try edges.append(edge1);
        try edges.append(edge2);
    }

    std.sort.sort(Edge, edges.items, {}, cmpEdgeLessThan);

    // Debug output
    //for (edges.items) |edge| {
    //    std.debug.print("Edge: {s}-{s}\n", .{
    //        nodes.items[edge.src].name,
    //        nodes.items[edge.dst].name,
    //    });
    //}

    // Find the start/end indices of all edges leaving each node.
    // This is simple because edges are now sorted by their source node.
    // TODO: Next time just add a std.ArrayList to every node, it's simpler.
    {
        nodes.items[edges.items[0].src].edge_start_idx = 0;
        var i: usize = 1;
        while (i < edges.items.len) : (i += 1) {
            if (edges.items[i].src != edges.items[i - 1].src) {
                nodes.items[edges.items[i - 1].src].edge_end_idx = i;
                nodes.items[edges.items[i].src].edge_start_idx = i;
            }
        }
        nodes.items[edges.items[i - 1].src].edge_end_idx = i;
    }
    // The 'src' field of Edge is now useless.

    // Debug output
    //for (nodes.items) |node| {
    //    std.debug.print("Node: {s}\n", .{node.name});
    //    var i: usize = node.edge_start_idx;
    //    while (i < node.edge_end_idx) : (i += 1) {
    //        std.debug.print("\tEdge: {s}-{s}\n", .{
    //            nodes.items[edges.items[i].src].name,
    //            nodes.items[edges.items[i].dst].name,
    //        });
    //    }
    //}

    const start_node_idx = node_name_to_idx.get("start").?;
    const end_node_idx = node_name_to_idx.get("end").?;
    const num_paths = part1RecursivePathFinding(nodes.items, edges.items, start_node_idx, end_node_idx);
    std.debug.print("Day 12, part 1: num paths = {}\n", .{num_paths});

    var path_dbg = std.ArrayList(usize).init(gpa);
    defer path_dbg.deinit();

    const num_ext_paths = try part2RecursivePathFinding(nodes.items, edges.items, start_node_idx, start_node_idx, end_node_idx, true, &path_dbg);
    std.debug.print("Day 12, part 2: num extended paths = {}\n", .{num_ext_paths});
}

fn cmpEdgeLessThan(ctx: void, lhs: Edge, rhs: Edge) bool {
    _ = ctx;
    return lhs.src < rhs.src;
}
