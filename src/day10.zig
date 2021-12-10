const std = @import("std");
const assert = std.debug.assert;

const data = @embedFile("../data/day10_input");

var general_purpose_allocator = std.heap.GeneralPurposeAllocator(.{}){};
const gpa = &general_purpose_allocator.allocator;

pub fn main() anyerror!void {
    var line_it = std.mem.tokenize(u8, data, "\r\n");

    var total_syntax_error_score: usize = 0;
    var auto_complete_scores = std.ArrayList(usize).init(gpa);

    while (line_it.next()) |line| {
        var stack = [_]u8{0} ** 110;
        var stack_idx: usize = 0;

        const syntax_error_score: usize = blk: {
            for (line) |c| {
                switch (c) {
                    '(', '[', '{', '<' => {
                        stack[stack_idx] = c;
                        stack_idx += 1;
                    },
                    ')' => {
                        stack_idx -= 1;
                        if (stack[stack_idx] != '(') {
                            break :blk 3;
                        }
                    },
                    ']' => {
                        stack_idx -= 1;
                        if (stack[stack_idx] != '[') {
                            break :blk 57;
                        }
                    },
                    '}' => {
                        stack_idx -= 1;
                        if (stack[stack_idx] != '{') {
                            break :blk 1197;
                        }
                    },
                    '>' => {
                        stack_idx -= 1;
                        if (stack[stack_idx] != '<') {
                            break :blk 25137;
                        }
                    },
                    else => unreachable,
                }
            }
            break :blk 0;
        };
        total_syntax_error_score += syntax_error_score;

        if (syntax_error_score == 0) {
            var auto_complete_score: usize = 0;

            // Unwind stack
            while (stack_idx > 0) {
                stack_idx -= 1;
                const complete_val: usize = switch (stack[stack_idx]) {
                    '(' => 1,
                    '[' => 2,
                    '{' => 3,
                    '<' => 4,
                    else => unreachable,
                };

                auto_complete_score = auto_complete_score * 5 + complete_val;
            }

            try auto_complete_scores.append(auto_complete_score);
        }
    }

    std.debug.print("Day 10, part 1: total syntax error score = {}\n", .{total_syntax_error_score});

    std.sort.sort(usize, auto_complete_scores.items, {}, comptime std.sort.asc(usize));
    const middle = auto_complete_scores.items[auto_complete_scores.items.len / 2];

    std.debug.print("Day 10, part 2: total auto complete score = {}\n", .{middle});
}
