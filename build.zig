const std = @import("std");

pub fn build(b: *std.build.Builder) void {
    // Standard target options allows the person running `zig build` to choose
    // what target to build for. Here we do not override the defaults, which
    // means any target is allowed, and the default is native. Other options
    // for restricting supported target set are available.
    const target = b.standardTargetOptions(.{});

    // Standard release options allow the person running `zig build` to select
    // between Debug, ReleaseSafe, ReleaseFast, and ReleaseSmall.
    const mode = b.standardReleaseOptions();

    const run_all = b.step("run_all", "Run all days");
    const test_all = b.step("test_all", "Test all days");

    const days = [_]u32{
        1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24,
    };

    for (days) |day| {
        const day_str = b.fmt("{:0>2}", .{day});
        const zig_src = b.fmt("src/day{s}.zig", .{day_str});
        const exe_name = b.fmt("day{s}", .{day_str});

        const exe = b.addExecutable(exe_name, zig_src);
        exe.setTarget(target);
        exe.setBuildMode(mode);
        exe.install();

        const run_cmd = exe.run();
        run_cmd.step.dependOn(b.getInstallStep());
        if (b.args) |args| {
            run_cmd.addArgs(args);
        }

        const run_step = b.step(b.fmt("run{s}", .{day_str}), b.fmt("Run {s}", .{exe_name}));
        run_step.dependOn(&run_cmd.step);
        run_all.dependOn(&run_cmd.step);

        const exe_tests = b.addTest(zig_src);
        exe_tests.setBuildMode(mode);

        const test_step = b.step(b.fmt("test{s}", .{day_str}), b.fmt("Test {s}", .{exe_name}));
        test_step.dependOn(&exe_tests.step);
        test_all.dependOn(&exe_tests.step);
    }
}
