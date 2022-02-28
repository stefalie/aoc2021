const std = @import("std");

const data = @embedFile("../data/day04_input");

const Field = packed struct {
    value: u7,
    mark: u1,
};

const Board = struct {
    fields: [5][5]Field,

    pub fn init() Board {
        // 0-init of this 2-dimensional array is a mess.
        //
        //const field = Field{
        //    .value = 0,
        //    .mark = 0,
        //};
        //const row = [_]Field{field} ** 5;
        return Board{
            //.fields = [_][5]Field{row} ** 5,
            //.fields = [_][5]Field{[_]Field{field} ** 5} ** 5,
            .fields = [_][5]Field{[_]Field{.{
                .value = 0,
                .mark = 0,
            }} ** 5} ** 5,
        };
    }

    pub fn mark(self: *Board, num: u7) bool {
        for (self.fields) |row, y| {
            for (row) |field, x| {
                if (field.value == num) {
                    self.fields[y][x].mark = 1;
                    return self.checkBingo(x, y);
                }
            }
        }
        return false;
    }

    pub fn checkBingo(self: *Board, x: usize, y: usize) bool {
        var count_x: u32 = 0;
        var count_y: u32 = 0;

        var i: u32 = 0;
        while (i < 5) : (i += 1) {
            count_x += self.fields[y][i].mark;
            count_y += self.fields[i][x].mark;
        }

        return count_x == 5 or count_y == 5;
    }

    pub fn sumUnmarked(self: *Board) u32 {
        var sum: u32 = 0;
        for (self.fields) |row| {
            for (row) |field| {
                if (field.mark == 0) {
                    sum += field.value;
                }
            }
        }
        return sum;
    }
};

fn part1(random_numbers: []u7, boards: []Board) !void {
    const BingoWinner = struct {
        number: u7,
        board_idx: u64,
    };

    const win = blk: {
        for (random_numbers) |num| {
            for (boards) |_, i| {
                if (boards[i].mark(num)) {
                    break :blk BingoWinner{
                        .board_idx = i,
                        .number = num,
                    };
                }
            }
        }
        unreachable;
    };

    const sum_unmarked = boards[win.board_idx].sumUnmarked();

    std.debug.print("Day 04, part 1: (win board = {}, number = {}, sum unmarked = {}), final score = {}\n", .{
        win.board_idx,
        win.number,
        sum_unmarked,
        win.number * sum_unmarked,
    });
}

fn part2(random_numbers: []u7, boards: []Board) !void {
    var active_boards = try std.DynamicBitSet.initFull(gpa, boards.len);

    const BingoLastLoser = struct {
        number: u7,
        board_idx: u64,
    };

    const loser = blk: {
        for (random_numbers) |num| {
            for (boards) |_, i| {
                if (active_boards.isSet(i)) {
                    if (boards[i].mark(num)) {
                        if (active_boards.count() > 1) {
                            active_boards.unset(i);
                        } else {
                            break :blk BingoLastLoser{
                                .board_idx = i,
                                .number = num,
                            };
                        }
                    }
                }
            }
        }
        unreachable;
    };

    const sum_unmarked = boards[loser.board_idx].sumUnmarked();

    std.debug.print("Day 04, part 2: (lose board = {}, number = {}, sum unmarked = {}), final score = {}\n", .{
        loser.board_idx,
        loser.number,
        sum_unmarked,
        loser.number * sum_unmarked,
    });
}

var general_purpose_allocator = std.heap.GeneralPurposeAllocator(.{}){};
const gpa = general_purpose_allocator.allocator();

pub fn main() anyerror!void {
    var boards = std.ArrayList(Board).init(gpa);
    var random_numbers = std.ArrayList(u7).init(gpa);
    defer {
        boards.deinit();
        random_numbers.deinit();
    }

    var line_it = std.mem.tokenize(u8, data, "\r\n");
    var random_num_it = std.mem.tokenize(u8, line_it.next().?, ",");

    while (random_num_it.next()) |num_str| {
        const num = try std.fmt.parseInt(u7, num_str, 10);
        try random_numbers.append(num);
    }

    var tmp_board = Board.init();
    var row_idx: u32 = 0;
    var col_idx: u32 = 0;

    while (line_it.next()) |line| {
        var num_it = std.mem.tokenize(u8, line, " ");

        col_idx = 0;
        while (num_it.next()) |num_str| : (col_idx += 1) {
            const num = try std.fmt.parseInt(u7, num_str, 10);
            tmp_board.fields[row_idx][col_idx].value = num;
        }

        row_idx += 1;
        if (row_idx == 5) {
            try boards.append(tmp_board);
            tmp_board = Board.init(); // Not strictly necessary.
            row_idx = 0;
        }
    }

    // Debug output
    //for (boards.items) |board| {
    //    for (board.fields) |row| {
    //        for (row) |col| {
    //            std.debug.print("{:2} ", .{col.value});
    //        }
    //        std.debug.print("\n", .{});
    //    }
    //    std.debug.print("\n", .{});
    //}
    //
    //for (random_numbers.items) |x, i| {
    //    if (i > 0) {
    //        std.debug.print(",", .{});
    //    }
    //    std.debug.print("{d}", .{x});
    //    if (i == random_numbers.items.len - 1) {
    //        std.debug.print("\n", .{});
    //    }
    //}

    try part1(random_numbers.items, boards.items);

    // Reset marks for 2nd part
    var i: u32 = 0;
    while (i < boards.items.len) : (i += 1) {
        for (boards.items[i].fields) |row, y| {
            for (row) |_, x| {
                boards.items[i].fields[y][x].mark = 0;
            }
        }
    }

    try part2(random_numbers.items, boards.items);
}
