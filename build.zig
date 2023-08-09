const std = @import("std");
const gpu_dawn = @import("mach_gpu_dawn");

pub fn build(b: *std.Build) !void {
    const optimize = b.standardOptimizeOption(.{});
    const target = b.standardTargetOptions(.{});
    const gpu_dawn_options = gpu_dawn.Options{
        .from_source = b.option(bool, "dawn-from-source", "Build Dawn from source") orelse false,
        .debug = b.option(bool, "dawn-debug", "Use a debug build of Dawn") orelse false,
    };

    const module = b.addModule("mach-gpu", .{
        .source_file = .{ .path = "src/main.zig" },
    });

    const test_step = b.step("test", "Run library tests");
    test_step.dependOn(&(try testStep(b, optimize, target, .{ .gpu_dawn_options = gpu_dawn_options })).step);

    // TODO: uncomment all this code once hexops/mach#902 is fixed, b.dependency("mach_glfw") cannot
    // be called inside `pub fn build` if we want this package to be usable via the package manager.
    _ = module;

    // const example = b.addExecutable(.{
    //     .name = "gpu-hello-triangle",
    //     .root_source_file = .{ .path = "examples/main.zig" },
    //     .target = target,
    //     .optimize = optimize,
    // });
    // example.addModule("gpu", module);

    // try link(b, example, .{ .gpu_dawn_options = gpu_dawn_options });

    // // Link GLFW
    // const glfw_dep = b.dependency("mach_glfw", .{
    //     .target = target,
    //     .optimize = optimize,
    // });
    // example.addModule("glfw", glfw_dep.module("mach-glfw"));
    // try @import("mach_glfw").link(b, example);

    // b.installArtifact(example);

    // const example_run_cmd = b.addRunArtifact(example);
    // example_run_cmd.step.dependOn(b.getInstallStep());
    // const example_run_step = b.step("run-example", "Run the example");
    // example_run_step.dependOn(&example_run_cmd.step);
}

pub fn testStep(b: *std.Build, optimize: std.builtin.OptimizeMode, target: std.zig.CrossTarget, options: Options) !*std.build.RunStep {
    const main_tests = b.addTest(.{
        .name = "gpu-tests",
        .root_source_file = .{ .path = sdkPath("/src/main.zig") },
        .target = target,
        .optimize = optimize,
    });
    try link(b, main_tests, options);
    b.installArtifact(main_tests);
    return b.addRunArtifact(main_tests);
}

pub const Options = struct {
    gpu_dawn_options: gpu_dawn.Options = .{},
};

pub fn link(b: *std.Build, step: *std.build.CompileStep, options: Options) !void {
    if (step.target.toTarget().cpu.arch != .wasm32) {
        try gpu_dawn.link(b, step, options.gpu_dawn_options);
        step.addCSourceFile(.{ .file = .{ .path = sdkPath("/src/mach_dawn.cpp") }, .flags = &.{"-std=c++17"} });
        step.addIncludePath(.{ .path = sdkPath("/src") });
    }
}

fn sdkPath(comptime suffix: []const u8) []const u8 {
    if (suffix[0] != '/') @compileError("suffix must be an absolute path");
    return comptime blk: {
        const root_dir = std.fs.path.dirname(@src().file) orelse ".";
        break :blk root_dir ++ suffix;
    };
}
