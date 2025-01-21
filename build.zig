const std = @import("std");

/// The root library file (usually root.zig)
const root = "src/root.zig";

/// Main executable file
const main = "src/main.zig";

/// Top Level tests file
const tests = "src/tests.zig";

// In runtime code I don't seperate eveything into its own functions to this degree. However I've found that these build files can get quite spagetified
// so I do this to simply make my life easier and as we are not in runtime, performance is not as important as readability.
pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize_mode = b.standardOptimizeOption(.{});

    const lib_module = configureLibrary(b, target, optimize_mode);
    configureUnitTests(b, lib_module);

    const imports = [_]*std.Build.Module{lib_module};
    configureExe(b, &imports, target, optimize_mode);
}

/// Configures and installs the library module, if the target and optimize mode are null they default to the default target and optimize modes. Returns a pointer the new module.
fn configureLibrary(b: *std.Build, target: ?std.Build.ResolvedTarget, optimize_mode: ?std.builtin.OptimizeMode) *std.Build.Module {
    var final_target = target;
    var final_optimizemode = optimize_mode;

    if (target == null) {
        final_target = b.standardTargetOptions(.{});
    }

    if (optimize_mode == null) {
        final_optimizemode = b.standardOptimizeOption(.{});
    }

    const lib_module = b.createModule(.{
        .root_source_file = b.path(root),
        .target = target,
        .optimize = optimize_mode,
    });

    const lib = b.addStaticLibrary(.{
        .name = "lib",
        .root_module = lib_module,
    });

    b.installArtifact(lib);

    return lib_module;
}

/// Configures and installs the executable module. Sets up the run command and step. If the target and optimize mode are null they default to the default target and optimize modes.
fn configureExe(b: *std.Build, imports: []const *std.Build.Module, target: ?std.Build.ResolvedTarget, optimize_mode: ?std.builtin.OptimizeMode) void {
    var final_target = target;
    var final_optimizemode = optimize_mode;

    if (target == null) {
        final_target = b.standardTargetOptions(.{});
    }

    if (optimize_mode == null) {
        final_optimizemode = b.standardOptimizeOption(.{});
    }

    const exe_mod = b.createModule(.{
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize_mode,
    });

    for (imports) |import| {
        exe_mod.addImport("lib", import);
    }

    const exe = b.addExecutable(.{
        .name = "main",
        .root_module = exe_mod,
    });

    b.installArtifact(exe);

    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());

    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);
}

/// Configures the unit tests and sets up the run commannd and step.
fn configureUnitTests(b: *std.Build, module: *std.Build.Module) void {
    const unit_tests = b.addTest(.{
        .root_module = module,
    });

    const run_unit_tests = b.addRunArtifact(unit_tests);
    run_unit_tests.step.dependOn(&unit_tests.step);

    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_unit_tests.step);
}
