const std = @import("std");
const assert = std.debug.assert;

const data = @embedFile("../data/day21_input");

const DetDie = struct {
    val: usize = 1,

    pub fn next(self: *DetDie) usize {
        //defer self.val = (self.val + 1 - 1) % 100) + 1;
        defer self.val = (self.val % 100) + 1;
        return self.val;
    }
};

const Dial = struct {
    val: u4 = undefined,
    pub fn init(val: usize) Dial {
        return .{
            .val = @intCast(u4, val),
        };
    }

    pub fn add(self: *Dial, inc: usize) void {
        defer self.val = @intCast(u4, ((self.val + inc - 1) % 10) + 1);
    }
};

pub fn main() anyerror!void {
    var input_it = std.mem.tokenize(u8, data, " \r\n");
    _ = input_it.next().?;
    _ = input_it.next().?;
    _ = input_it.next().?;
    _ = input_it.next().?;
    const start1: usize = try std.fmt.parseInt(usize, input_it.next().?, 10);
    _ = input_it.next().?;
    _ = input_it.next().?;
    _ = input_it.next().?;
    _ = input_it.next().?;
    const start2: usize = try std.fmt.parseInt(usize, input_it.next().?, 10);

    // Debug output
    //std.debug.print("start 1: {}, start 2: {}\n", .{ start1, start2 });

    var dice = DetDie{};
    var dials = [_]Dial{ Dial.init(start1), Dial.init(start2) };
    var scores = [_]usize{ 0, 0 };

    var it: usize = 0;
    while (true) : (it += 1) {
        const player_idx = it % 2;

        dials[player_idx].add(dice.next());
        dials[player_idx].add(dice.next());
        dials[player_idx].add(dice.next());

        scores[player_idx] += dials[player_idx].val;
        if (scores[player_idx] >= 1000) {
            const num_rolls = 3 * (it + 1);
            const loser_score = scores[if (player_idx == 0) 1 else 0];
            std.debug.print("loser score {}, num rolls {}\n", .{ loser_score, num_rolls });
            std.debug.print("Day 21, part 1: loser score * num rolls = {}\n", .{loser_score * num_rolls});
            break;
        }
    }

    const part2_states = PlayerStates{
        .p1_pos = Dial.init(start1),
        .p2_pos = Dial.init(start2),
    };
    const part2_result = part2Rec(true, part2_states);
    const max_wins = std.math.max(part2_result.player1, part2_result.player2);
    std.debug.print("Day 21, part 2: max wins in all universes = {}\n", .{max_wins});
}

const PlayerStates = struct {
    p1_pos: Dial,
    p2_pos: Dial,
    p1_score: usize = 0,
    p2_score: usize = 0,
    num_paths_leading_to_state: usize = 1,
};

const NumWins = struct {
    player1: usize = 0,
    player2: usize = 0,
};

// Ok, I admit it, I had a quick look at:
// https://github.com/sheredom/AOC2021/blob/main/src/day21.zig
fn part2Rec(player_one: bool, states: PlayerStates) NumWins {
    var num_wins = NumWins{};

    // 3 rolls ^ 3 outcomes == 27 possibilites, but all of them
    // advance the player 3-9 fields.
    const advance_possibilites = [_]u8{ 0, 0, 0, 1, 3, 6, 7, 6, 3, 1 };
    for (advance_possibilites) |num_possibilities, step| {
        if (num_possibilities == 0) {
            continue;
        }

        const new_states = if (player_one) blk: {
            var s = states;
            s.p1_pos.add(step);
            s.p1_score += s.p1_pos.val;
            s.num_paths_leading_to_state *= num_possibilities;
            break :blk s;
        } else blk: {
            var s = states;
            s.p2_pos.add(step);
            s.p2_score += s.p2_pos.val;
            s.num_paths_leading_to_state *= num_possibilities;
            break :blk s;
        };

        if (player_one and new_states.p1_score >= 21) {
            num_wins.player1 += new_states.num_paths_leading_to_state;
        } else if (!player_one and new_states.p2_score >= 21) {
            num_wins.player2 += new_states.num_paths_leading_to_state;
        } else {
            const rec_wins = part2Rec(!player_one, new_states);
            num_wins.player1 += rec_wins.player1;
            num_wins.player2 += rec_wins.player2;
        }
    }

    return num_wins;
}
