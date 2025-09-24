const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    // Build-time options baked into the binary
    const project = b.option([]const u8, "project", "Project/binary name") orelse "tcli";
    const conf_prefix = b.option([]const u8, "conf_prefix", "Config directory prefix") orelse "/etc/tcli";
    const log_prefix = b.option([]const u8, "log_prefix", "Log directory prefix") orelse ".";
    const configfile = b.option([]const u8, "configfile", "Config file name") orelse "config.toml";

    const config_path = std.fmt.allocPrint(b.allocator, "{s}/{s}", .{ conf_prefix, configfile }) catch @panic("OOM");
    const logfile_name = std.fmt.allocPrint(b.allocator, "{s}.log", .{project}) catch @panic("OOM");
    const logfile_path = std.fmt.allocPrint(b.allocator, "{s}/{s}", .{ log_prefix, logfile_name }) catch @panic("OOM");

    const opts = b.addOptions();
    opts.addOption([]const u8, "default_config_path", config_path);
    opts.addOption([]const u8, "default_log_path", logfile_path);
    const exe = b.addExecutable(.{
        .name = project,
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/main.zig"),
            .target = target,
            .optimize = optimize,
        }),
    });
    exe.root_module.addOptions("build_options", opts);

    b.installArtifact(exe);

    const run_step = b.step("run", "Run the app");

    const run_cmd = b.addRunArtifact(exe);
    run_step.dependOn(&run_cmd.step);

    run_cmd.step.dependOn(b.getInstallStep());

    if (b.args) |args| {
        run_cmd.addArgs(args);
    }
    const exe_tests = b.addTest(.{
        .root_module = exe.root_module,
    });
    const run_exe_tests = b.addRunArtifact(exe_tests);
    const test_step = b.step("test", "Run tests");
    test_step.dependOn(&run_exe_tests.step);
}
