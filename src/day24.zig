// Most code in this file is not used.

const std = @import("std");
const assert = std.debug.assert;

const data = @embedFile("../data/day24_input");

const Reg = enum {
    x,
    y,
    z,
    w,
};

const Op = enum {
    inp,
    add,
    mul,
    div,
    mod,
    eql,
};

const Operand = union(enum) {
    val: i8,
    reg: Reg,
};

const Inst = struct {
    op: Op,
    lhs: Reg,
    rhs: ?Operand,
};

const ALU = struct {
    xyzw_registers: [4]i64 = [_]i64{0} ** 4,
    input_read_idx: usize = 0,

    pub fn get(self: ALU, reg: Reg) i64 {
        return self.xyzw_registers[@enumToInt(reg)];
    }

    pub fn evalOperand(self: ALU, operand: Operand) i64 {
        return switch (operand) {
            Operand.val => |val| val,
            Operand.reg => |reg| self.xyzw_registers[@enumToInt(reg)],
        };
    }

    pub fn set(self: *ALU, reg: Reg, val: i64) void {
        self.xyzw_registers[@enumToInt(reg)] = val;
    }
};

fn execProgram(instructions: []Inst, input: []const i8) ALU {
    var alu = ALU{};

    for (instructions) |inst| {
        switch (inst.op) {
            Op.inp => {
                alu.set(inst.lhs, input[alu.input_read_idx]);
                alu.input_read_idx += 1;
            },
            else => {
                const lhs = alu.get(inst.lhs);
                const rhs = switch (inst.rhs.?) {
                    Operand.val => |val| val,
                    Operand.reg => |reg| alu.get(reg),
                };

                const new_val = switch (inst.op) {
                    Op.add => lhs + rhs,
                    Op.mul => lhs * rhs,
                    Op.div => @divTrunc(lhs, rhs),
                    Op.mod => @rem(lhs, rhs),
                    Op.eql => if (lhs == rhs) @as(i8, 1) else @as(i8, 0),
                    Op.inp => unreachable,
                };

                alu.set(inst.lhs, new_val);
            },
        }
    }

    return alu;
}

var general_purpose_allocator = std.heap.GeneralPurposeAllocator(.{}){};
const gpa = &general_purpose_allocator.allocator;

fn parseOperand(operand_str: []const u8) !Operand {
    return switch (operand_str[0]) {
        'x' => Operand{ .reg = Reg.x },
        'y' => Operand{ .reg = Reg.y },
        'z' => Operand{ .reg = Reg.z },
        'w' => Operand{ .reg = Reg.w },
        else => Operand{ .val = try std.fmt.parseInt(i8, operand_str, 10) },
    };
}

fn parseLine(line: []const u8) !Inst {
    var inst_it = std.mem.tokenize(u8, line, " ");
    const inst_name = inst_it.next().?;

    var inst: Inst = undefined;
    if (std.mem.eql(u8, inst_name, "inp")) {
        inst.op = Op.inp;
    } else if (std.mem.eql(u8, inst_name, "add")) {
        inst.op = Op.add;
    } else if (std.mem.eql(u8, inst_name, "mul")) {
        inst.op = Op.mul;
    } else if (std.mem.eql(u8, inst_name, "div")) {
        inst.op = Op.div;
    } else if (std.mem.eql(u8, inst_name, "mod")) {
        inst.op = Op.mod;
    } else if (std.mem.eql(u8, inst_name, "eql")) {
        inst.op = Op.eql;
    } else {
        unreachable;
    }

    inst.lhs = (try parseOperand(inst_it.next().?)).reg;
    inst.rhs = if (inst.op != Op.inp) try parseOperand(inst_it.next().?) else null;

    return inst;
}

fn parseProgram(src: []const u8, instructions: *std.ArrayList(Inst)) !void {
    instructions.clearRetainingCapacity();

    var line_it = std.mem.tokenize(u8, src, "\r\n");
    while (line_it.next()) |line| {
        try instructions.append(try parseLine(line));
    }
}

// Unused
fn zUpdateRoutine(z: isize, w: i8, params: [3]i8) isize {
    if (@rem(z, 26) + params[1] != w) {
        return @divTrunc(z, params[0]) * 26 + w + params[2];
    } else {
        return @divTrunc(z, params[0]);
    }
}

fn recurse(params: [][3]i8, z: usize, number: usize, down: bool) ?usize {
    if (params.len == 0) {
        return if (z == 0) number else null;
    }

    const param0 = params[0][0];
    const param1 = params[0][1];
    const param2 = params[0][2];

    // w = next_input();
    // x = z % 26 + param1 != w
    // z = z / param0 * (25 * x + 1) + (w + param2) * x

    // param0 and param2 are always > 0
    // param0 is either 1 or 26
    // if param0 == 1, param1 >= 10 (just form lookings at params)
    // therefore, x can only be 1 if param0 == 26
    //
    // If x == 1 a number is pushes onto a base26 stack
    // If x == 0 we pop
    // x can only be 1 if param0 == 26
    // There are the same number of param0 == 26 and == 1. Therefore
    // in order to reach z == 0 in the end, every param == 26 must
    // be a pop. For this we have to pick w so that x == 0.

    // Pop
    if (param0 == 26) {
        const pop_w = @intCast(i8, @rem(z, 26)) + param1;
        if (pop_w < 1 or pop_w > 9) {
            return null;
        }
        const new_z = @divTrunc(z, 26);
        return recurse(params[1..], new_z, number * 10 + @intCast(u8, pop_w), down);
    }

    // Push
    std.debug.assert(param0 == 1);
    const range_down = [_]u8{ 9, 8, 7, 6, 5, 4, 3, 2, 1 };
    const range_up = [_]u8{ 1, 2, 3, 4, 5, 6, 7, 8, 9 };
    for (if (down) range_down else range_up) |w| {
        const new_z = z * 26 + w + @intCast(u8, param2);
        if (recurse(params[1..], new_z, number * 10 + w, down)) |result| {
            return result;
        }
    }

    return null;
}

pub fn main() anyerror!void {
    var instructions = std.ArrayList(Inst).init(gpa);
    defer instructions.deinit();

    try parseProgram(data, &instructions);

    // Debug output
    //for (instructions.items) |inst| {
    //    std.debug.print("{}\n", .{inst});
    //}
    //
    //

    // Argh, I spent all the time building the interpreter above.
    // I thought I could somehow find a lower bound by randomly or regularly
    // sampling the input space. But it seems really hard to even find 1
    // possible solution.
    // Instead I should have looked at the input assembly. It seems to repeat
    // 14 times the following routine and only modify 3 parameters:
    // w = next_input();
    // x = z % 26 + param1 != w
    // z = z / param0 * (25 * x + 1) + (w + param2) * x
    // Only the z register matters, everything else are just temp values.
    // See also:
    // https://www.reddit.com/r/adventofcode/comments/rnejv5/comment/hpsr7bz/?utm_source=share&utm_medium=web2x&context=3
    // https://www.reddit.com/r/adventofcode/comments/rnejv5/comment/hpsk9nf/?utm_source=share&utm_medium=web2x&context=3
    // https://www.reddit.com/r/adventofcode/comments/rnejv5/comment/hps5hgw/?utm_source=share&utm_medium=web2x&context=3

    var params: [14][3]i8 = undefined;

    var line_it = std.mem.tokenize(u8, data, "\r\n");
    var routine_repeat_idx: usize = 0;
    while (routine_repeat_idx < 14) : (routine_repeat_idx += 1) {
        var i: usize = 0;
        while (i < 4) : (i += 1) {
            _ = line_it.next().?;
        }
        params[routine_repeat_idx][0] = (try parseLine(line_it.next().?)).rhs.?.val;
        params[routine_repeat_idx][1] = (try parseLine(line_it.next().?)).rhs.?.val;
        i += 2;
        while (i < 15) : (i += 1) {
            _ = line_it.next().?;
        }
        params[routine_repeat_idx][2] = (try parseLine(line_it.next().?)).rhs.?.val;
        i += 1;
        while (i < 18) : (i += 1) {
            _ = line_it.next().?;
        }
    }

    std.debug.print("Day 24, part 1: max model number = {}\n", .{recurse(params[0..], 0, 0, true)});
    std.debug.print("Day 24, part 2: min model number = {}\n", .{recurse(params[0..], 0, 0, false)});
}

test "negate" {
    const source =
        \\inp x
        \\mul x -1
    ;

    var instructions = std.ArrayList(Inst).init(gpa);
    defer instructions.deinit();
    try parseProgram(source, &instructions);

    var i: i8 = -32;
    while (i < 32) : (i += 1) {
        const input = [1]i8{i};
        const alu = execProgram(instructions.items, input[0..]);
        try std.testing.expect(alu.get(Reg.x) == -i);
    }
}

test "three times larger" {
    const source =
        \\inp z
        \\inp x
        \\mul z 3
        \\eql z x
    ;

    var instructions = std.ArrayList(Inst).init(gpa);
    defer instructions.deinit();
    try parseProgram(source, &instructions);

    const input1 = [_]i8{ 4, 12 };
    const alu1 = execProgram(instructions.items, input1[0..]);
    try std.testing.expect(alu1.get(Reg.z) == 1);
    const input2 = [_]i8{ 4, 11 };
    const alu2 = execProgram(instructions.items, input2[0..]);
    try std.testing.expect(alu2.get(Reg.z) == 0);
}

test "to binary" {
    const source =
        \\inp w
        \\add z w
        \\mod z 2
        \\div w 2
        \\add y w
        \\mod y 2
        \\div w 2
        \\add x w
        \\mod x 2
        \\div w 2
        \\mod w 2
    ;

    var instructions = std.ArrayList(Inst).init(gpa);
    defer instructions.deinit();
    try parseProgram(source, &instructions);

    var i: i8 = 0;
    while (i < 15) : (i += 1) {
        const input = [1]i8{i};
        const alu = execProgram(instructions.items, input[0..]);
        try std.testing.expect(alu.get(Reg.z) == (i >> 0) & 1);
        try std.testing.expect(alu.get(Reg.y) == (i >> 1) & 1);
        try std.testing.expect(alu.get(Reg.x) == (i >> 2) & 1);
        try std.testing.expect(alu.get(Reg.w) == (i >> 3) & 1);
    }
}
