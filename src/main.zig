const std = @import("std");
const build_options = @import("build_options");
const tcli = @import("tcli");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const config_path: []const u8 = build_options.default_config_path;
    const log_path: []const u8 = build_options.default_log_path;
    var buf: [4096]u8 = undefined;
    const out = try tcli.fetch_buf(allocator, config_path, log_path, &buf);
    _ = out; // use out as needed (e.g., print or write to file)
}
