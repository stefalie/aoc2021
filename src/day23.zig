const std = @import("std");
const assert = std.debug.assert;

const data = @embedFile("../data/day23_input");

const Cell = enum(u8) {
    A,
    B,
    C,
    D,
    empty,
    junction,

    pub fn print(self: Cell) void {
        const c = switch (self) {
            else => @enumToInt(self) + 'A',
            Cell.empty => '.',
            Cell.junction => '+',
        };
        std.debug.print("{c}", .{c});
    }
};

const junction_positions = [_]usize{ 2, 4, 6, 8 };
fn is_junction_pos(pos: usize) bool {
    for (junction_positions) |p| {
        if (p == pos) {
            return true;
        }
    }
    return false;
}
const move_costs = [_]usize{ 1, 10, 100, 1000 };

fn GenericState(comptime depth: usize) type {
    return struct {
        hallway: [11]Cell,
        rooms: [4][depth]Cell, // idx 0 -> A, 1 -> B, ...
        energy: usize,

        pub fn init() @This() {
            // Doesn't work. Why?
            //var state = .{
            //    .hallway = [_]Cell{Cell.empty} ** 11,
            //    .rooms = [_][2]Cell{[_]Cell{Cell.empty} ** 2} ** 4,
            //    .energy = 0,
            //};
            var state: @This() = undefined;
            state.energy = 0;
            for (state.hallway) |*cell| {
                cell.* = Cell.empty;
            }
            for (junction_positions) |idx| {
                state.hallway[idx] = Cell.junction;
            }
            for (state.rooms) |*room| {
                for (room) |*r| {
                    r.* = Cell.empty;
                }
            }
            return state;
        }

        pub fn print(self: @This()) void {
            for (self.hallway) |c| {
                c.print();
            }
            std.debug.print("\t spend energy: {}\n", .{self.energy});
            var lvl = depth;
            while (lvl > 0) {
                lvl -= 1;
                std.debug.print("  ", .{});
                self.rooms[0][lvl].print();
                std.debug.print(" ", .{});
                self.rooms[1][lvl].print();
                std.debug.print(" ", .{});
                self.rooms[2][lvl].print();
                std.debug.print(" ", .{});
                self.rooms[3][lvl].print();
                std.debug.print("\n", .{});
            }
        }

        pub fn done(self: @This()) bool {
            for (self.rooms) |room, idx| {
                const amphipod = @intToEnum(Cell, idx);
                if (room[0] != amphipod or room[1] != amphipod) {
                    return false;
                }
            }
            return true;
        }

        pub fn moveInHallway(self: @This(), from: usize, to: usize) ?@This() {
            std.debug.assert(from != to);
            const slice = if (to > from) self.hallway[(from + 1)..(to + 1)] else self.hallway[to..from];

            const is_path_clear = blk: {
                for (slice) |step| {
                    if (step != Cell.empty and step != Cell.junction) {
                        break :blk false;
                    }
                }
                break :blk true;
            };

            // std.debug.print("Can move from {} to {}: {}\n", .{ from, to, is_path_clear });

            if (is_path_clear) {
                var new_state = self;
                const move_type = self.hallway[from];
                new_state.hallway[from] = if (is_junction_pos(from)) Cell.junction else Cell.empty;
                new_state.hallway[to] = move_type;
                const path_length = slice.len;
                new_state.energy += path_length * move_costs[@enumToInt(move_type)];
                return new_state;
            } else {
                return null;
            }
        }

        // Move from junction into the room.
        pub fn enterRoom(self: @This(), room: Cell) ?@This() {
            const amphipod_idx = @enumToInt(room);
            const junction_idx = junction_positions[amphipod_idx];
            std.debug.assert(self.hallway[junction_idx] == room);

            const can_move_to_room0 = self.rooms[amphipod_idx][0] == Cell.empty;
            const can_move_to_room1 =
                self.rooms[amphipod_idx][0] == room and
                self.rooms[amphipod_idx][1] == Cell.empty;

            if (can_move_to_room0) {
                std.debug.assert(self.rooms[amphipod_idx][1] == Cell.empty);
                var new_state = self;
                new_state.hallway[junction_idx] = Cell.junction;
                new_state.rooms[amphipod_idx][0] = room;
                new_state.energy += 2 * move_costs[amphipod_idx];
                return new_state;
            } else if (can_move_to_room1) {
                var new_state = self;
                new_state.hallway[junction_idx] = Cell.empty;
                new_state.rooms[amphipod_idx][1] = room;
                new_state.energy += move_costs[amphipod_idx];
                return new_state;
            } else {
                return null;
            }
        }

        // Move from a room to the junction in front of it.
        pub fn leaveRoom(self: @This(), room: Cell) ?@This() {
            const room_idx = @enumToInt(room);
            const junction_idx = junction_positions[room_idx];
            defer std.debug.assert(self.hallway[junction_idx] != room);

            const can_leave_room0 =
                self.rooms[room_idx][1] == Cell.empty and
                self.rooms[room_idx][0] != Cell.empty and
                self.rooms[room_idx][0] != room;
            const can_leave_room1 =
                self.rooms[room_idx][1] != Cell.empty and
                (self.rooms[room_idx][1] != room or
                self.rooms[room_idx][0] != room);

            if (can_leave_room0) {
                var new_state = self;
                const leave_type = new_state.rooms[room_idx][0];
                new_state.rooms[room_idx][0] = Cell.empty;
                new_state.hallway[junction_idx] = leave_type;
                new_state.energy += 2 * move_costs[@enumToInt(leave_type)];
                return new_state;
            } else if (can_leave_room1) {
                var new_state = self;
                const leave_type = new_state.rooms[room_idx][1];
                new_state.rooms[room_idx][1] = Cell.empty;
                new_state.hallway[junction_idx] = leave_type;
                new_state.energy += 1 * move_costs[@enumToInt(leave_type)];
                return new_state;
            } else {
                return null;
            }
        }

        pub fn move(self: @This(), energy_bound: usize) usize {
            //std.debug.print("Looking at:\n", .{});
            //self.print();
            //std.debug.print("\n", .{});

            if (self.energy >= energy_bound) {
                //std.debug.print("Aborting because a better solution already exits {} vs {}.\n", .{
                //    self.energy,
                //    energy_bound,
                //});
                return energy_bound;
            }
            if (self.done()) {
                //std.debug.print("Found a solution:\n", .{});
                //self.print();
                return self.energy;
            }

            var bound = energy_bound;

            // Move hallway -> room
            for (self.hallway) |c, curr_pos| {
                switch (c) {
                    Cell.empty, Cell.junction => {},
                    else => {
                        const amphipod_idx = @enumToInt(c);
                        const junction_pos = junction_positions[amphipod_idx];
                        if (self.moveInHallway(curr_pos, junction_pos)) |at_junction| {
                            if (at_junction.enterRoom(c)) |new_state| {
                                //std.debug.print("enter:\n", .{});
                                bound = new_state.move(bound); // Recurse
                            }
                        }
                    },
                }
            }

            // Move room -> hallway
            for ([_]usize{ 0, 1, 2, 3 }) |room_idx| {
                if (self.leaveRoom(@intToEnum(Cell, room_idx))) |at_junction1| {
                    //std.debug.print("leave:\n", .{});
                    //at_junction1.print();
                    //std.debug.print("\n", .{});

                    const junction_pos1 = junction_positions[room_idx];
                    const move_type = at_junction1.hallway[junction_pos1];
                    const junction_pos2 = junction_positions[@enumToInt(move_type)];

                    // Check if we can directly move into the final room which
                    // is the best option if possible.
                    const direct_move: ?@This() = blk: {
                        if (junction_pos1 != junction_pos2) {
                            if (at_junction1.moveInHallway(junction_pos1, junction_pos2)) |at_junction2| {
                                break :blk at_junction2.enterRoom(move_type);
                            }
                        }
                        break :blk null;
                    };

                    if (direct_move) |new_state| {
                        //std.debug.print("direct move:\n", .{});
                        bound = new_state.move(bound); // Recurse
                    } else {
                        // Exhaustively move anywhere in the hallway.
                        for (at_junction1.hallway) |cell, try_pos| {
                            if (cell == Cell.empty) {
                                //std.debug.print("try Hallway move {} {}\n", .{ junction_pos1, try_pos });
                                if (at_junction1.moveInHallway(junction_pos1, try_pos)) |new_state| {
                                    //std.debug.print("Hallway move:\n", .{});
                                    bound = new_state.move(bound); // Recurse
                                }
                            }
                        }
                    }
                }
            }

            return bound;
        }
    };
}

const State = GenericState(2);
const StatePart2 = GenericState(4);

pub fn main() anyerror!void {
    var line_it = std.mem.tokenize(u8, data, "\r\n");
    _ = line_it.next().?;
    _ = line_it.next().?;

    var initial_state = State.init();
    for ([_]usize{ 1, 0 }) |lvl| {
        var room_it = std.mem.tokenize(u8, line_it.next().?, " #");
        for ([_]usize{ 0, 1, 2, 3 }) |room| {
            initial_state.rooms[room][lvl] = @intToEnum(Cell, room_it.next().?[0] - 'A');
        }
    }

    // initial_state.print();
    const min_energy = initial_state.move(std.math.maxInt(usize));
    std.debug.print("Day 23, part 1: min energy = {}\n", .{min_energy});

    var initial_state2 = StatePart2.init();
    for ([_]usize{ 0, 1, 2, 3 }) |room| {
        initial_state2.rooms[room][0] = initial_state.rooms[room][0];
        initial_state2.rooms[room][3] = initial_state.rooms[room][1];
    }
    // #D#C#B#A#
    // #D#B#A#C#
    initial_state2.rooms[0][2] = Cell.D;
    initial_state2.rooms[0][1] = Cell.D;
    initial_state2.rooms[1][2] = Cell.C;
    initial_state2.rooms[1][1] = Cell.B;
    initial_state2.rooms[2][2] = Cell.B;
    initial_state2.rooms[2][1] = Cell.A;
    initial_state2.rooms[3][2] = Cell.A;
    initial_state2.rooms[3][1] = Cell.C;
    initial_state2.print();

    std.debug.print("Day 23, part 2:\n", .{});
}
