const std = @import("std");
const config = @import("config.zig");
const build_options = @import("build_options");
const http = @import("http.zig");
const model = @import("graph.zig");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var args_it = try std.process.argsWithAllocator(allocator);
    defer args_it.deinit();
    _ = args_it.skip(); // exe name

    const config_path: []const u8 = build_options.default_config_path;
    const log_path: []const u8 = build_options.default_log_path;

    if (args_it.next()) |_| {}

    var cfg = try config.loadConfig(allocator, config_path);
    defer cfg.deinit(allocator);

    // Open log file (best-effort)
    const lf_opt: ?std.fs.File = std.fs.cwd().openFile(log_path, .{ .mode = .read_write }) catch std.fs.cwd().createFile(log_path, .{}) catch null;
    if (lf_opt) |lf_val| {
        var lf = lf_val;
        defer lf.close();
        _ = lf.writeAll("Booting...\n") catch {};
        const line1 = std.fmt.allocPrint(allocator, "Got bubs: {d}\n", .{cfg.bub.bubs.len}) catch null;
        if (line1) |l| {
            _ = lf.writeAll(l) catch {};
            allocator.free(l);
        }
        const line2 = std.fmt.allocPrint(allocator, "Baseurl: {s}\n", .{cfg.bub.base_url}) catch null;
        if (line2) |l| {
            _ = lf.writeAll(l) catch {};
            allocator.free(l);
        }
    }

    // Prepare extensions
    const persisted: model.PersistedQuery = .{
        .version = 1,
        .sha256hash = "059c4653b788f5bdb2f5a2d2a24b0ddc3831a15079001a3d927556a96fb0517f",
    };

    var wg = std.Thread.WaitGroup{};
    wg.reset();
    for (cfg.bub.bubs) |chan_login| {
        wg.start();
        const chan_name = try allocator.dupe(u8, chan_login);
        const headers_slice = cfg.bub.headers;
        const base_url = cfg.bub.base_url;
        const persisted_q = persisted;
        _ = std.Thread.spawn(.{}, worker, .{ allocator, base_url, headers_slice, persisted_q, chan_name, &wg }) catch {
            wg.finish();
            allocator.free(chan_name);
        };
    }
    wg.wait();
}

fn worker(allocator: std.mem.Allocator, base_url: []const u8, headers: []const config.Header, persisted: model.PersistedQuery, chan_login: []const u8, wg: *std.Thread.WaitGroup) !void {
    defer wg.finish();
    defer allocator.free(chan_login);
    var client_local = http.HttpClient.init(allocator, base_url, headers);
    const body = try std.fmt.allocPrint(
        allocator,
        "{{\"operationName\":\"{s}\",\"extensions\":{{\"persistedQuery\":{{\"version\":{d},\"sha256hash\":\"{s}\"}}}},\"variables\":{{\"channelLogin\":\"{s}\"}}}}",
        .{ "StreamMetadata", persisted.version, persisted.sha256hash, chan_login },
    );
    defer allocator.free(body);
    const resp = try client_local.postJson(body);
    defer allocator.free(resp);
    const needle = "\"type\":\"";
    if (std.mem.indexOf(u8, resp, needle)) |idx| {
        const start = idx + needle.len;
        if (std.mem.indexOfScalarPos(u8, resp, start, '"')) |end| {
            const s = resp[start..end];
            std.debug.print("{s}: {s}\n", .{ chan_login, s });
        }
    }
}
