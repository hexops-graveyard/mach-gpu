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
        .root_source_file = .{ .path = "src/main.zig" },
    });
    gpu_dawn.addPathsToModule(b, module, gpu_dawn_options);
    module.addIncludePath(.{ .path = sdkPath("/src") });

    const test_step = b.step("test", "Run library tests");

    const main_tests = b.addTest(.{
        .name = "gpu-tests",
        .root_source_file = .{ .path = sdkPath("/src/main.zig") },
        .target = target,
        .optimize = optimize,
    });
    try link(b, main_tests, .{ .gpu_dawn_options = gpu_dawn_options });
    b.installArtifact(main_tests);
    test_step.dependOn(&b.addRunArtifact(main_tests).step);

    const example = b.addExecutable(.{
        .name = "gpu-hello-triangle",
        .root_source_file = .{ .path = "examples/main.zig" },
        .target = target,
        .optimize = optimize,
    });
    example.root_module.addImport("gpu", module);

    try link(b, example, .{ .gpu_dawn_options = gpu_dawn_options });

    // Link GLFW
    const glfw_dep = b.dependency("mach_glfw", .{
        .target = target,
        .optimize = optimize,
    });
    example.root_module.addImport("glfw", glfw_dep.module("mach-glfw"));
    @import("mach_glfw").addPaths(example);

    b.installArtifact(example);

    const example_run_cmd = b.addRunArtifact(example);
    example_run_cmd.step.dependOn(b.getInstallStep());
    const example_run_step = b.step("run-example", "Run the example");
    example_run_step.dependOn(&example_run_cmd.step);
}

pub const Options = struct {
    gpu_dawn_options: gpu_dawn.Options = .{},
};

pub fn link(b: *std.Build, step: *std.Build.Step.Compile, options: Options) !void {
    if (step.rootModuleTarget().cpu.arch != .wasm32) {
        gpu_dawn.link(
            b.dependency("mach_gpu_dawn", .{
                .target = step.root_module.resolved_target.?,
                .optimize = step.root_module.optimize.?,
            }).builder,
            step,
            options.gpu_dawn_options,
        );
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
