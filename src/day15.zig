const std = @import("std");
const assert = std.debug.assert;

const data = @embedFile("../data/day15_input");

fn part2() void {
    std.debug.print("Day 15, part 2:\n", .{});
}

var general_purpose_allocator = std.heap.GeneralPurposeAllocator(.{}){};
const gpa = &general_purpose_allocator.allocator;

const Node = struct {
    risk: u8 = undefined,
    visited: bool = false,
    g: u16 = std.math.maxInt(u16), // aka accumulated risk
    f: u16 = std.math.maxInt(u16), // full_path estimate
    x: i8 = undefined,
    y: i8 = undefined,
};

fn priorityLessThan(lhs: *Node, rhs: *Node) std.math.Order {
    // Moved visited ondes to front of queue so that they're removed soon.
    if (lhs.visited and !rhs.visited) {
        return std.math.Order.lt;
    } else if (!lhs.visited and rhs.visited) {
        return std.math.Order.gt;
    }

    if (lhs.f < rhs.f) {
        return std.math.Order.lt;
    } else if (lhs.f > rhs.f) {
        return std.math.Order.gt;
    }
    return std.math.Order.eq;
}

// A* heuristic
fn h(x: i8, y: i8, dim_x: usize, dim_y: usize) u16 {
    return @intCast(u16, (dim_x - 1) + (dim_y - 1)) - (@intCast(u16, x) + @intCast(u16, y));
}

fn aStar(grid: *std.ArrayList(Node), dim_x: usize, dim_y: usize) !usize {
    // TODO: pass start/end positions as params.
    var q = std.PriorityQueue(*Node, priorityLessThan).init(gpa);
    defer q.deinit();

    // Dijkstra, no actually A*
    grid.items[0].g = 0;
    grid.items[0].f = 0 + h(0, 0, dim_x, dim_y);
    try q.add(&grid.items[0]);

    while (q.removeOrNull()) |node| {
        if (!node.visited) {
            node.visited = true;
            //std.debug.print("moving to {},{}\n", .{ node.x, node.y });

            // Debug output current progress
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

            // Check if done.
            if (node.x == dim_x - 1 and node.y == dim_y - 1) {
                for (grid.items) |n, idx| {
                    if (n.visited) {
                        std.debug.print("{}", .{n.risk});
                    } else {
                        std.debug.print(".", .{});
                    }
                    if ((idx + 1) % dim_x == 0) {
                        std.debug.print("\n", .{});
                    }
                }
                break;
            }

            // Add neighbors to queue.
            const offsets = [_][2]i8{ .{ -1, 0 }, .{ 1, 0 }, .{ 0, -1 }, .{ 0, 1 } };
            for (offsets) |off| {
                const new_x = off[0] + node.x;
                const new_y = off[1] + node.y;

                if (new_x >= 0 and new_x < dim_x and new_y >= 0 and new_y < dim_y) {
                    const neighbor_node = &grid.items[@intCast(usize, new_y) * dim_y + @intCast(usize, new_x)];
                    if (!neighbor_node.visited) {
                        // Estimate and add to queue
                        const g = node.g + neighbor_node.risk;
                        if (g < neighbor_node.g) {
                            neighbor_node.g = g;
                            neighbor_node.f = g + h(new_x, new_y, dim_x, dim_y);
                            try q.add(neighbor_node);
                            //std.debug.print("Add to queue: {},{} with cost {}\n", .{ new_x, new_y, cost });
                        }
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
                .x = @intCast(i8, x),
                .y = @intCast(i8, dim_y),
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

    // Dijkstra, no actually A*
    //grid.items[0].g = 0;
    //grid.items[0].f = 0 + h(0, 0, dim_x, dim_y);
    //try q.add(&grid.items[0]);

    //while (q.removeOrNull()) |node| {
    //    if (!node.visited) {
    //        node.visited = true;
    //        //std.debug.print("moving to {},{}\n", .{ node.x, node.y });

    //        // Debug output current progress
    //        //for (grid.items) |n, idx| {
    //        //    if (n.visited) {
    //        //        std.debug.print("{}", .{n.risk});
    //        //    } else {
    //        //        std.debug.print(".", .{});
    //        //    }
    //        //    if ((idx + 1) % dim_x == 0) {
    //        //        std.debug.print("\n", .{});
    //        //    }
    //        //}

    //        // Check if done.
    //        if (node.x == dim_x - 1 and node.y == dim_y - 1) {
    //            for (grid.items) |n, idx| {
    //                if (n.visited) {
    //                    std.debug.print("{}", .{n.risk});
    //                } else {
    //                    std.debug.print(".", .{});
    //                }
    //                if ((idx + 1) % dim_x == 0) {
    //                    std.debug.print("\n", .{});
    //                }
    //            }
    //            break;
    //        }

    //        // Add neighbors to queue.
    //        const offsets = [_][2]i8{ .{ -1, 0 }, .{ 1, 0 }, .{ 0, -1 }, .{ 0, 1 } };
    //        for (offsets) |off| {
    //            const new_x = off[0] + node.x;
    //            const new_y = off[1] + node.y;

    //            if (new_x >= 0 and new_x < dim_x and new_y >= 0 and new_y < dim_y) {
    //                const neighbor_node = &grid.items[@intCast(usize, new_y) * dim_y + @intCast(usize, new_x)];
    //                if (!neighbor_node.visited) {
    //                    // Estimate and add to queue
    //                    const g = node.g + neighbor_node.risk;
    //                    if (g < neighbor_node.g) {
    //                        neighbor_node.g = g;
    //                        neighbor_node.f = g + h(new_x, new_y, dim_x, dim_y);
    //                        try q.add(neighbor_node);
    //                        //std.debug.print("Add to queue: {},{} with cost {}\n", .{ new_x, new_y, cost });
    //                    }
    //                }
    //            }
    //        }
    //    }
    //}

    const path_cost = aStar(&grid, dim_x, dim_y);
    std.debug.print("Day 15, part 1: min risk path = {}\n", .{path_cost});

    part2();
}
